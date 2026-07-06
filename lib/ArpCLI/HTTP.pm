package ArpCLI::HTTP;

use strict;
use warnings;

use JSON::PP ();
use ArpCLI::Error;
use ArpCLI::Util qw(redact_secrets redact_headers);

use constant DEFAULT_MAX_RETRIES => 3;
use constant DEFAULT_RETRY_BASE => 1;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        base_url    => $args{base_url},
        api_key     => $args{api_key},
        agent       => $args{agent},
        timeout     => $args{timeout} // 60,
        max_retries => exists $args{max_retries} ? $args{max_retries} : DEFAULT_MAX_RETRIES,
        retry_base  => $args{retry_base} // DEFAULT_RETRY_BASE,
        sleeper     => $args{sleeper} // sub { sleep $_[0] },
        _sleep_total => 0,
    }, $class;
    return $self;
}

sub sleep_total { $_[0]->{_sleep_total} }

sub request {
    my ($self, $method, $path, %args) = @_;

    $path = '/' . $path unless $path =~ m{\A/};
    my $url = $self->_build_url($path, $args{query});

    my %headers = (
        Authorization => 'Bearer ' . $self->{api_key},
        Accept        => 'application/json',
        'Content-Type' => 'application/json',
    );

    my $content;
    if (exists $args{body}) {
        $content = JSON::PP->new->utf8->encode($args{body});
    }

    my $attempts = 0;
    my $max      = $self->{max_retries};
    while ($attempts <= $max) {
        $self->_debug_log($method, $url, \%headers, $content);
        my $response = $self->_agent->request(
            $method,
            $url,
            {
                headers => \%headers,
                (defined $content ? (content => $content) : ()),
                timeout => $self->{timeout},
            },
        );
        $self->_debug_log_response($method, $url, $response);

        my $status = $response->{status} // 0;
        if ($status == 429 || $status == 502) {
            if ($attempts < $max) {
                my $wait = _retry_delay($response, $attempts, $self->{retry_base});
                $self->{sleeper}->($wait);
                $self->{_sleep_total} += $wait;
                $attempts++;
                next;
            }
        }

        my $parsed = $self->_parse_response($method, $path, $response);
        $parsed->{rate_limits} = _rate_limit_headers($response->{headers});
        $parsed->{attempts}    = $attempts + 1;
        return $parsed;
    }
}

sub get    { shift->request('GET',    @_) }
sub post   { shift->request('POST',   @_) }
sub patch  { shift->request('PATCH',  @_) }
sub delete { shift->request('DELETE', @_) }

sub _build_url {
    my ($self, $path, $query) = @_;
    my $url = $self->{base_url} . $path;
    return $url unless ref $query eq 'HASH' && keys %$query;

    require URI;
    require URI::QueryParam;
    my $uri = URI->new($url);
    for my $key (sort keys %$query) {
        next unless defined $query->{$key};
        $uri->query_param_append($key, $query->{$key});
    }
    return "$uri";
}

sub _retry_delay {
    my ($response, $attempt, $base) = @_;
    my $headers = $response->{headers} // {};
    my $retry_after = $headers->{'retry-after'} // $headers->{'Retry-After'};
    if (defined $retry_after && $retry_after =~ /\A[0-9]+(?:\.[0-9]+)?\z/) {
        return 0 + $retry_after;
    }
    return $base * (2 ** $attempt);
}

sub _rate_limit_headers {
    my ($headers) = @_;
    return {} unless ref $headers eq 'HASH';
    my %limits;
    for my $key (keys %$headers) {
        next unless $key =~ /\A(?:x-)?rate(?:limit)?[-_]/i
            || $key =~ /\Aretry-after\z/i;
        $limits{$key} = $headers->{$key};
    }
    return \%limits;
}

sub _debug_enabled {
    my $env = $ENV{ARPCLI_DEBUG} // '';
    return $env ne '' && $env ne '0';
}

sub _debug_log {
    my ($self, $method, $url, $headers, $content) = @_;
    return unless _debug_enabled();
    my $safe_headers = redact_headers($headers);
    my $line = sprintf(
        'arpcli debug request: %s %s headers=%s',
        $method,
        $url,
        redact_secrets(JSON::PP->new->utf8->encode($safe_headers)),
    );
    $line .= ' body=' . redact_secrets($content) if defined $content;
    warn "$line\n";
    return;
}

sub _debug_log_response {
    my ($self, $method, $url, $response) = @_;
    return unless _debug_enabled();
    my $status = $response->{status} // 0;
    my $body   = $response->{content} // '';
    my $limits = _rate_limit_headers($response->{headers});
    my $extra  = keys %$limits
        ? ' rate_limits=' . redact_secrets(JSON::PP->new->utf8->encode($limits))
        : '';
    warn sprintf(
        "arpcli debug response: %s %s status=%d body=%s%s\n",
        $method,
        $url,
        $status,
        redact_secrets($body),
        $extra,
    );
    return;
}

sub _agent {
    my ($self) = @_;
    return $self->{agent} if $self->{agent};
    require HTTP::Tiny;
    $self->{agent} = HTTP::Tiny->new(
        agent      => 'arpcli/' . ($ArpCLI::VERSION // '0'),
        verify_SSL => 1,
    );
    return $self->{agent};
}

sub _parse_response {
    my ($self, $method, $path, $response) = @_;
    my $status = $response->{status} // 0;
    my $body   = $response->{content} // '';
    my $data;

    if (length $body) {
        eval {
            $data = JSON::PP->new->utf8->decode($body);
        };
        if ($@) {
            die ArpCLI::Error->new(
                type    => 'invalid_json',
                message => "invalid JSON from $method $path",
                status  => $status,
                body    => $body,
            );
        }
    }

    if ($status >= 200 && $status < 300) {
        return {
            status => $status,
            data   => $data,
            raw    => $body,
        };
    }

    my $type    = 'http_error';
    my $message = "HTTP $status for $method $path";
    if (ref $data eq 'HASH' && ref $data->{error} eq 'HASH') {
        $type    = $data->{error}{type}    // $type;
        $message = $data->{error}{message} // $message;
    }

    die ArpCLI::Error->new(
        type    => $type,
        message => $message,
        status  => $status,
        body    => $data // $body,
    );
}

1;