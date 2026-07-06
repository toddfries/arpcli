use strict;
use warnings;

use Test::More;
use Test::Throws qw(throws_ok);
use lib 't/lib';
use lib 'lib';

use ArpCLI::HTTP;
use ArpCLI::Error;
use Test::MockHTTP;

my $base = 'https://example.test';
my @slept;
my $mock = Test::MockHTTP->new(
    sequences => {
        "GET $base/api/v1/retry-502" => [
            { status => 502, content => '{"error":{"type":"dispatch_failed","message":"busy"}}' },
            { status => 502, content => '{"error":{"type":"dispatch_failed","message":"busy"}}' },
            { status => 200, content => '{"ok":true}', headers => { 'x-request-id' => 'abc' } },
        ],
        "GET $base/api/v1/retry-429" => [
            {
                status  => 429,
                content => '{"error":{"type":"rate_limited","message":"slow down"}}',
                headers => { 'retry-after' => '2' },
            },
            { status => 200, content => '{"ok":true}' },
        ],
        "GET $base/api/v1/retry-fail" => [
            { status => 502, content => '{"error":{"type":"dispatch_failed","message":"busy"}}' },
        ],
    },
);

my $http = ArpCLI::HTTP->new(
    base_url    => $base,
    api_key     => 'k',
    agent       => $mock,
    max_retries => 3,
    retry_base  => 1,
    sleeper     => sub { push @slept, $_[0] },
);

my $res = $http->get('/api/v1/retry-502');
is($res->{status}, 200);
ok($res->{data}{ok});
is($res->{attempts}, 3);
is(scalar @{ $mock->requests }, 3);
is_deeply(\@slept, [1, 2]);

@slept = ();
$res = $http->get('/api/v1/retry-429');
is($res->{status}, 200);
is_deeply(\@slept, [2]);

my $before_fail = scalar @{ $mock->requests };
throws_ok { $http->get('/api/v1/retry-fail') } 'ArpCLI::Error';
is(scalar @{ $mock->requests } - $before_fail, 4);

done_testing;