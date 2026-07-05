use strict;
use warnings;

use Test::More;
use lib 'lib';

use ArpCLI::Util qw(redact_secrets redact_headers);
use ArpCLI::Error;

is(
    redact_secrets('Bearer arp_live_secret123 token'),
    'Bearer [REDACTED] token',
);
is(
    redact_secrets('api_key=arp_live_abc_def'),
    'api_key=[REDACTED]',
);
is(
    redact_secrets('prefix arp_live_Tr8MM3UY5X4rprgIWJ9RdsQzfELSwi4_rQRXfmk5e1c suffix'),
    'prefix arp_live_[REDACTED] suffix',
);

my $hdr = redact_headers({ Authorization => 'Bearer secret', Accept => 'application/json' });
is($hdr->{Authorization}, 'Bearer [REDACTED]');
is($hdr->{Accept}, 'application/json');

my $err = ArpCLI::Error->new(
    message => 'failed with Bearer arp_live_leaked',
);
is("$err", 'failed with Bearer [REDACTED]');
like($err->debug_dump, qr/Bearer \[REDACTED\]/);
unlike($err->debug_dump, qr/arp_live_leaked/);

done_testing;