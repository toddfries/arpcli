use strict;
use warnings;

use Test::More;
use lib 'vendor/lib/perl5', 't/lib', 'lib';

use File::Temp qw(tempdir);
use File::Copy qw(move);
use ArpCLI::OpenAPI::Parser;
use ArpCLI::OpenAPI::Sync;

my $fixture = do {
    open my $fh, '<', 't/fixtures/openapi-minimal.yaml' or die $!;
    local $/; <$fh>;
};

my $parsed = ArpCLI::OpenAPI::Parser->new(yaml => $fixture)->parse;
is($parsed->{title}, 'Test API');
is($parsed->{version}, '9.9.9');
is($parsed->{base_url}, 'https://example.test');
is(scalar @{ $parsed->{operations} }, 2);
is($parsed->{operations}[0]{operation_id}, 'listWidgets');

my $tmp = tempdir(CLEANUP => 1);
my $sync = ArpCLI::OpenAPI::Sync->new(
    root    => $tmp,
    yaml    => $fixture,
    force   => 1,
);
my $result = $sync->run;
ok($result->{changed});
ok(-e "$tmp/spec/openapi.yaml");
ok(-e "$tmp/manuals/endpoints.md");
ok(-e "$tmp/spec/registry.json");
like(_slurp("$tmp/spec/registry.json"), qr/listWidgets/);

my $sync2 = ArpCLI::OpenAPI::Sync->new(root => $tmp, yaml => $fixture);
my $again = $sync2->run;
ok(!$again->{changed});
is($again->{message}, 'OpenAPI spec unchanged');

done_testing;

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die $!;
    local $/; <$fh>;
}