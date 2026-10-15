#!/usr/bin/env python3
"""Plan full-source checkpoints; publish only an explicitly validated exact tree."""
from __future__ import annotations

import argparse
import difflib
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


class SyncError(RuntimeError):
    pass


def git(repo: Path, *args: str) -> bytes:
    result = subprocess.run(['git', '-C', str(repo), *args], capture_output=True,
                            env=dict(os.environ, GIT_OPTIONAL_LOCKS='0'))
    if result.returncode:
        raise SyncError('git failed: ' + result.stderr.decode(errors='replace').strip())
    return result.stdout


def names(data: bytes) -> list[str]:
    return [p.decode('utf-8') for p in data.split(b'\0') if p]


def fingerprint(root: Path, paths) -> dict:
    result = {}
    for relative in sorted(paths):
        p = root / relative
        if p.is_symlink() or not p.resolve().is_relative_to(root.resolve()):
            raise SyncError('review symlink or escaping path: ' + relative)
        if not p.is_file():
            raise SyncError('missing source file: ' + relative)
        result[relative] = {'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
                            'executable': bool(p.stat().st_mode & 0o111)}
    return result


GENERATED_PARTS = {'DerivedData', 'xcuserdata', '__pycache__'}
PRIVATE_SUFFIXES = {'.ipa', '.p12', '.p8', '.pfx', '.pem', '.cer', '.mobileprovision', '.key'}
MEDIA_SUFFIXES = {'.png', '.jpg', '.jpeg', '.heic', '.mov', '.mp4', '.dng', '.raw'}
SOURCE_SUFFIXES = {'.swift', '.py', '.sh', '.xcconfig', '.xcscheme', '.pbxproj',
                   '.strings', '.stringsdict', '.entitlements', '.plist', '.json'}
ROOTS = {'Source', 'Tests', 'scripts', 'ci_scripts', 'Docs', 'Research', '.github', '.codex'}
PRIVATE_PATTERNS = {
    'machine path': re.compile(r'/Users/[A-Za-z0-9._-]+/'),
    'device identifier': re.compile(r'\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}\b'),
    'credential': re.compile(r'gh[pousr]_[A-Za-z0-9_]{20,}|(?<![A-Za-z])sk-(?:proj-)?[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----'),
}


def retained_reason(relative: str) -> str | None:
    p = Path(relative)
    if relative == 'config/mcporter.json':
        return 'machine-local tool connections'
    if relative.startswith(('work/v5-baseline/', '.autosync/')):
        return 'raw local validation evidence'
    if (set(p.parts) & GENERATED_PARTS or any(x.endswith(('.xcarchive', '.xcresult')) for x in p.parts)
            or p.suffix in PRIVATE_SUFFIXES or p.name in {'.DS_Store', 'Icon\r'} or p.suffix == '.pyc'):
        return 'generated state or signing/private material'
    if p.suffix.lower() in MEDIA_SUFFIXES and p.parts[0] not in {'Source', 'Tests'}:
        return 'raw media outside application/test resources'
    return None


def prepare(repo: Path) -> dict:
    repo = repo.resolve()
    if Path(git(repo, 'rev-parse', '--show-toplevel').decode().strip()).resolve() != repo:
        raise SyncError('repo must be the checkout root')
    base = git(repo, 'rev-parse', 'HEAD').decode().strip()
    branch = git(repo, 'branch', '--show-current').decode().strip()
    if not branch:
        raise SyncError('detached HEAD requires explicit review')
    tracked = set(names(git(repo, 'ls-files', '-z')))
    changes = names(git(repo, 'status', '--no-renames', '--porcelain=v1', '-z', '--untracked-files=all'))
    paths, retained, blocked = [], [], []
    for entry in changes:
        relative = entry[3:]
        reason = retained_reason(relative)
        if reason:
            retained.append({'path': relative, 'reason': reason})
        elif relative in tracked or Path(relative).parts[0] in ROOTS or (len(Path(relative).parts) == 1 and
                (Path(relative).suffix == '.md' or relative in {'.gitignore', '.gitattributes', 'Package.swift', 'Package.resolved'})):
            paths.append(relative)
        else:
            blocked.append(relative)
    published = {p for p in tracked | set(paths) if (repo / p).exists() or (repo / p).is_symlink()}
    files = fingerprint(repo, published)
    published_hashes = {item['sha256'] for item in files.values()}
    for item in retained:
        p = repo / item['path']
        if p.suffix in {'.swift', '.py', '.sh'} and p.is_file():
            if hashlib.sha256(p.read_bytes()).hexdigest() not in published_hashes:
                blocked.append(item['path'])
    ignored = names(git(repo, 'ls-files', '--others', '--ignored', '--exclude-standard', '-z',
                        '--', 'Source', 'Tests', 'scripts', 'ci_scripts', 'Research', '.github'))
    for relative in ignored:
        p = Path(relative)
        if not retained_reason(relative) and (p.suffix in SOURCE_SUFFIXES or p.parts[0] in {'Source', 'Tests'}):
            blocked.append(relative)
    for relative in paths:
        p = repo / relative
        if not p.is_file():
            continue
        try:
            current = p.read_text().splitlines()
        except UnicodeError:
            continue
        previous = subprocess.run(['git', '-C', str(repo), 'show', base + ':' + relative], capture_output=True)
        old = previous.stdout.decode(errors='replace').splitlines()
        for op, _, _, begin, end in difflib.SequenceMatcher(None, old, current, autojunk=False).get_opcodes():
            if op == 'equal':
                continue
            for line in range(begin, end):
                for label, pattern in PRIVATE_PATTERNS.items():
                    if pattern.search(current[line]):
                        blocked.append(f'{relative}:{line + 1}: {label}')
    return {'base': base, 'branch': branch, 'paths': sorted(paths), 'files': files,
            'retained': retained, 'blocked': sorted(set(blocked))}


