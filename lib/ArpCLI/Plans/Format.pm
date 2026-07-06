package ArpCLI::Plans::Format;

use strict;
use warnings;

use ArpCLI::Util qw(format_specs display_width);

sub group {
    my ($plan) = @_;
    my $code = $plan->{code} // '';
    return 'thunder' if $code =~ /\Athunder_/i;
    return 'vps'     if $code =~ /\Avps_/i;
    return 'other';
}

sub group_title {
    my ($group) = @_;
    return {
        vps     => 'VPS',
        thunder => 'ARP Thunder',
        other   => 'Other',
    }->{$group} // 'Other';
}

sub short_name {
    my ($plan) = @_;
    my $name = $plan->{name} // $plan->{code} // '';
    $name =~ s/\AVPS\s*-\s*//i;
    $name =~ s/\AARP\s+Thunder(?:\x{2122}|™)?\s*-\s*//i;
    $name =~ s/^"|"$//g;
    return $name;
}

sub format_prices {
    my ($prices) = @_;
    return '-' unless ref $prices eq 'HASH' && keys %$prices;
    my @bits;
    if (defined $prices->{monthly}) {
        push @bits, sprintf('$%.2f/mo', $prices->{monthly});
    }
    if (defined $prices->{hourly}) {
        push @bits, sprintf('$%.4f/hr', $prices->{hourly});
    }
    return join(' ', @bits);
}

sub grouped {
    my ($plans) = @_;
    my %groups;
    for my $plan (@$plans) {
        push @{ $groups{ group($plan) } }, $plan;
    }
    for my $g (keys %groups) {
        @{ $groups{$g} } = sort { ($a->{id} // 0) <=> ($b->{id} // 0) } @{ $groups{$g} };
    }
    return \%groups;
}

sub print_grouped {
    my ($fh, $plans) = @_;
    $fh //= \*STDOUT;
    my $groups = grouped($plans);
    my @order = grep { exists $groups->{$_} } qw(vps thunder other);
    my $printed;
    for my $group (@order) {
        my $rows = $groups->{$group};
        next unless $rows && @$rows;
        print {$fh} group_title($group), "\n" if @order > 1 || $group ne 'other';
        _print_table($fh, [qw(ID CODE NAME PRICE SPECS)], $rows, sub {
            my ($p) = @_;
            (
                $p->{id},
                $p->{code},
                short_name($p),
                format_prices($p->{prices}),
                format_specs($p->{specs}),
            );
        });
        print {$fh} "\n" if $group ne $order[-1];
        $printed++;
    }
    return $printed // 0;
}

sub _print_table {
    my ($fh, $headers, $rows, $extract) = @_;
    my @data = map { [ $extract->($_) ] } @$rows;
    my @widths;
    for my $i (0 .. $#$headers) {
        my $w = display_width($headers->[$i]);
        for my $row (@data) {
            my $len = display_width($row->[$i] // '');
            $w = $len if $len > $w;
        }
        push @widths, $w;
    }
    print {$fh} join(' ', map { _pad($headers->[$_], $widths[$_]) } 0 .. $#$headers), "\n";
    for my $row (@data) {
        print {$fh} join(' ', map {
            _pad($row->[$_] // '', $widths[$_])
        } 0 .. $#$headers), "\n";
    }
}

sub _pad {
    my ($text, $width) = @_;
    $text //= '';
    my $pad = $width - display_width($text);
    $pad = 0 if $pad < 0;
    return $text . (' ' x $pad);
}

1;