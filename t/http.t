use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';
use Test::Throws qw(throws_ok);

use ArpCLI::HTTP;
use ArpCLI::Error;
use Test::MockHTTP;

my $base = 'https://example.test';
my $mock = Test::MockHTTP->new(
    responses => {
        "GET $base/api/v1/locations" => {
            status  => 200,
            content => '{"locations":[{"code":"LAX"}]}',
        },
        "POST $base/api/v1/servers" => {
            status  => 403,
            content => '{"error":{"type":"insufficient_scope","message":"no write"}}',
        },
        "GET $base/api/v1/broken" => {
            status  => 200,
            content => 'not-json',
        },
    },
);

my $http = ArpCLI::HTTP->new(base_url => $base, api_key => 'k', agent => $mock);
my $res = $http->get('/api/v1/locations');
is($res->{status}, 200);
is_deeply($res->{data}{locations}, [{ code => 'LAX' }]);

throws_ok { $http->post('/api/v1/servers', body => { server => {} }) } 'ArpCLI::Error';
eval { $http->post('/api/v1/servers', body => { server => {} }) };
ok($@);
like($@->message, qr/no write/);

throws_ok { $http->get('/api/v1/broken') } 'ArpCLI::Error';

is(scalar @{ $mock->requests }, 4);
like($mock->requests->[0]{headers}{Authorization}, qr/Bearer k/);

done_testing;