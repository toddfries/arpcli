package ArpCLI::CLI::Format;

use strict;
use warnings;

sub print_json {
    my ($data) = @_;
    require JSON::PP;
    binmode STDOUT, ':encoding(UTF-8)';
    print JSON::PP->new->pretty->canonical->encode($data), "\n";
    return;
}

1;