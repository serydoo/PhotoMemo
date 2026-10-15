import importlib.util
import json
import os
import plistlib
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'memomark_source_sync.py'


class SourceSyncTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / 'repo'
        self.repo.mkdir()
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        self.put('.gitignore', '.autosync/\nignored.swift\n')
        self.put('Source/App/main.swift', 'let initial = 1\n')
        self.git('add', '--', '.gitignore', 'Source/App/main.swift')
        self.git('commit', '-qm', 'baseline')
        self.remote = self.base / 'remote.git'
        subprocess.run(['git', 'init', '--bare', '-q', str(self.remote)], check=True)
        self.git('remote', 'add', 'origin', str(self.remote))
        self.git('push', '-q', 'origin', 'main')
        spec = importlib.util.spec_from_file_location('source_sync_under_test', SCRIPT)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.repo), *args]).decode().strip()

    def put(self, relative, text):
        p = self.repo / relative
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def plan(self):
        return self.module.prepare(self.repo)

    def validated(self):
        plan = self.plan()
        candidate = self.base / 'candidate'
        candidate.mkdir(exist_ok=True)
        for relative in plan['files']:
            destination = candidate / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes((self.repo / relative).read_bytes())
        evidence = self.base / 'checks.log'
        evidence.write_text('fixture validation completed\n')
        receipt = {**{k: plan[k] for k in ('base', 'branch', 'files')},
                   'checks': {name: {'exit': 0, 'evidence': str(evidence)}
                              for name in ('fullTests', 'iosArchive', 'scriptTests')}}
        return candidate, receipt

    def test_prepare_covers_research_build_inputs_and_preserves_git_state(self):
        before = self.git('rev-parse', 'HEAD')
        self.put('Source/App/new.swift', 'let current = 2\n')
        self.put('Source/App/Assets.xcassets/example.imageset/image.png', 'synthetic resource')
        self.put('Research/probe.swift', 'let probe = 3\n')
        self.put('Docs/spec.md', 'accepted spec\n')
        self.put('work/v5-baseline/log.txt', 'local evidence')
        self.put('config/mcporter.json', 'private local connection')
        plan = self.plan()
        self.assertIn('Research/probe.swift', plan['paths'])
        self.assertIn('Source/App/new.swift', plan['files'])
        self.assertIn('Source/App/Assets.xcassets/example.imageset/image.png', plan['files'])
        self.assertNotIn('config/mcporter.json', plan['files'])
        self.assertEqual(len(plan['retained']), 2)
        self.assertEqual(plan['blocked'], [])
        self.assertEqual(self.git('rev-parse', 'HEAD'), before)
        self.assertEqual(self.git('diff', '--cached', '--name-only'), '')

    def test_ignored_source_and_unknown_top_level_block_sync(self):
        self.put('Source/App/ignored.swift', 'let missing = 1\n')
        self.put('unreviewed.swift', 'let unknown = 1\n')
        plan = self.plan()
        self.assertTrue(any('ignored.swift' in p for p in plan['blocked']))
        self.assertTrue(any('unreviewed.swift' in p for p in plan['blocked']))

    def test_generated_source_copy_requires_a_published_identical_counterpart(self):
        self.put('work/v5-baseline/helper.swift', 'let helper = 1\n')
        self.assertIn('work/v5-baseline/helper.swift', self.plan()['blocked'])
        self.put('Research/Tools/helper.swift', 'let helper = 1\n')
        self.assertNotIn('work/v5-baseline/helper.swift', self.plan()['blocked'])

    def test_deleted_source_and_rename_are_complete(self):
        source = self.repo / 'Source/App/main.swift'
        source.rename(self.repo / 'Source/App/renamed.swift')
        plan = self.plan()
        self.assertIn('Source/App/main.swift', plan['paths'])
        self.assertIn('Source/App/renamed.swift', plan['files'])
        self.assertNotIn('Source/App/main.swift', plan['files'])

    def test_stale_candidate_and_failed_checks_do_not_stage(self):
        self.put('Source/App/new.swift', 'let current = 2\n')
        candidate, receipt = self.validated()
        self.put('Source/App/new.swift', 'let current = 3\n')
        with self.assertRaises(self.module.SyncError):
            self.module.synchronize(self.repo, candidate, receipt, 'validated sync')
        self.assertEqual(self.git('diff', '--cached', '--name-only'), '')
        self.put('Source/App/new.swift', 'let current = 2\n')
        receipt['checks']['iosArchive']['exit'] = 1
        with self.assertRaises(self.module.SyncError):
            self.module.synchronize(self.repo, candidate, receipt, 'validated sync')
        self.assertEqual(self.git('diff', '--cached', '--name-only'), '')

    def test_preexisting_index_is_preserved(self):
        self.put('Source/App/new.swift', 'let current = 2\n')
        candidate, receipt = self.validated()
        self.git('add', '--', 'Source/App/new.swift')
        before = self.git('diff', '--cached')
        with self.assertRaises(self.module.SyncError):
            self.module.synchronize(self.repo, candidate, receipt, 'validated sync')
        self.assertEqual(self.git('diff', '--cached'), before)

    def test_local_bare_remote_receives_complete_validated_tree(self):
        self.put('Source/App/new.swift', 'let current = 2\n')
        self.put('Research/probe.py', 'print("synthetic probe")\n')
        self.put('work/v5-baseline/log.txt', 'retained')
        candidate, receipt = self.validated()
        result = self.module.synchronize(self.repo, candidate, receipt, 'Complete validated source')
        remote = subprocess.check_output(['git', '--git-dir', str(self.remote), 'rev-parse', 'refs/heads/main']).decode().strip()
        self.assertEqual(result['commit'], remote)
        self.assertEqual(self.git('status', '--short', '--', 'Source', 'Research'), '')
        self.assertTrue((self.repo / 'work/v5-baseline/log.txt').exists())
        self.assertNotIn('work/v5-baseline/log.txt', self.git('ls-tree', '-r', '--name-only', 'HEAD'))

    def test_default_cli_does_not_commit_or_publish(self):
        self.put('Source/App/new.swift', 'let current = 2\n')
        self.put('work/v5-baseline/log.txt', 'local only')
        before = self.git('rev-parse', 'HEAD')
        output = self.base / 'plan.json'
        run = subprocess.run(['python3', str(SCRIPT), '--repo', str(self.repo), '--output', str(output)], capture_output=True)
        self.assertEqual(run.returncode, 0, run.stdout)
        self.assertEqual(json.loads(output.read_text())['base'], before)
        self.assertEqual(self.git('rev-parse', 'HEAD'), before)
        self.assertEqual(self.git('diff', '--cached', '--name-only'), '')

    def test_remote_advance_stops_before_staging(self):
        self.put('Source/App/new.swift', 'let current = 2\n')
        candidate, receipt = self.validated()
        parent = self.git('rev-parse', 'HEAD')
        tree = self.git('rev-parse', 'HEAD^{tree}')
        other = self.git('commit-tree', tree, '-p', parent, '-m', 'remote update')
        self.git('push', '-q', 'origin', other + ':refs/heads/main')
        with self.assertRaises(self.module.SyncError):
            self.module.synchronize(self.repo, candidate, receipt, 'validated sync')
        self.assertEqual(self.git('diff', '--cached', '--name-only'), '')
        self.assertEqual(self.git('rev-parse', 'HEAD'), parent)

    def test_extra_candidate_input_and_missing_evidence_are_rejected(self):
        self.put('Source/App/new.swift', 'let current = 2\n')
        candidate, receipt = self.validated()
        extra = candidate / 'unpublished-build-input.swift'
        extra.write_text('let missing = 3\n')
        with self.assertRaises(self.module.SyncError):
            self.module.synchronize(self.repo, candidate, receipt, 'validated sync')
        extra.unlink()
        receipt['checks']['fullTests']['evidence'] = str(self.base / 'absent.log')
        with self.assertRaises(self.module.SyncError):
            self.module.synchronize(self.repo, candidate, receipt, 'validated sync')
        self.assertEqual(self.git('diff', '--cached', '--name-only'), '')

    def test_commit_hook_cannot_publish_a_different_tree(self):
        self.put('Source/App/new.swift', 'let current = 2\n')
        candidate, receipt = self.validated()
        before = self.git('rev-parse', 'HEAD')
        hook = self.repo / '.git/hooks/pre-commit'
        hook.write_text('#!/bin/sh\nprintf hook > injected.txt\ngit add -- injected.txt\n')
        hook.chmod(0o755)
        with self.assertRaises(self.module.SyncError):
            self.module.synchronize(self.repo, candidate, receipt, 'validated sync')
        remote = subprocess.check_output(['git', '--git-dir', str(self.remote), 'rev-parse', 'refs/heads/main']).decode().strip()
        self.assertEqual(remote, before)

    def test_installer_binds_checkout_paths_and_preserves_installed_runner(self):
        scripts = self.repo / 'scripts'
        scripts.mkdir()
        for name in ('install_autosync.sh', 'auto_sync_to_github.sh', 'com.serydoo.memomark.autosync.plist', 'memomark_source_sync.py'):
            shutil.copy2(SCRIPT.parent / name, scripts / name)
        support = self.base / 'support & local'
        old = support / 'AutoSync/auto_sync_to_github.sh'
        old.parent.mkdir(parents=True)
        old.write_text('old runner retained\n')
        fake_home = self.base / 'home'
        fake_home.mkdir()
        tools = self.base / 'bin'
        tools.mkdir()
        launchctl = tools / 'launchctl'
        launchctl.write_text('#!/bin/sh\nexit 0\n')
        launchctl.chmod(0o755)
        env = dict(os.environ, HOME=str(fake_home), MEMOMARK_REPO_DIR=str(self.repo),
                   MEMOMARK_SUPPORT_DIR=str(support), PATH=str(tools) + os.pathsep + os.environ['PATH'])
        run = subprocess.run(['/bin/zsh', str(scripts / 'install_autosync.sh')], env=env, capture_output=True)
        self.assertEqual(run.returncode, 0, run.stderr)
        target = fake_home / 'Library/LaunchAgents/com.serydoo.memomark.autosync.plist'
        data = plistlib.loads(target.read_bytes())
        self.assertEqual(data['EnvironmentVariables']['MEMOMARK_REPO_DIR'], str(self.repo))
        self.assertEqual(data['EnvironmentVariables']['MEMOMARK_SUPPORT_DIR'], str(support))
        self.assertEqual(data['ProgramArguments'], [str(old), 'prepare'])
        self.assertEqual(old.read_bytes(), (scripts / 'auto_sync_to_github.sh').read_bytes())
        self.assertEqual((old.parent / 'memomark_source_sync.py').read_bytes(), SCRIPT.read_bytes())
        prepared = subprocess.run(['/bin/zsh', str(old)], env=env, capture_output=True)
        self.assertEqual(prepared.returncode, 0, prepared.stdout)
        self.assertTrue((old.parent / 'latest-plan-or-sync.json').is_file())
        self.assertTrue(any(p.read_text() == 'old runner retained\n' for p in support.glob('AutoSync/backups/*/auto_sync_to_github.sh')))

    def test_new_credentials_and_escaping_symlinks_block_publication(self):
        self.put('Docs/unsafe.md', 'token=' + 'ghp_' + 'a' * 30)
        self.assertTrue(any('credential' in p for p in self.plan()['blocked']))
        outside = self.base / 'private.swift'
        outside.write_text('let outside = 1\n')
        (self.repo / 'Source/App/link.swift').symlink_to(outside)
        with self.assertRaises(self.module.SyncError):
            self.plan()

    def test_cli_failure_receipt_does_not_claim_old_success(self):
        self.put('Source/App/new.swift', 'let current = 2\n')
        candidate, receipt = self.validated()
        receipt['checks']['iosArchive']['exit'] = 1
        receipt_path = self.base / 'receipt.json'
        receipt_path.write_text(json.dumps(receipt))
        message = self.base / 'message.txt'
        message.write_text('validated sync')
        output = self.base / 'result.json'
        output.write_text('{"status":"pushed"}')
        result = subprocess.run(['python3', str(SCRIPT), 'sync', '--repo', str(self.repo),
                                 '--output', str(output), '--candidate', str(candidate),
                                 '--receipt', str(receipt_path), '--message-file', str(message)], capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(output.read_text())['status'], 'stopped')
        self.assertEqual(self.git('diff', '--cached', '--name-only'), '')

    def test_unreadable_or_invalid_repo_still_writes_a_failure_receipt(self):
        invalid = self.base / 'not-a-checkout'
        invalid.mkdir()
        output = self.base / 'failure.json'
        output.write_text('{"status":"pushed"}')
        result = subprocess.run(['python3', str(SCRIPT), '--repo', str(invalid), '--output', str(output)], capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(output.read_text())['status'], 'stopped')

    def test_prepare_does_not_refresh_index_metadata(self):
        source = self.repo / 'Source/App/main.swift'
        stat = source.stat()
        os.utime(source, ns=(stat.st_atime_ns, stat.st_mtime_ns + 2_000_000_000))
        index = self.repo / '.git/index'
        before = index.read_bytes()
        self.plan()
        self.assertEqual(index.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
