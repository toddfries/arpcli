package ArpCLI::API::Servers;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

use ArpCLI::Util qw(is_uuid);

sub list {
    my ($self) = @_;
    return $self->_paginate('/api/v1/servers', 'servers');
}

sub list_raw {
    my ($self) = @_;
    my $servers = $self->list;
    return {
        servers => $servers,
        meta    => {
            pagination => {
                total_entries => scalar @$servers,
                aggregated    => \1,
            },
        },
    };
}

sub show {
    my ($self, $uuid) = @_;
    $self->_require_uuid($uuid);
    return $self->show_raw($uuid)->{server};
}

sub show_raw {
    my ($self, $uuid) = @_;
    $self->_require_uuid($uuid);
    return $self->_get_data('get', "/api/v1/servers/$uuid");
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
    return $self->bandwidth_raw($uuid, %args)->{bandwidth};
}

sub bandwidth_raw {
    my ($self, $uuid, %args) = @_;
    $self->_require_uuid($uuid);
    my $query = {};
    $query->{range} = $args{range} if defined $args{range};
    return $self->_get_data('get', "/api/v1/servers/$uuid/bandwidth", query => $query);
}

sub billing {
    my ($self, $uuid) = @_;
    return $self->billing_raw($uuid)->{billing};
}

sub billing_raw {
    my ($self, $uuid) = @_;
    $self->_require_uuid($uuid);
    return $self->_get_data('get', "/api/v1/servers/$uuid/billing");
}

sub ssh_host_keys {
    my ($self, $uuid) = @_;
    my $items = $self->ssh_host_keys_raw($uuid)->{ssh_host_keys};
    return (ref $items eq 'ARRAY') ? $items : [];
}

sub ssh_host_keys_raw {
    my ($self, $uuid) = @_;
    $self->_require_uuid($uuid);
    return $self->_get_data('get', "/api/v1/servers/$uuid/ssh_host_keys");
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