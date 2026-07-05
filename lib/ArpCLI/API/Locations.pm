package ArpCLI::API::Locations;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

sub list {
    my ($self) = @_;
    my $res = $self->http->get('/api/v1/locations');
    my $items = $res->{data}{locations};
    return (ref $items eq 'ARRAY') ? $items : [];
}

1;