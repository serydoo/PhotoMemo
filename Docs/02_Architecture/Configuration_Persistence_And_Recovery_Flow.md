# Configuration Persistence And Recovery Flow

## Durable Truth

`ConfigurationLibraryRecord` is the only runtime durable configuration truth. `MemorySubject` is the aggregate root; subject and configuration names are display values, while hidden UUIDs define identity.

The primary aggregate is stored atomically in the App Group configuration library. `last-known-good.json` is recovery data. Legacy UserDefaults keys and configuration slots are compatibility projections only and must never write back into aggregate truth.

## Apply Flow

```text
Configuration Session
  -> build complete aggregate candidate
  -> resolve album destination
  -> atomically save primary aggregate
  -> emit revisioned save receipt
  -> write compatibility projections
  -> publish matching production snapshot
  -> reconcile the Session from the same receipt
```

Primary write failure leaves compatibility settings, production state, and Session selection unchanged. A compatibility-projection failure is recorded in the receipt and must not replace the primary aggregate.

## Complete Configuration Boundary

Each `MemoryConfigurationRecord` owns its editor, presentation, location, Memory copy, Photos description policy, album destination, media mode, Live Photo policy, selected anchor and canonical `classicWhite` route. Renderer layout constants are not configuration data.

## Local Backup

Local `.memomarkconfig` documents are inert backups organized under the subject UUID. Documents use relative asset paths and checksums. Saving or deleting a live configuration does not implicitly delete its backups.

## Import And Restore

Import validates schema, ownership, checksum and assets before mutation. Same-name/different-ID subjects remain distinct. A colliding configuration ID restores as a copy by default. Missing anchors, albums and assets produce explicit recovery resolutions rather than partial silent writes.

Only Restore And Make Current enters the normal aggregate apply flow. Import alone does not publish a production snapshot.

## Frozen Jobs

`BatchConfigurationSnapshot` carries configuration ID and revision. Jobs retain the snapshot captured at admission; later import, deletion or apply operations cannot mutate an existing job.

## Recovery

Startup loads the primary aggregate first and falls back to last-known-good only when primary decoding or validation fails. After recovery, compatibility projections may be repaired from the recovered aggregate. Unsupported future schemas are rejected without destructive migration.
