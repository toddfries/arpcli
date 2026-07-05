package ArpCLI::OpenAPI::Codegen;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use JSON::PP ();

sub write_registry {
    my ($class, %args) = @_;
    my $map     = $args{map};
    my $parsed  = $args{parsed};
    my $path    = $args{path} // 'spec/registry.json';
    my @entries;
    for my $id (sort keys %$map) {
        my $row = $map->{$id};
        next unless $row->{path} && $row->{http_method};
        push @entries, {
            operation_id => $id,
            http_method  => $row->{http_method},
            path         => $row->{path},
            module       => $row->{module},
            method       => $row->{method},
            scope        => $row->{scope},
            cli          => $row->{cli},
            summary      => $row->{summary},
        };
    }

    make_path(dirname($path));
    open my $fh, '>', $path or die "openapi: cannot write $path: $!\n";
    print {$fh} JSON::PP->new->pretty->canonical->encode({
        version  => $parsed->{version},
        title    => $parsed->{title},
        base_url => $parsed->{base_url},
        entries  => \@entries,
    });
    close $fh;
    return $path;
}

sub write_manifest {
    my ($class, %args) = @_;
    my $map  = $args{map};
    my $path = $args{path} // 'spec/endpoint-manifest.json';
    my @rows;
    for my $id (sort keys %$map) {
        my $row = $map->{$id};
        next unless $row->{path};
        push @rows, {
            operation_id => $id,
            %{ $row },
        };
    }
    open my $fh, '>', $path or die "openapi: cannot write $path: $!\n";
    print {$fh} JSON::PP->new->pretty->canonical->encode(\@rows);
    close $fh;
    return $path;
}

sub coverage_report {
    my ($class, %args) = @_;
    my $map      = $args{map};
    my $lib_root = $args{lib_root} // 'lib/ArpCLI/API';
    my @missing_api;
    my @missing_cli;
    for my $id (sort keys %$map) {
        my $row = $map->{$id};
        next unless $row->{path};
        my $module = $row->{module} // 'UNKNOWN';
        my $method = $row->{method} // 'unknown';
        if ($module eq 'UNKNOWN') {
            push @missing_api, "$id ($row->{http_method} $row->{path})";
            next;
        }
        my $pm = "$lib_root/$module.pm";
        unless (-e $pm && _has_method($pm, $method)) {
            push @missing_api, "$module->$method for $id";
        }
        if (defined $row->{cli} && $row->{cli} eq 'null') {
            $row->{cli} = undef;
        }
        if ($row->{scope} && $row->{scope} ne 'read' && !$row->{cli}) {
            push @missing_cli, "$id ($row->{http_method} $row->{path})";
        }
    }
    return {
        missing_api => \@missing_api,
        missing_cli => \@missing_cli,
    };
}

sub _has_method {
    my ($path, $method) = @_;
    open my $fh, '<', $path or return 0;
    my $re = qr/^\s*sub\s+\Q$method\E\b/;
    while (my $line = <$fh>) {
        return 1 if $line =~ $re;
    }
    return 0;
}

1;