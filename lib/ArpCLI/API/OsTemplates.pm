package ArpCLI::API::OsTemplates;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

sub list {
    my ($self) = @_;
    my $res = $self->http->get('/api/v1/os_templates');
    return $res->{data}{os_templates} // {};
}

1;