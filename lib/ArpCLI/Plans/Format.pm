package ArpCLI::Plans::Format;

use strict;
use warnings;

use ArpCLI::Util qw(display_width);

use constant THUNDER_DISK_NOTE =>
    '# Disk: primary Storage + Storage (SATA) bulk capacity (API names; not detailed in OpenAPI)';

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
    $name =~ s/\s+Plan\z//i;
    return $name;
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
        print {$fh} group_title($group), "\n";
        print {$fh} THUNDER_DISK_NOTE, "\n" if $group eq 'thunder';
        _print_plans_table($fh, $rows, $group);
        print {$fh} "\n" if $group ne $order[-1];
        $printed++;
    }
    return $printed // 0;
}

sub row_values {
    my ($plan, $group) = @_;
    my %spec = map { $_->{name} => $_ } @{ $plan->{specs} // [] };
    my $prices = $plan->{prices} // {};

    return [
        _id_cell($plan->{id}),
        $plan->{code},
        short_name($plan),
        _monthly_price_cell($prices->{monthly}),
        _hourly_price_cell($prices->{hourly}),
        _disk_cell(\%spec, $group),
        _spec_cell($spec{RAM}),
        _spec_cell($spec{CPU}),
    ];
}

sub _id_cell {
    my ($id) = @_;
    return defined $id ? sprintf('%3d', 0 + $id) : '  -';
}

sub _monthly_price_cell {
    my ($amount) = @_;
    return sprintf('%6s', '-') unless defined $amount;
    return sprintf('%6.2f', $amount + 0);
}

sub _hourly_price_cell {
    my ($amount) = @_;
    return sprintf('%6s', '-') unless defined $amount;
    return sprintf('%6.5f', $amount + 0);
}

sub _spec_cell {
    my ($spec) = @_;
    return '-' unless $spec;
    my $q = $spec->{quantity};
    $q = int($q) if defined $q && $q == int($q);
    return defined $q ? "$q" : '-';
}

sub _disk_cell {
    my ($spec, $group) = @_;
    if ($group eq 'thunder') {
        my $primary = _spec_cell($spec->{Storage});
        my $sata    = _spec_cell($spec->{'Storage (SATA)'});
        return $primary eq '-' ? $sata : ($sata eq '-' ? $primary : "$primary+$sata");
    }
    return _spec_cell($spec->{Storage});
}

sub _print_plans_table {
    my ($fh, $plans, $group) = @_;
    my @rows = map { row_values($_, $group) } @$plans;
    my @widths = _column_widths(\@rows);
    _print_header_row($fh, \@widths);
    for my $row (@rows) {
        _print_data_row($fh, $row, \@widths);
    }
    return;
}

sub _column_widths {
    my ($rows) = @_;
    my @headers = (
        [ 'ID', 'CODE', 'PLAN NAME', 'monthly', 'hourly', 'Disk', 'RAM', 'CPU' ],
        [ '',   '',     '',          'monthly', 'hourly', 'Disk', 'RAM', 'CPU' ],
    );
    my @widths = (3, 4, 9, 6, 7, 4, 3, 3);
    for my $i (0 .. 7) {
        my $w = display_width($headers[0][$i]);
        $w = display_width($headers[1][$i]) if $w < display_width($headers[1][$i]);
        for my $row (@$rows) {
            my $len = display_width($row->[$i] // '');
            $w = $len if $len > $w;
        }
        $widths[$i] = $w;
    }
    return @widths;
}

sub _print_header_row {
    my ($fh, $widths) = @_;
    my $price_span = $widths->[3] + 1 + $widths->[4];
    my $spec_span  = $widths->[5] + 1 + $widths->[6] + 1 + $widths->[7];

    my $line1 = join(' ',
        _lpad('ID', $widths->[0]),
        _pad('CODE', $widths->[1]),
        _pad('PLAN NAME', $widths->[2]),
        _pad('Price', $price_span),
        _pad('Specs', $spec_span),
    );
    my $line2 = join(' ',
        _lpad('', $widths->[0]),
        _pad('', $widths->[1]),
        _pad('', $widths->[2]),
        _rpad('monthly', $widths->[3]),
        _rpad('hourly', $widths->[4]),
        _pad('Disk', $widths->[5]),
        _rpad('RAM', $widths->[6]),
        _pad('CPU', $widths->[7]),
    );
    print {$fh} $line1, "\n", $line2, "\n";
    return;
}

sub _print_data_row {
    my ($fh, $row, $widths) = @_;
    my @align = qw(lpad pad pad rpad rpad pad rpad pad);
    print {$fh} join(' ', map {
        _align_cell($row->[$_] // '', $widths->[$_], $align[$_])
    } 0 .. 7), "\n";
    return;
}

sub _align_cell {
    my ($text, $width, $align) = @_;
    return _rpad($text, $width) if $align eq 'rpad';
    return _lpad($text, $width) if $align eq 'lpad';
    return _pad($text, $width);
}

sub _pad {
    my ($text, $width) = @_;
    $text //= '';
    my $pad = $width - display_width($text);
    $pad = 0 if $pad < 0;
    return $text . (' ' x $pad);
}

sub _rpad {
    my ($text, $width) = @_;
    $text //= '';
    my $pad = $width - display_width($text);
    $pad = 0 if $pad < 0;
    return (' ' x $pad) . $text;
}

sub _lpad {
    my ($text, $width) = @_;
    return _rpad($text, $width);
}

1;