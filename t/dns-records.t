use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';
use Test::Throws qw(throws_ok);

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

done_testing;