package ArpCLI::OpenAPI::Registry;

use strict;
use warnings;

use Cwd qw(abs_path);
use JSON::PP ();

sub endpoints {
    return @{ meta()->{entries} };
}

my $_META;

sub meta {
    return $_META //= _load();
}

sub _load {
    my $path = _registry_path();
    open my $fh, '<', $path or die "openapi: cannot read registry $path: $!\n";
    local $/;
    my $raw = <$fh>;
    close $fh;
    return JSON::PP->new->decode($raw);
}

sub _registry_path {
    my $root = abs_path(__FILE__);
    $root =~ s{/lib/ArpCLI/OpenAPI/Registry\.pm\z}{};
    return "$root/spec/registry.json";
}

1;