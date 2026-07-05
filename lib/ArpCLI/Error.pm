package ArpCLI::Error;

use strict;
use warnings;

use ArpCLI::Util qw(redact_secrets);

use overload
    '""' => sub { redact_secrets($_[0]->{message}) },
    fallback => 1;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        type    => $args{type}    // 'error',
        message => $args{message} // 'unknown error',
        status  => $args{status},
        body    => $args{body},
    }, $class;
    return $self;
}

sub type    { $_[0]->{type} }
sub message { redact_secrets($_[0]->{message}) }
sub status  { $_[0]->{status} }
sub body    { $_[0]->{body} }

sub debug_dump {
    my ($self) = @_;
    my $body = $self->{body};
    if (defined $body && !ref $body) {
        $body = redact_secrets($body);
    }
    elsif (ref $body eq 'HASH' || ref $body eq 'ARRAY') {
        require JSON::PP;
        $body = redact_secrets(JSON::PP->new->utf8->encode($body));
    }
    return sprintf(
        'type=%s status=%s message=%s body=%s',
        $self->{type} // '',
        $self->{status} // '',
        redact_secrets($self->{message} // ''),
        defined $body ? $body : '',
    );
}

1;