def source_files(root: Path) -> set[str]:
    return {str(p.relative_to(root)) for p in root.rglob('*') if (p.is_file() or p.is_symlink())
            and not (set(p.relative_to(root).parts) & GENERATED_PARTS) and p.name != '.DS_Store'}


def synchronize(repo: Path, candidate: Path, receipt: dict, message: str) -> dict:
    repo, candidate = repo.resolve(), candidate.resolve()
    if git(repo, 'diff', '--cached', '--name-only', '-z'):
        raise SyncError('index already contains staged work; preserve it for review')
    plan = prepare(repo)
    if plan['blocked']:
        raise SyncError('review blocked inputs: ' + ', '.join(plan['blocked']))
    for field in ('base', 'branch', 'files'):
        if receipt.get(field) != plan[field]:
            raise SyncError('stale or incomplete validation receipt: ' + field)
    if source_files(candidate) != set(plan['files']) or fingerprint(candidate, plan['files']) != plan['files']:
        raise SyncError('candidate differs from the complete validated source')
    for check in ('fullTests', 'iosArchive', 'scriptTests'):
        record = receipt.get('checks', {}).get(check, {})
        evidence = Path(record.get('evidence', ''))
        if type(record.get('exit')) is not int or record['exit'] != 0 or not evidence.is_file() or not evidence.stat().st_size:
            raise SyncError('missing or failed validation evidence: ' + check)
    if not plan['paths']:
        return {'commit': plan['base'], 'changedPaths': 0, 'status': 'no changes'}
    if not message.strip():
        raise SyncError('commit message is required')
    ref = 'refs/heads/' + plan['branch']
    remote = git(repo, 'ls-remote', 'origin', ref).decode().split()
    if not remote or remote[0] != plan['base']:
        raise SyncError('remote base changed; review before staging')
    with tempfile.TemporaryDirectory(prefix='MemoMarkValidatedIndex-') as temp:
        stage = Path(temp) / 'stage'; stage.mkdir()
        allowlist = Path(temp) / 'paths.bin'
        allowlist.write_bytes(b'\0'.join(p.encode() for p in plan['paths']) + b'\0')
        git(repo, '--literal-pathspecs', 'add', '--pathspec-from-file=' + str(allowlist), '--pathspec-file-nul')
        if set(names(git(repo, 'diff', '--cached', '--name-only', '--no-renames', '-z'))) != set(plan['paths']):
            raise SyncError('staged paths differ; index preserved for review')
        git(repo, 'diff', '--cached', '--check')
        git(repo, 'checkout-index', '--all', '--prefix=' + str(stage) + '/')
        if source_files(stage) != set(plan['files']) or fingerprint(stage, plan['files']) != plan['files']:
            raise SyncError('index export differs from the validated complete tree')
        # Guard races with another local editor or a remote writer before committing.
        if git(repo, 'rev-parse', 'HEAD').decode().strip() != plan['base'] or prepare(repo)['files'] != plan['files']:
            raise SyncError('source changed while staging; index preserved for review')
        if git(repo, 'ls-remote', 'origin', ref).decode().split()[0] != plan['base']:
            raise SyncError('remote changed while staging; index preserved for review')
        validated_tree = git(repo, 'write-tree').decode().strip()
        body = Path(temp) / 'commit-message.txt'; body.write_text(message)
        git(repo, 'commit', '-F', str(body))
        commit = git(repo, 'rev-parse', 'HEAD').decode().strip()
        if git(repo, 'rev-parse', 'HEAD^{tree}').decode().strip() != validated_tree:
            raise SyncError('commit hook changed the validated tree; local commit retained, not pushed')
        if git(repo, 'rev-parse', 'HEAD^').decode().strip() != plan['base']:
            raise SyncError('commit parent changed; local commit retained, not pushed')
        git(repo, 'push', 'origin', 'HEAD:' + ref)
        if git(repo, 'ls-remote', 'origin', ref).decode().split()[0] != commit:
            raise SyncError('post-push remote SHA differs from local commit')
    return {'commit': commit, 'branch': plan['branch'], 'changedPaths': len(plan['paths']),
            'sourceFiles': len(plan['files']), 'status': 'pushed'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('prepare', 'sync'), nargs='?', default='prepare')
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--candidate', type=Path)
    parser.add_argument('--receipt', type=Path)
    parser.add_argument('--message-file', type=Path)
    args = parser.parse_args()
    try:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        lock_key = hashlib.sha256(str(args.repo.resolve()).encode()).hexdigest()
        lock_path = Path(tempfile.gettempdir()) / ('memomark-source-sync-' + lock_key + '.lock')
        descriptor = os.open(lock_path, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        with os.fdopen(descriptor, 'a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            try:
                if args.mode == 'prepare':
                    result = prepare(args.repo)
                else:
                    if not all((args.candidate, args.receipt, args.message_file)):
                        raise SyncError('sync requires --candidate, --receipt and --message-file')
                    result = synchronize(args.repo, args.candidate, json.loads(args.receipt.read_text()), args.message_file.read_text())
                args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
            except (SyncError, OSError, ValueError, KeyError) as error:
                failure = {'status': 'stopped', 'error': str(error), 'localCommit': None}
                try:
                    failure['localCommit'] = git(args.repo, 'rev-parse', 'HEAD').decode().strip()
                except SyncError:
                    pass
                args.output.write_text(json.dumps(failure, ensure_ascii=False, indent=2) + '\n')
                raise
        print(f"{args.mode}: {result.get('status', 'plan saved')}; {args.output}")
        return 0
    except (SyncError, OSError, ValueError, KeyError) as error:
        print('Source sync stopped: ' + str(error))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
