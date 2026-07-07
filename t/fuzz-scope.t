use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';
use JSON::PP;
use ArpCLI::Client;
use ArpCLI::Error;
use ArpCLI::HTTP;
use Test::MockHTTP;

my $base = 'https://example.test';
my $uuid = '52326bc0-79df-012c-d6f1-00163ec95f4c';
my $scope_body = JSON::PP->new->encode({
    error => {
        type    => 'insufficient_scope',
        message => "This API key does not have the 'write' scope",
    },
});
my $range_body = JSON::PP->new->encode({
    error => {
        type    => 'invalid_range',
        message => 'range must be one of: 1h, 6h, 24h, 7d, 30d',
    },
});

my $mock = Test::MockHTTP->new(
    responses => {
        "POST $base/api/v1/dns_records" => { status => 403, content => $scope_body },
        "PATCH $base/api/v1/dns_records/42" => { status => 403, content => $scope_body },
        "DELETE $base/api/v1/dns_records/42" => { status => 403, content => $scope_body },
        "POST $base/api/v1/ssh_keys" => { status => 403, content => $scope_body },
        "DELETE $base/api/v1/ssh_keys/9" => { status => 403, content => $scope_body },
        "DELETE $base/api/v1/servers/$uuid" => { status => 403, content => $scope_body },
        "POST $base/api/v1/servers/$uuid/actions/boot" => { status => 403, content => $scope_body },
        "POST $base/api/v1/servers/$uuid/actions/change_iso" => { status => 403, content => $scope_body },
        "POST $base/api/v1/servers/$uuid/actions/set_parameter" => { status => 403, content => $scope_body },
        "GET $base/api/v1/servers/$uuid/bandwidth?range=notvalid" => { status => 422, content => $range_body },
    },
);

my $client = ArpCLI::Client->new(http => ArpCLI::HTTP->new(
    base_url => $base,
    api_key  => 'k',
    agent    => $mock,
));

sub assert_scope_error {
    my ($label, $code) = @_;
    eval { $code->() };
    my $err = $@;
    ok(ref $err eq 'ArpCLI::Error', "$label throws ArpCLI::Error");
    is($err->type, 'insufficient_scope', "$label error type");
    is($err->status, 403, "$label error status");
    like($err->message, qr/write/i, "$label message mentions write scope");
}

my @write_cases = (
    [ 'dns_records create', sub {
        $client->dns_records->create({ ip_address => '10.0.0.2', hostname => 'h.example.com' });
    } ],
    [ 'dns_records update', sub { $client->dns_records->update(42, { hostname => 'h.example.com' }) } ],
    [ 'dns_records delete', sub { $client->dns_records->delete(42) } ],
    [ 'ssh_keys create', sub {
        $client->ssh_keys->create({ name => 'k', username => 'deploy', key => 'ssh-ed25519 AAAA' });
    } ],
    [ 'ssh_keys delete', sub { $client->ssh_keys->delete(9) } ],
    [ 'servers delete', sub { $client->servers->delete($uuid) } ],
    [ 'actions boot', sub { $client->actions->boot($uuid) } ],
    [ 'actions change_iso', sub { $client->actions->change_iso($uuid, 'openbsd.iso') } ],
    [ 'actions set_parameter', sub {
        $client->actions->set_parameter($uuid, 'boot-menu', 'on');
    } ],
);

for my $case (@write_cases) {
    assert_scope_error($case->[0], $case->[1]);
}

eval { $client->servers->bandwidth($uuid, range => 'notvalid') };
my $err = $@;
ok(ref $err eq 'ArpCLI::Error', 'invalid bandwidth range throws');
is($err->type, 'invalid_range', 'invalid_range error type');
like($err->message, qr/1h.*30d/, 'invalid_range message lists allowed values');

done_testing;