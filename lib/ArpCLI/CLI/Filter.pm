package ArpCLI::CLI::Filter;

use strict;
use warnings;

use ArpCLI::Util qw(flatten_os_templates);

sub filter_servers {
    my ($servers, %opts) = @_;
    $servers = [] unless ref $servers eq 'ARRAY';
    my @out = @$servers;

    if (defined $opts{state} && length $opts{state}) {
        my $want = lc $opts{state};
        @out = grep { lc($_->{state} // '') eq $want } @out;
    }

    if ($opts{re}) {
        my $re = $opts{re};
        @out = grep { _server_matches_re($_, $re) } @out;
    }

    return \@out;
}

sub filter_servers_raw {
    my ($raw, %opts) = @_;
    return $raw unless $opts{state} || $opts{re};
    my $servers = filter_servers($raw->{servers}, %opts);
    return {
        servers => $servers,
        meta    => {
            pagination => {
                total_entries => scalar @$servers,
                aggregated    => \1,
            },
        },
    };
}

sub filter_isos {
    my ($isos, $re) = @_;
    $isos = [] unless ref $isos eq 'ARRAY';
    return $isos unless $re;
    return [ grep { $_ =~ $re } @$isos ];
}

sub filter_isos_raw {
    my ($raw, $re) = @_;
    return $raw unless $re;
    my $isos = filter_isos($raw->{isos}, $re);
    return { isos => $isos };
}

sub filter_os_templates {
    my ($templates, $re) = @_;
    $templates = [] unless ref $templates eq 'ARRAY';
    return $templates unless $re;
    return [
        grep {
            ($_->{code} // '') =~ $re
                || ($_->{family} // '') =~ $re
                || ($_->{version} // '') =~ $re
                || ($_->{title} // '') =~ $re
        } @$templates
    ];
}

sub filter_os_templates_raw {
    my ($raw, $re) = @_;
    return $raw unless $re;
    my $root = $raw->{os_templates} // {};
    return $raw unless ref $root eq 'HASH';

    my %filtered;
    for my $family (sort keys %$root) {
        my $entry = $root->{$family};
        next unless ref $entry eq 'HASH';
        my $series = $entry->{series};
        next unless ref $series eq 'ARRAY';

        my @kept = grep {
            ($_->{code} // '') =~ $re
                || ($_->{version} // '') =~ $re
                || ($entry->{title} // '') =~ $re
                || $family =~ $re
        } @$series;
        next unless @kept;

        $filtered{$family} = { %$entry, series => \@kept };
    }

    return { os_templates => \%filtered };
}

sub _server_matches_re {
    my ($server, $re) = @_;
    for my $field (qw(label uuid state plan os_template primary_ipv4 primary_ipv6 location)) {
        my $val = $server->{$field};
        return 1 if defined $val && $val =~ $re;
    }
    return 0;
}

1;