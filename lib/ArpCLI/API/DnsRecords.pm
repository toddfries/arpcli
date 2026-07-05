package ArpCLI::API::DnsRecords;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

sub list {
    my ($self) = @_;
    return $self->_paginate('/api/v1/dns_records', 'dns_records');
}

sub create {
    my ($self, $dns_record) = @_;
    my $res = $self->http->post('/api/v1/dns_records', body => { dns_record => $dns_record });
    return $res->{data}{dns_record};
}

sub update {
    my ($self, $id, $dns_record) = @_;
    my $res = $self->http->patch("/api/v1/dns_records/$id", body => { dns_record => $dns_record });
    return $res->{data}{dns_record};
}

sub delete {
    my ($self, $id) = @_;
    return $self->http->delete("/api/v1/dns_records/$id");
}

1;