package ArpCLI::API::Isos;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

sub list {
    my ($self) = @_;
    my $data = $self->list_raw;
    my $items = $data->{isos};
    return (ref $items eq 'ARRAY') ? $items : [];
}

sub list_raw {
    my ($self) = @_;
    return $self->_get_data('get', '/api/v1/isos');
}

1;