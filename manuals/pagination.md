# Pagination

Parameters: `page` (1-indexed, default 1), `per_page` (default 50, max 100).

Paginated endpoints: `GET /servers`, `GET /dns_records`.

Implementation: `ArpCLI::Util::paginate_all` via `ArpCLI::API::Base::_paginate`.

Loop until `meta.pagination.next_page` is null; accumulate all items.