use strict;
use warnings;

use Test::More;
use lib 'vendor/lib/perl5', 'lib';

use ArpCLI::OpenAPI::Codegen;
use ArpCLI::OpenAPI::Map;
use ArpCLI::OpenAPI::Registry ();

my $map = ArpCLI::OpenAPI::Map->load('spec/endpoint-map.yaml');
my $report = ArpCLI::OpenAPI::Codegen->coverage_report(map => $map);

ok(@{ $report->{missing_api} // [] } == 0, 'all mapped API methods exist')
    or diag join("\n", @{ $report->{missing_api} });

my @endpoints = ArpCLI::OpenAPI::Registry->endpoints;
ok(@endpoints >= 1);

my @known_missing_cli = qw(
    createServer
    updateDnsRecord
    deleteDnsRecord
    createSshKey
    deleteSshKey
);
my %expected_missing = map { $_ => 1 } @known_missing_cli;
for my $miss (@{ $report->{missing_cli} // [] }) {
    my ($op) = split / /, $miss;
    ok($expected_missing{$op}, "expected missing CLI: $miss");
}

done_testing;