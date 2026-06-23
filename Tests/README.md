# Tests

This folder contains fixtures and Swift test sources.

Current structure:

- `Fixtures/`
- `PhotoMemoTests/BatchTests/`
- `PhotoMemoTests/ExportTests/`
- `PhotoMemoTests/MemoryEngineTests/`
- `PhotoMemoTests/MetadataTests/`
- `PhotoMemoTests/RendererTests/`
- `PhotoMemoTests/VariableTests/`
- `PhotoMemoTests/Support/`

V2 direction:

- Add Layout Engine contract tests before renderer migration.
- Prefer testing measurable specifications over renderer-local constants.
- Keep private research datasets out of test fixtures.
