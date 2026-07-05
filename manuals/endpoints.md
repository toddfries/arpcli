# Endpoints

All paths are under `/api/v1/`. Module mapping in `lib/ArpCLI/API/`.

## Read (GET)

| Path | Module | Method |
|------|--------|--------|
| `/locations` | Locations | `list` |
| `/isos` | Isos | `list` |
| `/plans` | Plans | `list` |
| `/os_templates` | OsTemplates | `list` |
| `/servers` | Servers | `list` (paginated) |
| `/servers/{uuid}` | Servers | `show` |
| `/servers/{uuid}/bandwidth?range=` | Servers | `bandwidth` |
| `/servers/{uuid}/billing` | Servers | `billing` |
| `/servers/{uuid}/ssh_host_keys` | Servers | `ssh_host_keys` |
| `/dns_records` | DnsRecords | `list` (paginated) |
| `/ssh_keys` | SshKeys | `list` |

## Write (non-GET)

| Path | Module | Scope |
|------|--------|-------|
| POST `/servers` | Servers | provision |
| DELETE `/servers/{uuid}` | Servers | write |
| POST `/servers/{uuid}/actions/boot` | ServerActions | write |
| POST `.../shutdown` | ServerActions | write |
| POST `.../poweroff` | ServerActions | write |
| POST `.../reset` | ServerActions | write |
| POST `.../change_iso` | ServerActions | write |
| POST `.../set_parameter` | ServerActions | write |
| POST/PATCH/DELETE `/dns_records` | DnsRecords | write |
| POST/DELETE `/ssh_keys` | SshKeys | write |

## Bandwidth `range` values

`1h`, `6h`, `24h`, `7d`, `30d` (default `30d`)