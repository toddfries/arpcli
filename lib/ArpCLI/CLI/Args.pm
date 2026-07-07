package ArpCLI::CLI::Args;

use strict;
use warnings;

sub extract_json {
    my ($args) = @_;
    my $json = 0;
    @$args = grep {
        if ($_ eq '--json') { $json = 1; 0 } else { 1 }
    } @$args;
    return $json;
}

sub extract_range {
    my ($args, $default) = @_;
    $default //= '30d';
    my $range = $default;
    while (@$args) {
        my $opt = shift @$args;
        if ($opt eq '--range') {
            die "arpcli: --range requires a value\n" unless @$args;
            $range = shift @$args;
        }
        else {
            unshift @$args, $opt;
            last;
        }
    }
    return $range;
}

sub extract_list_subcommand {
    my ($args, $resource) = @_;
    return 'list' unless @$args;
    return 'list' if $args->[0] =~ /^-/;
    my $sub = shift @$args;
    die "arpcli: unknown $resource subcommand: $sub\n" unless $sub eq 'list';
    return $sub;
}

sub extract_brief {
    my ($args) = @_;
    my $brief = 0;
    @$args = grep {
        if ($_ eq '--brief') { $brief = 1; 0 } else { 1 }
    } @$args;
    return $brief;
}

sub extract_thunder {
    my ($args) = @_;
    my $thunder = 0;
    @$args = grep {
        if ($_ eq '--thunder') { $thunder = 1; 0 } else { 1 }
    } @$args;
    return $thunder;
}

sub ensure_empty {
    my ($args, $context) = @_;
    return unless @$args;
    die "arpcli: unknown $context option: $args->[0]\n";
}

1;