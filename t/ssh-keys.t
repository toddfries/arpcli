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
my $pub  = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1dWlq8j1RWFHOF0GzqHE/pMQfRBGKcLmM+6Kl5RVbC user@host';
my $mock = Test::MockHTTP->new(
    responses => {
        "POST $base/api/v1/ssh_keys" => {
            status  => 201,
            content => JSON::PP->new->encode({
                ssh_key => {
                    id                   => 42,
                    name                 => 'Laptop',
                    key                  => $pub,
                    username             => 'deploy',
                    key_type             => 'ssh-ed25519',
                    fingerprint_sha256   => 'SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s',
                    created_at           => '2025-03-14T18:22:41Z',
                },
            }),
        },
        "DELETE $base/api/v1/ssh_keys/42" => {
            status  => 204,
            content => '',
        },
    },
);

my $client = ArpCLI::Client->new(http => ArpCLI::HTTP->new(
    base_url => $base,
    api_key  => 'k',
    agent    => $mock,
));

my $key = $client->ssh_keys->create({
    name     => 'Laptop',
    username => 'deploy',
    key      => $pub,
});
is($key->{id}, 42);
is($key->{name}, 'Laptop');
is($key->{username}, 'deploy');

my $req = $mock->requests->[-1];
is($req->{method}, 'POST');
like($req->{content}, qr/"name"\s*:\s*"Laptop"/);
like($req->{content}, qr/"username"\s*:\s*"deploy"/);
like($req->{content}, qr/"key"\s*:\s*"ssh-ed25519 /);

my $del = $client->ssh_keys->delete(42);
is($del->{status}, 204);
ok(!defined $del->{data});
is($mock->requests->[-1]{method}, 'DELETE');

done_testing;