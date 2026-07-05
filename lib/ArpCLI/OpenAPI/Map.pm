package ArpCLI::OpenAPI::Map;

use strict;
use warnings;

use YAML::PP ();

use constant DEFAULT_MAP_PATH => 'spec/endpoint-map.yaml';

sub load {
    my ($class, $path) = @_;
    $path //= DEFAULT_MAP_PATH;
    return {} unless -e $path;
    my $doc = YAML::PP->new->load_file($path);
    return ref $doc eq 'HASH' ? $doc : {};
}

sub save {
    my ($class, $map, $path) = @_;
    $path //= DEFAULT_MAP_PATH;
    open my $fh, '>', $path or die "openapi: cannot write $path: $!\n";
    print {$fh} YAML::PP->new->dump($map);
    close $fh;
    return;
}

sub merge_operations {
    my ($class, $operations, $map) = @_;
    my %merged = %$map;
    my @unknown;
    for my $op (@$operations) {
        my $id = $op->{operation_id} or next;
        if (!$merged{$id}) {
            $merged{$id} = {
                module => _guess_module($op),
                method => _guess_method($id),
                scope  => _guess_scope($op),
                cli    => undef,
            };
            push @unknown, $id;
        }
        $merged{$id}{path}         = $op->{path};
        $merged{$id}{http_method}  = $op->{http_method};
        $merged{$id}{summary}      = $op->{summary};
        $merged{$id}{tags}         = $op->{tags};
    }
    return (\%merged, \@unknown);
}

sub _guess_module {
    my ($op) = @_;
    my $tag = (ref $op->{tags} eq 'ARRAY' && @{ $op->{tags} }) ? $op->{tags}[0] : '';
    my %by_tag = (
        'Locations'    => 'Locations',
        'ISOs'         => 'Isos',
        'Plans'        => 'Plans',
        'OS Templates' => 'OsTemplates',
        'Servers'      => 'Servers',
        'Server Actions' => 'ServerActions',
        'DNS Records'  => 'DnsRecords',
        'SSH Keys'     => 'SshKeys',
        'Bandwidth'    => 'Servers',
        'Billing'      => 'Servers',
        'SSH Host Keys' => 'Servers',
    );
    return $by_tag{$tag} // 'UNKNOWN';
}

sub _guess_method {
    my ($id) = @_;
    $id =~ s/Server$//;
    $id =~ s/^get//i;
    $id =~ s/^list//i;
    $id =~ s/^show//i;
    $id =~ s/^create//i;
    $id =~ s/^update//i;
    $id =~ s/^delete//i;
    $id =~ s/^boot//i && return 'boot';
    my $s = $id;
    $s =~ s/([a-z])([A-Z])/$1_\L$2/g;
    $s =~ s/\A([A-Z])/\L$1/;
    return $s || 'unknown';
}

sub _guess_scope {
    my ($op) = @_;
    return 'read' if uc($op->{http_method}) eq 'GET';
    return 'provision' if ($op->{operation_id} // '') eq 'createServer';
    return 'write';
}

1;