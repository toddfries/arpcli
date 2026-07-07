use strict;
use warnings;

use Test::More;
use lib 'lib';

use ArpCLI::Output;

my $buf = '';
open my $fh, '>', \$buf or die $!;

my $data = {
    servers => [{
        uuid => '52326bc0-79df-012c-d6f1-00163ec95f4c',
        label => 'web-01',
        state => 'running',
        plan => 'VPS-1G',
        os_template => 'openbsd-7.6-amd64',
        primary_ipv4 => '10.0.0.1',
        primary_ipv6 => undef,
        specs => [{ name => 'CPU', quantity => 1, unit => 'core' }],
        billing_mode => 'reserved',
        billing_interval => 'monthly',
        location => 'LAX',
        created_at => '2020-01-01T00:00:00Z',
    }],
    server_detail => {
        '52326bc0-79df-012c-d6f1-00163ec95f4c' => {
            bandwidth => {
                range => '30d',
                inbound_bytes => 1024,
                outbound_bytes => 2048,
                total_bytes => 3072,
            },
            billing => {
                billing_mode => 'reserved',
                interval => 'monthly',
                total => 10,
                line_items => [{
                    label => 'VPS-1G',
                    quantity => 1,
                    unit_price => 10,
                    amount => 10,
                }],
            },
            ssh_host_keys => [{ type => 'ED25519', fingerprint => 'SHA256:abc' }],
        },
    },
    dns_records => [{ id => 1, name => '1.0.0.10.in-addr.arpa', content => 'host.', domain => 'zone' }],
    ssh_keys => [],
    locations => [{ code => 'LAX', name => 'Los Angeles', country => 'US' }],
    plans => [
        { id => 1, code => 'vps_small', name => 'Small', specs => [], prices => { monthly => 10 } },
        { id => 7, code => 'thunder_starter', name => "ARP Thunder\x{2122} - Starter", specs => [], prices => { monthly => 40 } },
    ],
    isos => ['test.iso'],
    os_templates => {
        openbsd => {
            title => 'OpenBSD',
            series => [{ title => 'OpenBSD', version => '7.6', code => 'openbsd-7.6-amd64' }],
        },
    },
    bandwidth_range => '30d',
};

my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    ArpCLI::Output->new(fh => $fh)->print_discovery($data);
}
close $fh;

like($buf, qr/arp\.account/);
like($buf, qr/arp\.servers/);
like($buf, qr/web-01/);
like($buf, qr/arp\.dns_records/);
like($buf, qr/arp\.catalog/);
like($buf, qr/openbsd-7\.6-amd64/);
like($buf, qr/ARP Thunder/, 'status output includes trademark plan name');
is(scalar @warnings, 0, 'status output emits no wide-character warnings');

$buf = '';
open $fh, '>', \$buf or die $!;
@warnings = ();
{
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    ArpCLI::Output->new(fh => $fh)->print_discovery($data, brief => 1);
}
close $fh;

like($buf, qr/arp\.account/, 'brief output has account counts');
like($buf, qr/arp\.servers/, 'brief output has server table');
like($buf, qr/web-01/, 'brief output lists server label');
unlike($buf, qr/server\.52326bc0/, 'brief output omits per-server detail');
unlike($buf, qr/arp\.dns_records/, 'brief output omits dns section');
unlike($buf, qr/arp\.catalog/, 'brief output omits catalog section');
is(scalar @warnings, 0, 'brief output emits no wide-character warnings');

done_testing;