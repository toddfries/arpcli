use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';

use ArpCLI::HTTP;
use ArpCLI::RateLimit;
use Test::MockHTTP;

my $base = 'https://example.test';
my $journal = "t/tmp-rate-limit-$$.journal";
END { unlink $journal if -e $journal }

my $mock = Test::MockHTTP->new(
    responses => {
        "GET $base/api/v1/ping" => {
            status  => 200,
            content => '{"ok":true}',
        },
        "POST $base/api/v1/servers" => {
            status  => 201,
            content => '{"server":{"uuid":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"}}',
        },
    },
);

my $t0   = 1_000_000.0;
my $now  = $t0;
my @slept;
my @warned;

my $rl = ArpCLI::RateLimit->new(
    path    => $journal,
    key_id  => 'testkey',
    clock   => sub { $now },
    sleeper => sub { push @slept, $_[0]; $now += $_[0] },
    warn    => sub { push @warned, $_[0] },
);

is_deeply($rl->limits, {
    key            => 54,
    ip             => 108,
    server_create  => 6,
    window_sec     => 60,
}, 'documented limits with margin');

for (1 .. 54) {
    $rl->acquire('GET', '/api/v1/ping');
}
is($rl->counts->{key_remaining}, 0, 'key bucket full at margin');

@slept  = ();
@warned = ();
$rl->acquire('GET', '/api/v1/ping');
ok(@slept >= 1, 'waits when key bucket is full');
ok(@warned >= 1, 'warns when throttling');

$now = $t0 + 61;
@slept  = ();
@warned = ();
$rl->acquire('GET', '/api/v1/ping');
is(scalar @slept, 0, 'no wait after window rolls forward');

my $rl_create = ArpCLI::RateLimit->new(
    path    => $journal,
    key_id  => 'createkey',
    clock   => sub { $now },
    sleeper => sub { push @slept, $_[0]; $now += $_[0] },
    warn    => sub { },
);

for (1 .. 6) {
    $rl_create->acquire('POST', '/api/v1/servers');
}
is($rl_create->counts->{create_remaining}, 0, 'server create bucket at margin');

$now += 61;
my $http = ArpCLI::HTTP->new(
    base_url         => $base,
    api_key          => 'integration-key',
    agent            => $mock,
    rate_limit       => $rl,
    rate_limit_path  => $journal,
    rate_limit_clock => sub { $now },
    rate_limit_sleeper => sub { $now += $_[0] },
);

$http->get('/api/v1/ping');
is(scalar @{ $mock->requests }, 1, 'HTTP calls acquire before request');

open my $fh, '<', $journal or die $!;
my $text = do { local $/; <$fh> };
close $fh;
like($text, qr/\A# arpcli-usage-v1/, 'journal has version header');
like($text, qr/\t(?:general|server_create)\n\z/m, 'journal lines are tab-separated');

done_testing;