package Test::MockHTTP;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        responses => $args{responses} // {},
        requests  => [],
        default   => $args{default},
    }, $class;
}

sub requests { $_[0]->{requests} }

sub request {
    my ($self, $method, $url, $opts) = @_;
    push @{ $self->{requests} }, {
        method  => $method,
        url     => $url,
        headers => $opts->{headers},
        content => $opts->{content},
    };

    my $key = "$method $url";
    my $resp = $self->{responses}{$key};
    $resp //= $self->{default} if $self->{default};
    $resp //= {
        status  => 404,
        content => '{"error":{"type":"not_found","message":"mock miss"}}',
    };
    return $resp;
}

1;