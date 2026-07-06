# arpcli
```
Date: Mon, 6 Jul 2026 00:00:00 -0500
Subject: arpcli - a perl based ARP Networks Platform API client
From: Todd T. Fries <todd@fries.net>
To: anyone reading this
```

I made this because I wanted a practical command-line tool for the ARP Networks
Platform API (https://phoenix.arpnetworks.com/api/docs) — something I could run
from a shell to see what is on my account without clicking through the dashboard.
It is Perl, uses HTTP::Tiny and JSON::PP, and keeps the API key in a config file
instead of hard-coding it anywhere in the tree.

`arpcli status` walks everything your key can read and prints an outline-style
report (sysctl-ish key=value lines, tables for servers and DNS, catalog listings
for locations, plans, ISOs, and OS templates). Most read commands take `--json`
when you want the raw API body for scripting. Server power actions and a handful
of write operations are wired too, but only if your key has the write scope.

Quick start:

```
mkdir -p ~/.config/arpcli
chmod 700 ~/.config/arpcli
cat > ~/.config/arpcli/conf <<'EOF'
[api]
base_url = https://arpnetworks.com
api_key = arp_live_your_key_here
EOF
chmod 600 ~/.config/arpcli/conf

perl Makefile.PL && make && make test
./bin/arpcli status
./bin/arpcli servers list
./bin/arpcli plans list --thunder
./bin/arpcli servers list --json
```

`prove -lr t/` runs the offline test suite (~279 tests). OpenBSD-style man pages
live in `man/`. See `AI-CRIBNOTES.md` if you are an AI or a future-me picking
this back up. `script/sync-openapi` pulls the upstream OpenAPI spec when that
changes.

Enjoy!

Thanks,

```
--
Todd Fries .. todd@fries.net .. twitter:@unix2mars .. github:toddfries

Label   | Data           | Notes
--------+----------------+------------------------------
Motto   | In support of  | free software solutions.
Phone   | 1.405.252.0702 | SMS/voice everywhere
Mobile  | 1.405.203.6124 | SMS/voice mobile only
Employer| self employed  | Free Daemon Consulting, LLC
Address | PO Box 16169   | Oklahoma City, OK 73113-2169
PGP     | 3F42004A       |
```
