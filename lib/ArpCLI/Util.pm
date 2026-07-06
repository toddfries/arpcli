package ArpCLI::Util;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
    trim
    is_uuid
    format_bytes
    format_specs
    flatten_os_templates
    paginate_all
    redact_secrets
    redact_headers
    display_sanitize
    display_width
);

sub trim {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

sub is_uuid {
    my ($s) = @_;
    return 0 unless defined $s && length $s;
    return $s =~ /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i;
}

sub format_bytes {
    my ($bytes) = @_;
    return 'n/a' unless defined $bytes;
    return '0 B' if $bytes == 0;

    my @units = qw(B KB MB GB TB PB);
    my $idx   = 0;
    my $val   = $bytes + 0;
    while ($val >= 1024 && $idx < $#units) {
        $val /= 1024;
        $idx++;
    }
    return sprintf('%.2f %s', $val, $units[$idx]);
}

sub format_specs {
    my ($specs) = @_;
    return '' unless ref $specs eq 'ARRAY' && @$specs;
    return join ', ', map {
        my $q = $_->{quantity};
        $q = int($q) if defined $q && $q == int($q);
        my $u = $_->{unit} // '';
        "$_->{name}=${q}${u}"
    } @$specs;
}

sub flatten_os_templates {
    my ($families) = @_;
    return [] unless ref $families eq 'HASH';
    my @out;
    for my $family (sort keys %$families) {
        my $entry = $families->{$family};
        next unless ref $entry eq 'HASH' && ref $entry->{series} eq 'ARRAY';
        for my $series (@{ $entry->{series} }) {
            push @out, {
                family  => $family,
                title   => $series->{title} // $entry->{title},
                version => $series->{version},
                code    => $series->{code},
            };
        }
    }
    return \@out;
}

sub redact_secrets {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\bBearer\s+\S+/Bearer [REDACTED]/g;
    $text =~ s/\bapi_key\s*=\s*\S+/api_key=[REDACTED]/g;
    $text =~ s/\barp_live_[A-Za-z0-9_]+/arp_live_[REDACTED]/g;
    return $text;
}

sub redact_headers {
    my ($headers) = @_;
    return {} unless ref $headers eq 'HASH';
    my %copy = %$headers;
    $copy{Authorization} = 'Bearer [REDACTED]' if exists $copy{Authorization};
    return \%copy;
}

sub display_sanitize {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\x{2122}/(TM)/g;
    $text =~ s/™/(TM)/g;
    return $text;
}

sub display_width {
    my ($text) = @_;
    return 0 unless defined $text && length $text;
    return length display_sanitize($text);
}

sub paginate_all {
    my ($fetch_page) = @_;
    my @all;
    my $page = 1;
    while (1) {
        my $result = $fetch_page->($page);
        my ($items, $pagination) = @$result{qw(items pagination)};
        push @all, @$items if ref $items eq 'ARRAY';
        last unless ref $pagination eq 'HASH';
        my $next = $pagination->{next_page};
        last unless defined $next;
        $page = $next;
    }
    return \@all;
}

1;