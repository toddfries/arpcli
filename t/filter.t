use strict;
use warnings;

use Test::More;
use lib 'lib';

use ArpCLI::CLI::Filter;

my @servers = (
    { label => 'web', state => 'running', plan => 'VPS', os_template => 'openbsd-7.6-amd64' },
    { label => 'db',  state => 'stopped', plan => 'VPS', os_template => 'debian-13-amd64' },
);

my $running = ArpCLI::CLI::Filter::filter_servers(\@servers, state => 'running');
is(scalar @$running, 1);
is($running->[0]{label}, 'web');

my $bsd = ArpCLI::CLI::Filter::filter_servers(\@servers, re => qr/openbsd/);
is(scalar @$bsd, 1);
is($bsd->[0]{label}, 'web');

my $both = ArpCLI::CLI::Filter::filter_servers(\@servers, state => 'running', re => qr/openbsd/);
is(scalar @$both, 1);

my @isos = qw(openbsd-amd64-install70.iso debian.iso);
my $iso = ArpCLI::CLI::Filter::filter_isos(\@isos, qr/openbsd/);
is(scalar @$iso, 1);
is($iso->[0], 'openbsd-amd64-install70.iso');

my $templates = [
    { code => 'openbsd-7.6-amd64', family => 'openbsd', version => '7.6', title => 'OpenBSD' },
    { code => 'debian-13-amd64',   family => 'debian',  version => '13',  title => 'Debian' },
];
my $tmpl = ArpCLI::CLI::Filter::filter_os_templates($templates, qr/openbsd/);
is(scalar @$tmpl, 1);
is($tmpl->[0]{code}, 'openbsd-7.6-amd64');

my $raw = ArpCLI::CLI::Filter::filter_servers_raw({
    servers => \@servers,
    meta    => { pagination => { total_entries => 2 } },
}, state => 'running');
is(scalar @{ $raw->{servers} }, 1);
is($raw->{meta}{pagination}{total_entries}, 1);

done_testing;