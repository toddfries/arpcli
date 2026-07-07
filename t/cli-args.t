use strict;
use warnings;

use Test::More;
use lib 'lib';

use ArpCLI::CLI::Args;

sub dies_like {
    my ($label, $code, $pattern) = @_;
    eval { $code->() };
    ok($@, "$label dies");
    like($@, $pattern, "$label message");
}

my @json_args = qw(list --json --json --json);
is(ArpCLI::CLI::Args::extract_json(\@json_args), 1, 'extract_json returns true');
is_deeply(\@json_args, ['list'], 'extract_json strips all --json flags');

my @range_args = qw(--range 7d --json);
is(ArpCLI::CLI::Args::extract_range(\@range_args), '7d');
is_deeply(\@range_args, ['--json'], 'extract_range leaves other flags');

my @default_range = qw();
is(ArpCLI::CLI::Args::extract_range(\@default_range), '30d', 'extract_range default');

my @missing_range = qw(--range);
dies_like('--range without value', sub {
    ArpCLI::CLI::Args::extract_range(\@missing_range);
}, qr/--range requires a value/);

my @thunder = qw(list --thunder --json);
is(ArpCLI::CLI::Args::extract_thunder(\@thunder), 1);
is_deeply(\@thunder, ['list', '--json'], 'extract_thunder strips --thunder only');

my @leftover = qw(foo --bar);
dies_like('ensure_empty unknown option', sub {
    ArpCLI::CLI::Args::ensure_empty(\@leftover, 'test ctx');
}, qr/unknown test ctx option: foo/);

my @ok_empty = qw();
ArpCLI::CLI::Args::ensure_empty(\@ok_empty, 'test ctx');

my @flag_first = qw(--json --thunder);
is(ArpCLI::CLI::Args::extract_list_subcommand(\@flag_first, 'plans'), 'list');
is_deeply(\@flag_first, ['--json', '--thunder'], 'extract_list_subcommand leaves flags');

my @explicit = qw(list --json);
is(ArpCLI::CLI::Args::extract_list_subcommand(\@explicit, 'plans'), 'list');
is_deeply(\@explicit, ['--json']);

my @bad_sub = qw(create);
dies_like('extract_list_subcommand rejects create', sub {
    ArpCLI::CLI::Args::extract_list_subcommand(\@bad_sub, 'plans');
}, qr/unknown plans subcommand/);

done_testing;