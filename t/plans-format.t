use strict;
use warnings;

use Test::More;
use lib 'lib';

use ArpCLI::Plans::Format;
use ArpCLI::Util qw(display_width);

is(ArpCLI::Plans::Format::group({ code => 'vps_small' }), 'vps');
is(ArpCLI::Plans::Format::group({ code => 'thunder_starter' }), 'thunder');
is(
    ArpCLI::Plans::Format::short_name({ name => 'ARP Thunder™ - Starter Plan' }),
    'Starter Plan',
);
is(
    ArpCLI::Plans::Format::short_name({ name => 'VPS - "The American"' }),
    'The American',
);
is(
    ArpCLI::Plans::Format::format_prices({ monthly => 10, hourly => 0.01369863 }),
    '$10.00/mo $0.0137/hr',
);

ok(display_width('ARP Thunder™ - Starter') >= display_width('ARP Thunder(TM) - Starter'));

my $buf = '';
open my $fh, '>', \$buf or die $!;
ArpCLI::Plans::Format::print_grouped($fh, [
    { id => 1, code => 'vps_small', name => 'VPS - Small Plan', prices => { monthly => 10 }, specs => [] },
    { id => 7, code => 'thunder_starter', name => 'ARP Thunder™ - Starter Plan', prices => { monthly => 40 }, specs => [] },
]);
close $fh;
like($buf, qr/^VPS/m);
like($buf, qr/^ARP Thunder/m);
like($buf, qr/Starter Plan/);
unlike($buf, qr/ARP Thunder™/);

done_testing;