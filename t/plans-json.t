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
        "GET $base/api/v1/plans" => {
            status  => 200,
            content => JSON::PP->new->encode({
                plans => [
                    { id => 1, code => 'vps_small', name => 'VPS - Small', specs => [], prices => {} },
                    { id => 7, code => 'thunder_starter', name => 'ARP Thunder', specs => [], prices => {} },
                ],
            }),
        },
    },
);

my $client = ArpCLI::Client->new(http => ArpCLI::HTTP->new(
    base_url => $base,
    api_key  => 'k',
    agent    => $mock,
));

my $data = $client->plans->list_raw;
is(scalar @{ $data->{plans} }, 2);

my @thunder = grep { (($_->{code} // '') =~ /\Athunder_/i) } @{ $data->{plans} };
is(scalar @thunder, 1);
is($thunder[0]{code}, 'thunder_starter');

my $json = JSON::PP->new->pretty->canonical->encode({ plans => \@thunder });
like($json, qr/"code"\s*:\s*"thunder_starter"/);

done_testing;