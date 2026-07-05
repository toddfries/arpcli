package ArpCLI::OpenAPI::Parser;

use strict;
use warnings;

use YAML::PP ();

sub new {
    my ($class, %args) = @_;
    return bless { yaml => $args{yaml} }, $class;
}

sub parse {
    my ($self) = @_;
    my $doc = YAML::PP->new->load_string($self->{yaml});
    die "openapi: root document must be a mapping\n" unless ref $doc eq 'HASH';

    my @operations;
    my $paths = $doc->{paths} // {};
    for my $path (sort keys %$paths) {
        my $item = $paths->{$path};
        next unless ref $item eq 'HASH';
        for my $http_method (sort keys %$item) {
            next unless $http_method =~ /\A(?:get|post|put|patch|delete)\z/i;
            my $op = $item->{$http_method};
            next unless ref $op eq 'HASH';
            push @operations, {
                path           => $path,
                http_method    => uc $http_method,
                operation_id   => $op->{operationId},
                tags           => $op->{tags} // [],
                summary        => $op->{summary},
                parameters     => $op->{parameters} // [],
            };
        }
    }

    my $schemas = $doc->{components}{schemas} // {};
    my %schema_summaries;
    for my $name (sort keys %$schemas) {
        my $schema = $schemas->{$name};
        next unless ref $schema eq 'HASH';
        $schema_summaries{$name} = {
            required   => $schema->{required} // [],
            properties => [ sort keys %{ $schema->{properties} // {} } ],
            enum       => _schema_enum($schema),
        };
    }

    my $error_types = $schema_summaries{Error}{enum} // [];
    if (!@$error_types) {
        my $etype = $schemas->{Error}{properties}{error}{properties}{type}{enum};
        $error_types = $etype if ref $etype eq 'ARRAY';
    }

    my $servers = $doc->{servers} // [];
    my $base_url = (ref $servers->[0] eq 'HASH') ? ($servers->[0]{url} // '') : '';

    return {
        title        => $doc->{info}{title} // 'Platform API',
        version      => $doc->{info}{version} // '0',
        description  => $doc->{info}{description} // '',
        base_url     => $base_url,
        operations   => \@operations,
        schemas      => \%schema_summaries,
        error_types  => $error_types,
    };
}

sub _schema_enum {
    my ($schema) = @_;
    return $schema->{enum} if ref $schema->{enum} eq 'ARRAY';
    return [];
}

1;