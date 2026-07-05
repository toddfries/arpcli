package ArpCLI::API::Servers;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

use ArpCLI::Util qw(is_uuid);

sub list {
    my ($self) = @_;
    return $self->_paginate('/api/v1/servers', 'servers');
}

sub show {
    my ($self, $uuid) = @_;
    $self->_require_uuid($uuid);
    my $res = $self->http->get("/api/v1/servers/$uuid");
    return $res->{data}{server};
}

sub create {
    my ($self, $server) = @_;
    my $res = $self->http->post('/api/v1/servers', body => { server => $server });
    return $res->{data}{server};
}

sub delete {
    my ($self, $uuid) = @_;
    $self->_require_uuid($uuid);
    return $self->http->delete("/api/v1/servers/$uuid");
}

sub bandwidth {
    my ($self, $uuid, %args) = @_;
    $self->_require_uuid($uuid);
    my $query = {};
    $query->{range} = $args{range} if defined $args{range};
    my $res = $self->http->get("/api/v1/servers/$uuid/bandwidth", query => $query);
    return $res->{data}{bandwidth};
}

sub billing {
    my ($self, $uuid) = @_;
    $self->_require_uuid($uuid);
    my $res = $self->http->get("/api/v1/servers/$uuid/billing");
    return $res->{data}{billing};
}

sub ssh_host_keys {
    my ($self, $uuid) = @_;
    $self->_require_uuid($uuid);
    my $res = $self->http->get("/api/v1/servers/$uuid/ssh_host_keys");
    my $items = $res->{data}{ssh_host_keys};
    return (ref $items eq 'ARRAY') ? $items : [];
}

sub _require_uuid {
    my ($self, $uuid) = @_;
    require ArpCLI::Error;
    die ArpCLI::Error->new(
        type    => 'invalid_uuid',
        message => 'server uuid is required and must be valid',
    ) unless is_uuid($uuid);
    return;
}

1;