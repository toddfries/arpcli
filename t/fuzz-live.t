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

plan tests => 4;

my $client = ArpCLI::Client->new();

throws_ok {
    $client->dns_records->create({
        ip_address => '127.0.0.1',
        hostname   => 'fuzz-test.example.com',
    });
} 'ArpCLI::Error', 'dns_records create throws on read-only key';

eval {
    $client->dns_records->create({
        ip_address => '127.0.0.1',
        hostname   => 'fuzz-test.example.com',
    });
};
my $err = $@;
ok(ref $err eq 'ArpCLI::Error', 'create error is ArpCLI::Error');
is($err->type, 'insufficient_scope', 'create error type is insufficient_scope');
is($err->status, 403, 'create error status is 403');

done_testing;