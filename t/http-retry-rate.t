use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';

use ArpCLI::HTTP;
use ArpCLI::RateLimit;
use Test::MockHTTP;

my $base = 'https://example.test';
my $journal = "t/tmp-http-retry-rate-$$.journal";
END { unlink $journal if -e $journal }

my $now = 2_000_000.0;
my @slept;
my @warned;

my $mock = Test::MockHTTP->new(
    sequences => {
        "GET $base/api/v1/retry-429" => [
            {
                status  => 429,
                content => '{"error":{"type":"rate_limited","message":"slow down"}}',
                headers => { 'retry-after' => '5' },
            },
            { status => 200, content => '{"ok":true}' },
        ],
    },
);

my $rl = ArpCLI::RateLimit->new(
    path    => $journal,
    key_id  => 'retrykey',
    clock   => sub { $now },
    sleeper => sub { push @slept, $_[0]; $now += $_[0] },
    warn    => sub { push @warned, $_[0] },
    verbose => 1,
);

my $http = ArpCLI::HTTP->new(
    base_url         => $base,
    api_key          => 'retry-test-key',
    agent            => $mock,
    rate_limit       => $rl,
    max_retries      => 2,
    rate_limit_clock => sub { $now },
    rate_limit_sleeper => sub { push @slept, $_[0]; $now += $_[0] },
    verbose          => 1,
);

my $res = $http->get('/api/v1/retry-429');
is($res->{status}, 200);
ok(@slept >= 1, '429 retry sleeps');
ok(@warned >= 1, 'verbose warns on 429 sleep');

open my $fh, '<', $journal or die $!;
my $text = do { local $/; <$fh> };
close $fh;
like($text, qr/\tretry_after\n/, '429 Retry-After persisted to journal');

done_testing;