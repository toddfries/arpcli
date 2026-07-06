use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';
use Test::Throws qw(throws_ok);

use ArpCLI::Client;
use ArpCLI::Error;

unless ($ENV{ARPCLI_LIVE}) {
    plan skip_all => 'set ARPCLI_LIVE=1 to run live API fuzz tests';
}

my $client = ArpCLI::Client->new();
my $uuid = eval {
    my $list = $client->servers->list_raw;
    $list->{servers}[0]{uuid};
};
if ($@ || !$uuid) {
    plan skip_all => 'live fuzz needs at least one server';
}

plan tests => 11;

sub assert_live_scope {
    my ($label, $code) = @_;
    eval { $code->() };
    my $err = $@;
    ok(ref $err eq 'ArpCLI::Error', "$label throws ArpCLI::Error");
    is($err->type, 'insufficient_scope', "$label type is insufficient_scope");
    is($err->status, 403, "$label status is 403");
}

assert_live_scope('dns_records create', sub {
    $client->dns_records->create({
        ip_address => '127.0.0.1',
        hostname   => 'fuzz-regress.example.com',
    });
});

assert_live_scope('servers boot', sub {
    $client->actions->boot($uuid);
});

assert_live_scope('servers delete', sub {
    $client->servers->delete($uuid);
});

eval { $client->servers->bandwidth($uuid, range => 'notvalid') };
my $range_err = $@;
ok(ref $range_err eq 'ArpCLI::Error', 'invalid bandwidth range throws');
is($range_err->type, 'invalid_range', 'invalid_range type from live API');

done_testing;