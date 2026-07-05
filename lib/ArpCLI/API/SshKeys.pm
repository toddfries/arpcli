package ArpCLI::API::SshKeys;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

sub list {
    my ($self) = @_;
    my $res = $self->http->get('/api/v1/ssh_keys');
    my $items = $res->{data}{ssh_keys};
    return (ref $items eq 'ARRAY') ? $items : [];
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