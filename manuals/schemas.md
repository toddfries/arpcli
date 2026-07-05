# Key schemas

## Server

Required: `uuid`, `label`, `state`, `billing_mode`, `os_template`, `plan`, `specs`, `created_at`.

Notable fields: `state` ∈ running|shutoff|paused|crashed|unknown; `billing_mode` ∈ reserved|on-demand; `specs[]` has `name`, `quantity`, `unit`; `primary_ipv4`, `primary_ipv6`, `ip_space`, `location`.

## ServerBilling

`billing_mode`, `interval`, `line_items[]`, `total`. Optional: `free`, `est_monthly`, `uninvoiced_hours`, `uninvoiced_amount`.

## Bandwidth

`range`, `inbound_bytes`, `outbound_bytes`, `total_bytes` (bytes may be null).

## DnsRecord

`id`, `name` (ARPA), `type`, `content` (PTR target), `domain`.

## Plan

`id`, `code`, `name`, `specs[]`, `prices{hourly,monthly}`.

## OsTemplates

`os_templates` is a hash keyed by family; each has `title`, `logo`, `series[]` with `title`, `version`, `code`.

## Pagination envelope

Lists return `{ items_key: [...], meta: { pagination: { page, per_page, previous_page, next_page, last_page, total_entries } } }`.