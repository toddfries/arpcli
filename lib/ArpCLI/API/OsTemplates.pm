package ArpCLI::API::OsTemplates;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

sub list {
    my ($self) = @_;
    my $data = $self->list_raw;
    return $data->{os_templates} // {};
}

sub list_raw {
    my ($self) = @_;
    return $self->_get_data('get', '/api/v1/os_templates');
}

1;