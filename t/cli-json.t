use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';

use JSON::PP;
use ArpCLI::CLI::Args;
use ArpCLI::CLI::Format;
use ArpCLI::Client;
use ArpCLI::HTTP;
use Test::MockHTTP;

my $base = 'https://example.test';
my $mock = Test::MockHTTP->new(
    responses => {
        "GET $base/api/v1/locations" => {
            status  => 200,
            content => '{"locations":[{"code":"LAX","name":"Los Angeles"}]}',
        },
        "GET $base/api/v1/isos" => {
            status  => 200,
            content => '{"isos":["openbsd.iso"]}',
        },
        "GET $base/api/v1/ssh_keys" => {
            status  => 200,
            content => '{"ssh_keys":[]}',
        },
    },
);

my $client = ArpCLI::Client->new(http => ArpCLI::HTTP->new(
    base_url => $base,
    api_key  => 'k',
    agent    => $mock,
));

is_deeply($client->locations->list_raw, { locations => [{ code => 'LAX', name => 'Los Angeles' }] });
is_deeply($client->isos->list_raw, { isos => ['openbsd.iso'] });

my @args = qw(list --json);
is(ArpCLI::CLI::Args::extract_json(\@args), 1);
is_deeply(\@args, ['list']);

my $buf = '';
{
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    ArpCLI::CLI::Format::print_json({ hello => 'world' });
}
like($buf, qr/"hello"\s*:\s*"world"/);

done_testing;