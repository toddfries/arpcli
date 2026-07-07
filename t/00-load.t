use strict;
use warnings;

use Test::More;

use lib 'vendor/lib/perl5', 't/lib', 'lib';

my @modules = qw(
    ArpCLI
    ArpCLI::Error
    ArpCLI::Config
    ArpCLI::HTTP
    ArpCLI::RateLimit
    ArpCLI::Util
    ArpCLI::Client
    ArpCLI::Output
    ArpCLI::API::Base
    ArpCLI::API::Locations
    ArpCLI::API::Isos
    ArpCLI::API::Plans
    ArpCLI::API::OsTemplates
    ArpCLI::API::Servers
    ArpCLI::API::ServerActions
    ArpCLI::API::DnsRecords
    ArpCLI::API::SshKeys
    ArpCLI::OpenAPI::Parser
    ArpCLI::OpenAPI::Map
    ArpCLI::OpenAPI::Manuals
    ArpCLI::OpenAPI::Codegen
    ArpCLI::OpenAPI::Sync
    ArpCLI::OpenAPI::Registry
    ArpCLI::Plans::Format
    ArpCLI::CLI::Args
    ArpCLI::CLI::Format
);

plan tests => scalar @modules;

for my $mod (@modules) {
    use_ok($mod);
}

done_testing;