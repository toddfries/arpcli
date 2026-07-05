# Future options

Reference for later arpcli passes.

## CLI enhancements

- [ ] `servers create` with flags for plan_id, os_template, location, ssh_key_ids (API module exists; CLI not wired)
- [ ] `dns-records create|update|delete` subcommands with validation messages (API module exists; CLI not wired)
- [ ] `ssh-keys create|delete` subcommands (API module exists; CLI not wired)
- [ ] JSON output mode (`--json`) for scripting
- [ ] Filter flags: `servers list --state running`, `isos list --grep openbsd`
- [ ] Colored output and `--quiet` for errors-only
- [ ] Configurable default bandwidth range in `arpcli.conf`

## API coverage

- [ ] Detect API key scope by probing a write endpoint and caching result
- [ ] Retry with backoff on 429 and 502
- [ ] ETag / If-None-Match if API adds caching headers
- [ ] Watch for new endpoints in docs.yaml (diff on upgrade)

## Output

- [ ] `status --brief` summary only (counts + server table)
- [ ] Export to YAML or JSON for ansible/terraform consumption
- [ ] Match dashboard billing page layout more closely
- [ ] Human-readable relative timestamps (created_at → "16 years ago")

## Quality

- [ ] CI workflow running `prove -lr t`
- [ ] Install target / package (OpenBSD port, Debian package)
- [ ] Pod coverage in modules; `perldoc ArpCLI::Client`
- [ ] Live integration tests behind `ARPCLI_LIVE=1` guard

## Security

- [ ] Support reading api_key from env `ARPCLI_API_KEY` as override
- [ ] Optional `keyring` / pass integration

## Documentation

- [ ] Sync manuals/ when OpenAPI spec changes (script to pull docs.yaml)
- [ ] Example session in README for `arpcli status` sample output