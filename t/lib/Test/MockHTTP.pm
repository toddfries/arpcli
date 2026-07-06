package Test::MockHTTP;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        responses  => $args{responses} // {},
        sequences  => $args{sequences} // {},
        requests   => [],
        default    => $args{default},
        seq_counts => {},
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
    if (my $seq = $self->{sequences}{$key}) {
        my $idx = $self->{seq_counts}{$key} // 0;
        $self->{seq_counts}{$key} = $idx + 1;
        return $seq->[$idx] // $seq->[-1];
    }

    my $resp = $self->{responses}{$key};
    $resp //= $self->{default} if $self->{default};
    $resp //= {
        status  => 404,
        content => '{"error":{"type":"not_found","message":"mock miss"}}',
    };
    return $resp;
}

1;