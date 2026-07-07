use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';

use JSON::PP;
use ArpCLI::Client;
use ArpCLI::HTTP;
use Test::MockHTTP;

my $base = 'https://example.test';
my $mock = Test::MockHTTP->new(
    responses => {
        "POST $base/api/v1/dns_records" => {
            status  => 201,
            content => JSON::PP->new->encode({
                dns_record => {
                    id       => 99,
                    name     => '2.0.0.10.in-addr.arpa',
                    content  => 'server.example.com.',
                    domain   => '0.0.10.in-addr.arpa',
                    type     => 'PTR',
                },
            }),
        },
        "PATCH $base/api/v1/dns_records/42" => {
            status  => 200,
            content => JSON::PP->new->encode({
                dns_record => {
                    id       => 42,
                    name     => '2.0.0.10.in-addr.arpa',
                    content  => 'renamed.example.com.',
                    domain   => '0.0.10.in-addr.arpa',
                    type     => 'PTR',
                },
            }),
        },
        "DELETE $base/api/v1/dns_records/42" => {
            status  => 204,
            content => '',
        },
    },
);

my $client = ArpCLI::Client->new(http => ArpCLI::HTTP->new(
    base_url => $base,
    api_key  => 'k',
    agent    => $mock,
));

my $rec = $client->dns_records->create({
    ip_address => '10.0.0.2',
    hostname   => 'server.example.com',
});
is($rec->{id}, 99);
is($rec->{content}, 'server.example.com.');

my $req = $mock->requests->[-1];
is($req->{method}, 'POST');
like($req->{content}, qr/"ip_address"\s*:\s*"10\.0\.0\.2"/);
like($req->{content}, qr/"hostname"\s*:\s*"server\.example\.com"/);

my $updated = $client->dns_records->update(42, { hostname => 'renamed.example.com' });
is($updated->{id}, 42);
is($updated->{content}, 'renamed.example.com.');
$req = $mock->requests->[-1];
is($req->{method}, 'PATCH');
like($req->{content}, qr/"hostname"\s*:\s*"renamed\.example\.com"/);

my $del = $client->dns_records->delete(42);
is($del->{status}, 204);
ok(!defined $del->{data});
is($mock->requests->[-1]{method}, 'DELETE');

done_testing;