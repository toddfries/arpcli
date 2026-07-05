# arpcli manuals index

Token-saving reference for future AI sessions. Each topic file extracts the
minimum context needed to extend arpcli without re-reading the full OpenAPI spec.

## Topics

| Topic | File | Use when |
|-------|------|----------|
| API overview | [api-overview.md](api-overview.md) | Auth, scopes, rate limits, base URL |
| Endpoints | [endpoints.md](endpoints.md) | Adding or changing API resource modules |
| Schemas | [schemas.md](schemas.md) | Parsing responses, output fields |
| Pagination | [pagination.md](pagination.md) | List endpoints with `meta.pagination` |
| Errors | [errors.md](errors.md) | HTTP status and `error.type` handling |
| Project layout | [project-layout.md](project-layout.md) | Where code, tests, and docs live |

## Sync

Run `script/sync-openapi` after API releases. It fetches the OpenAPI spec,
updates `spec/`, regenerates auto-synced manuals, and refreshes
`spec/registry.json`.

## External docs

- Live spec: https://phoenix.arpnetworks.com/api/docs
- YAML source: https://phoenix.arpnetworks.com/api/docs.yaml

## Future work

See [../future-options.md](../future-options.md) for planned enhancements.