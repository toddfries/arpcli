package ArpCLI::API::Base;

use strict;
use warnings;

use ArpCLI::Util qw(paginate_all);

sub new {
    my ($class, $http) = @_;
    return bless { http => $http }, $class;
}

sub http { $_[0]->{http} }

sub _get_data {
    my ($self, $method, $path, %args) = @_;
    my $res = $self->http->$method($path, %args);
    my $data = $res->{data};
    return ref $data eq 'HASH' ? $data : {};
}

sub _paginate {
    my ($self, $path, $items_key) = @_;
    return paginate_all(sub {
        my ($page) = @_;
        my $res = $self->http->get($path, query => { page => $page });
        my $data = $res->{data} // {};
        return {
            items      => $data->{$items_key} // [],
            pagination => $data->{meta}{pagination},
        };
    });
}

1;