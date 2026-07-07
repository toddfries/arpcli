use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';
use Test::Throws qw(throws_ok);

use ArpCLI::HTTP;
use ArpCLI::Client;
use ArpCLI::Error;
use Test::MockHTTP;

my $base = 'https://example.test';
my $uuid = '52326bc0-79df-012c-d6f1-00163ec95f4c';

my $mock = Test::MockHTTP->new(
    responses => {
        "GET $base/api/v1/servers?page=1" => {
            status  => 200,
            content => qq({"servers":[{"uuid":"$uuid","label":"a"}],"meta":{"pagination":{"page":1,"next_page":2}}}),
        },
        "GET $base/api/v1/servers?page=2" => {
            status  => 200,
            content => qq({"servers":[{"uuid":"c767c910-55b3-0135-1456-525400972102","label":"b"}],"meta":{"pagination":{"page":2}}}),
        },
        "GET $base/api/v1/servers/$uuid" => {
            status  => 200,
            content => qq({"server":{"uuid":"$uuid","label":"a","state":"running"}}),
        },
        "GET $base/api/v1/servers/$uuid/bandwidth" => {
            status  => 200,
            content => '{"bandwidth":{"range":"30d","inbound_bytes":100,"outbound_bytes":200,"total_bytes":300}}',
        },
        "POST $base/api/v1/servers/$uuid/actions/boot" => {
            status  => 202,
            content => '{"status":"queued","action":"boot"}',
        },
        "GET $base/api/v1/dns_records?page=1" => {
            status  => 200,
            content => '{"dns_records":[{"id":1,"name":"x","content":"y.","domain":"z"}],"meta":{"pagination":{"page":1}}}',
        },
        "GET $base/api/v1/ssh_keys" => {
            status  => 200,
            content => '{"ssh_keys":[]}',
        },
        "GET $base/api/v1/locations" => {
            status  => 200,
            content => '{"locations":[]}',
        },
        "GET $base/api/v1/plans" => {
            status  => 200,
            content => '{"plans":[]}',
        },
        "GET $base/api/v1/isos" => {
            status  => 200,
            content => '{"isos":["a.iso"]}',
        },
        "GET $base/api/v1/os_templates" => {
            status  => 200,
            content => '{"os_templates":{}}',
        },
    },
);

my $client = ArpCLI::Client->new(http => ArpCLI::HTTP->new(
    base_url => $base,
    api_key  => 'k',
    agent    => $mock,
));

my $servers = $client->servers->list;
is(scalar @$servers, 2);

my $server = $client->servers->show($uuid);
is($server->{label}, 'a');

my $bw = $client->servers->bandwidth($uuid);
is($bw->{total_bytes}, 300);

my $boot = $client->actions->boot($uuid);
is($boot->{data}{status}, 'queued');

throws_ok { $client->servers->show('bad') } 'ArpCLI::Error';
throws_ok { $client->actions->boot('bad') } 'ArpCLI::Error';

my $data = $client->discover;
is(scalar @{ $data->{servers} }, 2);
ok(exists $data->{server_detail}{$uuid});

my $before_brief = scalar @{ $mock->requests };
my $brief = $client->discover(brief => 1);
is(scalar @{ $brief->{servers} }, 2, 'brief discover still lists servers');
is(keys %{ $brief->{server_detail} }, 0, 'brief discover omits server_detail');
for my $req (@{ $mock->requests }[$before_brief .. $#{ $mock->requests }]) {
    unlike($req->{url}, qr{/bandwidth|/billing|/ssh_host_keys},
        'brief discover does not fetch per-server detail');
}
ok((scalar @{ $mock->requests } - $before_brief) < 10, 'brief discover avoids per-server detail calls');

my $servers_raw = $client->servers->list_raw;
is(scalar @{ $servers_raw->{servers} }, 2);
ok($servers_raw->{meta}{pagination}{aggregated});
is($servers_raw->{meta}{pagination}{total_entries}, 2);

my $dns_raw = $client->dns_records->list_raw;
is(scalar @{ $dns_raw->{dns_records} }, 1);
ok($dns_raw->{meta}{pagination}{aggregated});
is($dns_raw->{meta}{pagination}{total_entries}, 1);

done_testing;