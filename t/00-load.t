use strict;
use warnings;

use Test::More;

use lib 't/lib';
use lib 'lib';

my @modules = qw(
    ArpCLI
    ArpCLI::Error
    ArpCLI::Config
    ArpCLI::HTTP
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
);

plan tests => scalar @modules;

for my $mod (@modules) {
    use_ok($mod);
}

done_testing;