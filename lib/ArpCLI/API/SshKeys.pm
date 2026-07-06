package ArpCLI::API::SshKeys;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

sub list {
    my ($self) = @_;
    my $data = $self->list_raw;
    my $items = $data->{ssh_keys};
    return (ref $items eq 'ARRAY') ? $items : [];
}

sub list_raw {
    my ($self) = @_;
    return $self->_get_data('get', '/api/v1/ssh_keys');
}

sub create {
    my ($self, $ssh_key) = @_;
    my $res = $self->http->post('/api/v1/ssh_keys', body => { ssh_key => $ssh_key });
    return $res->{data}{ssh_key};
}

sub delete {
    my ($self, $id) = @_;
    return $self->http->delete("/api/v1/ssh_keys/$id");
}

1;