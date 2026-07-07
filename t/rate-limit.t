use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';

use ArpCLI::HTTP;
use ArpCLI::RateLimit;
use Test::MockHTTP;

my $base = 'https://example.test';
my $journal      = "t/tmp-rate-limit-$$.journal";
my $retry_journal = "t/tmp-rate-retry-$$.journal";
END {
    unlink $journal if -e $journal;
    unlink $retry_journal if -e $retry_journal;
}

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
    verbose => 1,
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
ok(@warned >= 1, 'verbose warns when throttling');
like($warned[-1], qr/sleeping \d+s/, 'warn mentions sleep seconds');

$now = $t0 + 61;
@slept  = ();
@warned = ();
$rl->acquire('GET', '/api/v1/ping');
is(scalar @slept, 0, 'no wait after window rolls forward');

my $quiet = ArpCLI::RateLimit->new(
    path    => $journal,
    key_id  => 'quietkey',
    clock   => sub { $now },
    sleeper => sub { push @slept, $_[0]; $now += $_[0] },
    warn    => sub { push @warned, $_[0] },
    verbose => 0,
);
for (1 .. 54) {
    $quiet->acquire('GET', '/api/v1/ping');
}
@slept  = ();
@warned = ();
$quiet->acquire('GET', '/api/v1/ping');
ok(@slept >= 1, 'silent mode still waits');
is(scalar @warned, 0, 'silent mode does not warn');

my $rl_create = ArpCLI::RateLimit->new(
    path    => $journal,
    key_id  => 'createkey',
    clock   => sub { $now },
    sleeper => sub { push @slept, $_[0] },
    warn    => sub { },
    verbose => 0,
);

for (1 .. 6) {
    $rl_create->acquire('POST', '/api/v1/servers');
}
is($rl_create->counts->{create_remaining}, 0, 'server create bucket at margin');

$now = 3_000_000.0;
my $retry = ArpCLI::RateLimit->new(
    path    => $retry_journal,
    key_id  => 'retrykey',
    clock   => sub { $now },
    sleeper => sub { push @slept, $_[0]; $now += $_[0] },
    warn    => sub { },
    verbose => 0,
);
$retry->record_retry_after(30);
is($retry->counts->{retry_after_until}, $now + 30, 'retry_after deadline recorded');

open my $fh, '<', $retry_journal or die $!;
my $text = do { local $/; <$fh> };
close $fh;
like($text, qr/\tretry_after\n/, 'journal stores retry_after line');

$now = 3_000_000.0;
@slept = ();
my $reload = ArpCLI::RateLimit->new(
    path    => $retry_journal,
    key_id  => 'retrykey',
    clock   => sub { $now },
    sleeper => sub { push @slept, $_[0]; $now += $_[0] },
    warn    => sub { },
    verbose => 0,
);
$reload->acquire('GET', '/api/v1/ping');
ok(@slept >= 1, 'new run honors persisted retry_after before request');

$now = 3_000_100.0;
@slept = ();
$reload = ArpCLI::RateLimit->new(
    path    => $retry_journal,
    key_id  => 'retrykey',
    clock   => sub { $now },
    sleeper => sub { push @slept, $_[0] },
    warn    => sub { },
    verbose => 0,
);
$reload->acquire('GET', '/api/v1/ping');
is(scalar @slept, 0, 'expired retry_after no longer blocks');

$now = 4_000_000.0;
my $http = ArpCLI::HTTP->new(
    base_url           => $base,
    api_key            => 'integration-key',
    agent              => $mock,
    rate_limit         => $rl,
    rate_limit_path    => $journal,
    rate_limit_clock   => sub { $now },
    rate_limit_sleeper => sub { $now += $_[0] },
);

$http->get('/api/v1/ping');
is(scalar @{ $mock->requests }, 1, 'HTTP calls acquire before request');

$text = do { open $fh, '<', $journal; local $/; <$fh> };
like($text, qr/\A# arpcli-usage-v1/, 'journal has version header');
like($text, qr/\t(?:general|server_create|retry_after)\n/, 'journal lines are tab-separated');

done_testing;