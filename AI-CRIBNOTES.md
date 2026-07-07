# AI-CRIBNOTES.md

Compact briefing for AI agents working on **arpcli**. **Read this first.** Update the
[Pass log](#pass-log) at the end of every session when behavior, layout, or workflow changes.

---

## Mandatory workflow

1. **Read** this file + skim `future-options.md` for scope.
2. **Implement** focused changes only (no drive-by refactors).
3. **Update man pages** (`man/arpcli.1`, `man/arpcli.conf.5`) when CLI behavior, flags, or
   config changes. Keep mdoc long options as `.Fl -json` not `.Fl json` (`t/man-flags.t`).
4. **Regress** before commit:
   ```bash
   prove -lr t/                    # expect ~280+ tests, all PASS
   ARPCLI_LIVE=1 prove -lr t/fuzz-live.t   # optional; needs ~/.config/arpcli/conf
   ```
5. **Add regress** for every bug found, fixed, or feared (see [Regression policy](#regression-policy)).
6. **Commit** when regress is green. **Do not leave completed work uncommitted.**
7. **Update this file** (Pass log + any new gotchas) when behavior or workflow changes.

### Commit messages

- Complete sentences; say *what* and *why*.
- Imperative subject (~50 chars); body optional for non-obvious context.
- Examples from this repo:
  - `Add --json output to all sensible arpcli commands`
  - `Fix man page long-option spelling for --json and --thunder`
  - `Expand fuzz regression coverage from lessons learned`

### What not to commit

- API keys, `~/arpcode`, or contents of `~/.config/arpcli/conf`
- Debug prints of secrets (use `ArpCLI::Util::redact_secrets`; see `t/redact.t`)

---

## Quick orientation

| Path | Role |
|------|------|
| `bin/arpcli` | CLI entry; subcommand dispatch, `--json` wiring |
| `lib/ArpCLI/Client.pm` | Composes API modules; `discover()` for `status` |
| `lib/ArpCLI/HTTP.pm` | JSON HTTP; throws `ArpCLI::Error`; 429/502 retry |
| `lib/ArpCLI/API/*.pm` | Resource clients; `*_raw` for API-shaped output |
| `lib/ArpCLI/CLI/Args.pm` | `extract_json`, `extract_range`, `extract_thunder` |
| `lib/ArpCLI/CLI/Format.pm` | `print_json` (pretty canonical UTF-8) |
| `lib/ArpCLI/Output.pm` | Human `status` report (sysctl-style) |
| `lib/ArpCLI/Plans/Format.pm` | Grouped VPS / ARP Thunder plans table |
| `t/lib/Test/MockHTTP.pm` | Inject as HTTP `agent` for offline tests |
| `spec/openapi.yaml` | Canonical API spec; sync via `script/sync-openapi` |
| `man/arpcli.1` | mdoc; long opts need `.Fl -json` not `.Fl json` |
| `.proverc` | `-Ivendor/lib/perl5 -It/lib -Ilib` (YAML::PP vendored) |

Config: `~/.config/arpcli/conf` — INI `[api]` with `base_url`, `api_key`.

---

## CLI surface (current)

### Read commands (`--json` supported)

`status [--range 30d] [--json]` · `servers list|show|bandwidth|billing|ssh-host-keys` ·
`locations [list]` · `plans [list] [--thunder]` · `isos [list]` · `os-templates [list]` ·
`dns-records list` · `ssh-keys list`

Single-subcommand resources accept flags without `list` (`plans --json` ≡ `plans list --json`).
Use `ArpCLI::CLI::Args::extract_list_subcommand`.

### Write commands (CLI wired; need **write**-scoped key)

`servers delete|boot|shutdown|poweroff|reset|change-iso|set-parameter` — all accept `--json`.

### API exists, CLI **not** wired (fuzz regress expects `unknown subcommand`)

`servers create` · `dns-records create|update|delete` · `ssh-keys create|delete`

When wiring these: add CLI + `t/fuzz.t` cases + mock/live scope tests + update `man/arpcli.1`.

### Exit codes (intentional but easy to get wrong)

| Source | Exit |
|--------|------|
| CLI parse/usage `die "arpcli: ..."` | **255** |
| `ArpCLI::Error` (API, config, uuid) | **1** |
| Success / `-h` | **0** |

Regress: `t/fuzz.t` convention block at bottom.

### `--json` behavior

- Read: raw API body; paginated lists use aggregated envelope:
  `{ "servers"|"dns_records": [...], "meta": { "pagination": { "total_entries": N, "aggregated": true } } }`
- `status --json`: `discover()` hash (not single API call).
- Multiple `--json` flags: all stripped silently (`t/cli-args.t`).

---

## Testing

```bash
prove -lr t/                 # default; uses .proverc
prove -lr t/fuzz.t           # CLI invalid-usage matrix
prove -lr t/fuzz-scope.t     # mock 403 write / 422 range
ARPCLI_LIVE=1 prove -lr t/fuzz-live.t
```

### Test file map

| File | Covers |
|------|--------|
| `t/00-load.t` | All modules compile |
| `t/api.t` | Client + pagination + `list_raw` envelopes |
| `t/http.t` / `t/http-retry.t` | HTTP errors, retry, redaction in logs |
| `t/config.t` / `t/edge.t` | Config edge cases, uuid, 204 DELETE |
| `t/cli-args.t` / `t/cli-json.t` | Flag parsing, JSON print |
| `t/fuzz.t` | CLI misuse: bad args, unwired cmds, injection strings |
| `t/fuzz-scope.t` | **Every write API path** → mock `insufficient_scope` 403 |
| `t/fuzz-live.t` | Live read-only key: create DNS, boot, delete, bad range |
| `t/output.t` | `status` layout; **no wide-char warnings** for `™` in plans |
| `t/man-flags.t` | mdoc `--json` spelling (`.Fl -json`) |
| `t/plans-format.t` | Grouped plans table, `display_width` |
| `t/openapi-coverage.t` | Registry ↔ API ↔ CLI coverage |
| `t/sync-openapi.t` | OpenAPI pull/codegen (needs vendor YAML::PP) |
| `t/redact.t` | Secrets never leak in errors/logs |

### Mock pattern

```perl
use Test::MockHTTP;
my $mock = Test::MockHTTP->new(responses => {
    "GET $base/api/v1/foo" => { status => 200, content => '{"..."}' },
});
my $client = ArpCLI::Client->new(http => ArpCLI::HTTP->new(
    base_url => $base, api_key => 'k', agent => $mock,
));
```

**Gotcha:** mock keys are `"METHOD $full_url"` including query string, e.g.
`GET .../bandwidth?range=notvalid` (`t/fuzz-scope.t`).

CLI subprocess tests: temp INI under `t/tmp-*-$$.ini`, `qx($perl -Ilib bin/arpcli -c $tmp ...)`.
Help tests: `local $ENV{__ARPCLI_TEST_EXIT} = 0`.

---

## Regression policy

**When you find or fix any bug, add a test in the same commit** (or immediately after).

| Trigger | Add regress to |
|---------|----------------|
| CLI bad input / unknown subcommand | `t/fuzz.t` |
| Write scope / API error type | `t/fuzz-scope.t` (+ `t/fuzz-live.t` if live-verified) |
| Flag parsing | `t/cli-args.t` |
| HTTP / retry / JSON parse | `t/http.t` or `t/http-retry.t` |
| status / table / Unicode | `t/output.t` or `t/plans-format.t` |
| man page flags | `t/man-flags.t` |
| New API method | `t/api.t` or dedicated `t/<feature>.t` |
| OpenAPI/registry drift | `t/openapi-coverage.t` |

Fuzz mindset: try path traversal in UUIDs, missing args, doubled flags, unwired subcommands,
read-only key against writes, invalid `--range`, `-c` missing config alone, command injection in
argv. **If it broke once, it gets a test.**

---

## Known gotchas

### mdoc long options

`.Fl json` renders **`-json`**. Use **`.Fl -json`** for `--json`. Same for `--thunder`.
`--range` already uses `.Fl -range`. Guard: `t/man-flags.t`.

### Wide characters

Plan names include `™`. Use `display_width` + UTF-8 `binmode` for tables
(`Output.pm`, `Plans/Format.pm`, `bin/arpcli` `print_table`). Guard: `t/output.t`.

### `-c` without command

`arpcli -c /bad/path` must **not** print usage and exit 0; must report missing config.
`bin/arpcli` validates config when `-c` is set even if args empty. Guard: `t/fuzz.t`.

### List methods in scalar context

Never `return []` bare in scalar context — returns `0`. Use `return [] if wantarray; return []`
or always return ref in list context only. (Historical bug in list methods.)

### Read-only API key

Live write attempts return `type=insufficient_scope`, `status=403`,
message `This API key does not have the 'write' scope`. Guard: `t/fuzz-scope.t`, `t/fuzz-live.t`.

### `plans` / catalog commands with no `list`

Default subcommand is `list`. Flags may precede it (`plans --json`, not `plans list --json`
only). **Gotcha:** naive `shift @args` treats `--json` as a subcommand name — use
`extract_list_subcommand`. Applies to `locations`, `plans`, `isos`, `os-templates`.
Regress: `t/cli-args.t`, `t/fuzz.t`.

### `Test::Throws`

Custom in `t/lib/Test/Throws.pm` — prototype `(&$;$)`. Regex classes don't work; use `dies_like`
with `like($@, qr/.../)` for string dies.

### OpenAPI sync

`script/sync-openapi` needs `vendor/lib/perl5` (YAML::PP). Updates `spec/`, `manuals/`,
registry manifests. Run `t/sync-openapi.t` after spec changes.

### API error shape

```json
{ "error": { "type": "...", "message": "..." } }
```

Types: `unauthorized`, `forbidden`, `insufficient_scope`, `not_found`, `invalid_range`,
`unprocessable`, `invalid_iso_file`, `invalid_parameter`, `payment_method_required`,
`rate_limited`, `dispatch_failed`. See `manuals/errors.md`.

---

## Adding a feature (checklist)

1. API method in `lib/ArpCLI/API/<Resource>.pm` (+ `*_raw` if JSON output)
2. Accessor in `Client.pm` if new resource
3. Subcommand in `bin/arpcli` (+ `usage()` + **`man/arpcli.1`** — required same pass)
4. Mock test + fuzz case if CLI-facing
5. `script/sync-openapi` if OpenAPI changed; keep `t/openapi-coverage.t` green
6. Trim `future-options.md` when done
7. Update **Pass log** below

---

## Live account snapshot (read-only key; 2026-07)

For manual/live regress: 3 running servers, 3 DNS PTRs, 0 SSH keys. Write calls fail 403
scope. Do not mutate production without explicit user approval.

---

## Pass log

| Date | Summary |
|------|---------|
| 2026-07-06 | Initial crib notes. 279 offline tests; `t/fuzz*.t`, `t/cli-args.t`, `t/fuzz-scope.t`. `--json` on all sensible commands. Fuzz fixes: `-c` alone, status `™` wide chars. Man: `.Fl -json`. |
| 2026-07-07 | Workflow: regress + manpages + commit + update crib each pass. Fix `plans --json` (and locations/isos/os-templates): `extract_list_subcommand` so flags are not parsed as subcommands. |

<!-- AI: append a row when you change behavior, tests, or workflow. -->