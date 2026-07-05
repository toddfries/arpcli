package ArpCLI::OpenAPI::Sync;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use HTTP::Tiny ();

use ArpCLI::OpenAPI::Parser;
use ArpCLI::OpenAPI::Map;
use ArpCLI::OpenAPI::Manuals;
use ArpCLI::OpenAPI::Codegen;

use constant DEFAULT_URL  => 'https://phoenix.arpnetworks.com/api/docs.yaml';
use constant SPEC_PATH    => 'spec/openapi.yaml';
use constant SHA_PATH     => 'spec/openapi.sha256';

sub new {
    my ($class, %args) = @_;
    return bless {
        url      => $args{url} // DEFAULT_URL,
        root     => $args{root} // '.',
        dry_run  => $args{dry_run} // 0,
        force    => $args{force} // 0,
        agent    => $args{agent},
        yaml     => $args{yaml},
    }, $class;
}

sub run {
    my ($self) = @_;
    my $yaml = $self->_fetch_yaml;
    my $digest = sha256_hex($yaml);

    my $spec_path = $self->_path(SPEC_PATH);
    my $sha_path  = $self->_path(SHA_PATH);
    my $old_digest = _read_text($sha_path);

    if (!$self->{force} && defined $old_digest && $old_digest eq $digest) {
        return {
            changed => 0,
            digest  => $digest,
            message => 'OpenAPI spec unchanged',
        };
    }

    my $parsed = ArpCLI::OpenAPI::Parser->new(yaml => $yaml)->parse;
    my $map_path = $self->_path('spec/endpoint-map.yaml');
    my $cur_map  = ArpCLI::OpenAPI::Map->load($map_path);
    my ($map, $unknown) = ArpCLI::OpenAPI::Map->merge_operations(
        $parsed->{operations},
        $cur_map,
    );

    my $manuals = ArpCLI::OpenAPI::Manuals->new(
        root   => $self->_path('manuals'),
        parsed => $parsed,
        map    => $map,
    );
    my $coverage = ArpCLI::OpenAPI::Codegen->coverage_report(
        map      => $map,
        lib_root => $self->_path('lib/ArpCLI/API'),
    );

    if ($self->{dry_run}) {
        return {
            changed       => 1,
            digest        => $digest,
            old_digest    => $old_digest,
            unknown_ops   => $unknown,
            coverage      => $coverage,
            message       => 'dry-run: spec changed, no files written',
        };
    }

    make_path(dirname($spec_path));
    _write_text($spec_path, $yaml);
    _write_text($sha_path, $digest);
    ArpCLI::OpenAPI::Map->save($map, $map_path);

    my $written = $manuals->write_all();
    push @$written, ArpCLI::OpenAPI::Codegen->write_registry(
        map    => $map,
        parsed => $parsed,
        path   => $self->_path('spec/registry.json'),
    );
    push @$written, ArpCLI::OpenAPI::Codegen->write_manifest(
        map  => $map,
        path => $self->_path('spec/endpoint-manifest.json'),
    );

    return {
        changed     => 1,
        digest      => $digest,
        old_digest  => $old_digest,
        unknown_ops => $unknown,
        coverage    => $coverage,
        written     => $written,
        message     => 'OpenAPI spec updated',
    };
}

sub _fetch_yaml {
    my ($self) = @_;
    return $self->{yaml} if defined $self->{yaml};
    my $agent = $self->{agent} // HTTP::Tiny->new(agent => 'arpcli-sync/0.001', verify_SSL => 1);
    my $res = $agent->get($self->{url});
    die "openapi: fetch failed: HTTP $res->{status}\n" unless $res->{success};
    my $yaml = $res->{content} // '';
    die "openapi: empty response from $self->{url}\n" unless length $yaml;
    $yaml =~ s/\r\n/\n/g;
    return $yaml;
}

sub _path {
    my ($self, $rel) = @_;
    return $rel if $self->{root} eq '.';
    return "$self->{root}/$rel";
}

sub _read_text {
    my ($path) = @_;
    return undef unless defined $path && -e $path;
    open my $fh, '<', $path or die "openapi: cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh;
    $text =~ s/\s+\z//;
    return $text;
}

sub _write_text {
    my ($path, $text) = @_;
    make_path(dirname($path));
    open my $fh, '>', $path or die "openapi: cannot write $path: $!\n";
    print {$fh} $text;
    close $fh;
    return;
}

1;