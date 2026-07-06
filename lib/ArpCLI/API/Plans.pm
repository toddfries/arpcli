package ArpCLI::API::Plans;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

sub list {
    my ($self) = @_;
    my $data = $self->list_raw;
    my $items = $data->{plans};
    return (ref $items eq 'ARRAY') ? $items : [];
}

sub list_raw {
    my ($self) = @_;
    my $res = $self->http->get('/api/v1/plans');
    my $data = $res->{data};
    return ref $data eq 'HASH' ? $data : { plans => [] };
}

1;