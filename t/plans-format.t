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

my $vps_row = ArpCLI::Plans::Format::row_values({
    id => 1, code => 'vps_small', name => 'VPS - Small Plan',
    prices => { monthly => 10, hourly => 0.01369863 },
    specs => [
        { name => 'Storage', quantity => 40, unit => 'GB' },
        { name => 'RAM', quantity => 1024, unit => 'MB' },
        { name => 'CPU', quantity => 2, unit => 'core' },
    ],
}, 'vps');
is_deeply($vps_row, [1, 'vps_small', 'Small Plan', '10.00', '0.0137', '40', '1024', '2']);

my $thunder_row = ArpCLI::Plans::Format::row_values({
    id => 7, code => 'thunder_starter', name => 'ARP Thunder™ - Starter Plan',
    prices => { monthly => 40, hourly => 0.05479452 },
    specs => [
        { name => 'RAM', quantity => 4096, unit => 'MB' },
        { name => 'Storage (SATA)', quantity => 200, unit => 'GB' },
        { name => 'Storage', quantity => 80, unit => 'GB' },
        { name => 'CPU', quantity => 2, unit => 'core' },
    ],
}, 'thunder');
is($thunder_row->[5], '80+200');

my $buf = '';
open my $fh, '>', \$buf or die $!;
ArpCLI::Plans::Format::print_grouped($fh, [
    { id => 1, code => 'vps_small', name => 'VPS - Small Plan', prices => { monthly => 10, hourly => 0.01 }, specs => [
        { name => 'Storage', quantity => 40, unit => 'GB' },
        { name => 'RAM', quantity => 1024, unit => 'MB' },
        { name => 'CPU', quantity => 2, unit => 'core' },
    ] },
    { id => 7, code => 'thunder_starter', name => 'ARP Thunder™ - Starter Plan', prices => { monthly => 40 }, specs => [
        { name => 'Storage', quantity => 80, unit => 'GB' },
        { name => 'Storage (SATA)', quantity => 200, unit => 'GB' },
        { name => 'RAM', quantity => 4096, unit => 'MB' },
        { name => 'CPU', quantity => 2, unit => 'core' },
    ] },
]);
close $fh;
like($buf, qr/^VPS/m);
like($buf, qr/Price\s+Specs/m);
like($buf, qr/monthly hourly.*Disk\s+RAM\s+CPU/m);
like($buf, qr/80\+200/);
like($buf, qr/Storage \(SATA\)/);
unlike($buf, qr/ARP Thunder™/);

done_testing;