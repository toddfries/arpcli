# Project layout

```
arpcli/
├── bin/arpcli              # CLI entry
├── lib/ArpCLI/
│   ├── Config.pm           # INI loader
│   ├── HTTP.pm             # JSON HTTP client (injectable agent for tests)
│   ├── Client.pm           # Composes API modules; discover()
│   ├── Output.pm           # status report formatter
│   ├── Util.pm             # uuid, bytes, specs, pagination
│   └── API/*.pm            # One module per API resource
├── t/                      # Test::More suite + Test::MockHTTP
├── man/                    # OpenBSD mdoc (arpcli.1, arpcli.conf.5)
├── manuals/                # AI token-saving topic docs
└── future-options.md       # Next-session roadmap
```

## Testing pattern

Inject `Test::MockHTTP` as `agent` into `ArpCLI::HTTP->new`, then build `ArpCLI::Client->new(http => ...)`.

## Adding an endpoint

1. Add method to `lib/ArpCLI/API/<Resource>.pm`
2. Wire accessor in `Client.pm` if new resource
3. Add CLI subcommand in `bin/arpcli`
4. Add `t/api.t` or dedicated test with mock response
5. Update `manuals/endpoints.md`