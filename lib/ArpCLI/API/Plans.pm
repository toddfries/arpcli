package ArpCLI::API::Plans;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

sub list {
    my ($self) = @_;
    my $res = $self->http->get('/api/v1/plans');
    my $items = $res->{data}{plans};
    return (ref $items eq 'ARRAY') ? $items : [];
}

1;