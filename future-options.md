# Future options

Reference for later arpcli passes.

## CLI enhancements

- [ ] `servers create` with flags for plan_id, os_template, location, ssh_key_ids (API module exists; CLI not wired)
- [x] `dns-records create|update|delete`
- [x] `ssh-keys create|delete` subcommands

- [ ] Filter flags: `servers list --state running`, `isos list --grep openbsd`
- [ ] Colored output and `--quiet` for errors-only
- [ ] Configurable default bandwidth range in `arpcli.conf`

## API coverage

- [ ] Detect API key scope by probing a write endpoint and caching result
- [ ] ETag / If-None-Match if API adds caching headers
- [ ] List plan add-ons / extras (no endpoint in OpenAPI v1; `GET /plans` returns only `vps_*` and `thunder_*` base plans with `prices{hourly,monthly}` — no add-on catalog)
- [x] Client-side rate-limit journal at `~/.cache/arpcli/usage` (54 key / 108 IP / 6 server-create per 60s with margin; `retry_after` journal lines from 429 Retry-After; `-v` warns before `sleep()`; disable via `ARPCLI_NO_RATE_LIMIT=1`)
- [ ] Surface rate-limit quota headers if ARP adds them (live responses currently expose only `x-request-id`, `x-runtime`, `x-cache`)


## Output

- [ ] `status --brief` summary only (counts + server table)
- [ ] Export to YAML or JSON for ansible/terraform consumption
- [ ] Match dashboard billing page layout more closely
- [ ] Human-readable relative timestamps (created_at → "16 years ago")

## Quality

- [ ] CI workflow running `prove -lr t`
- [ ] Install target / package (OpenBSD port, Debian package)
- [ ] Pod coverage in modules; `perldoc ArpCLI::Client`
- [x] Live integration tests behind `ARPCLI_LIVE=1` guard (`t/fuzz-live.t`; see `AI-CRIBNOTES.txt`)

## Security

- [ ] Support reading api_key from env `ARPCLI_API_KEY` as override
- [ ] Optional `keyring` / pass integration

## Documentation


- [ ] Example session in README for `arpcli status` sample output