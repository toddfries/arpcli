package ArpCLI::RateLimit;

use strict;
use warnings;

use Fcntl qw(:flock SEEK_END);
use File::Basename qw(dirname);
use File::Path qw(make_path);

# Documented limits (spec/openapi.yaml): 120/min IP, 60/min key, 7/min server create.
# Client-side ceilings use a 10% margin on IP/key and reserve one server-create slot.
use constant WINDOW_SEC       => 60;
use constant LIMIT_KEY        => 54;
use constant LIMIT_IP         => 108;
use constant LIMIT_SERVER_CREATE => 6;

use constant CACHE_DIR  => $ENV{HOME} . '/.cache/arpcli';
use constant USAGE_PATH => CACHE_DIR . '/usage';
use constant VERSION    => 'arpcli-usage-v1';

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        path      => $args{path} // USAGE_PATH,
        key_id    => $args{key_id} // 'default',
        clock     => $args{clock} // \&_now,
        sleeper   => $args{sleeper} // \&_default_sleeper,
        warn      => $args{warn} // sub { warn $_[0] },
        verbose   => exists $args{verbose}
            ? $args{verbose}
            : _env_truthy($ENV{ARPCLI_VERBOSE}),
        _events   => [],
        _mtime    => 0,
    }, $class;
    $self->_ensure_cache_dir;
    $self->_load_locked;
    return $self;
}

sub limits {
    return {
        key           => LIMIT_KEY,
        ip            => LIMIT_IP,
        server_create => LIMIT_SERVER_CREATE,
        window_sec    => WINDOW_SEC,
    };
}

sub acquire {
    my ($self, $method, $path) = @_;
    my $bucket = _bucket_for($method, $path);
    $self->_with_journal(sub {
        my ($fh) = @_;
        $self->_reload_if_stale($fh);
        $self->_prune;
        $self->_wait_for_retry_after;
        $self->_wait_for_slot($bucket);
        $self->_record($fh, $bucket);
    });
    return;
}

sub record_retry_after {
    my ($self, $seconds) = @_;
    return unless defined $seconds && $seconds > 0;
    $self->_with_journal(sub {
        my ($fh) = @_;
        $self->_reload_if_stale($fh);
        $self->_prune;
        $self->_record_retry_after($fh, 0 + $seconds);
    });
    return;
}

sub wait {
    my ($self, $seconds, $reason) = @_;
    return unless defined $seconds && $seconds > 0;
    $self->_sleep($seconds, $reason // 'waiting');
    return;
}

sub counts {
    my ($self) = @_;
    $self->_prune;
    my $general = $self->_count_bucket('general');
    my $create  = $self->_count_bucket('server_create');
    my $retry   = $self->_active_retry_after;
    return {
        general          => $general,
        server_create    => $create,
        key_remaining    => LIMIT_KEY - $general,
        ip_remaining     => LIMIT_IP - $general,
        create_remaining => LIMIT_SERVER_CREATE - $create,
        retry_after_until => $retry,
    };
}

sub _bucket_for {
    my ($method, $path) = @_;
    $path = '/' . $path unless $path =~ m{\A/};
    return 'server_create'
        if uc($method) eq 'POST' && $path eq '/api/v1/servers';
    return 'general';
}

sub _env_truthy {
    my ($value) = @_;
    return 0 unless defined $value;
    return 0 if $value eq '' || $value eq '0';
    return 1;
}

sub _now { time() }

sub _default_sleeper {
    my ($seconds) = @_;
    return unless defined $seconds && $seconds > 0;
    sleep(int($seconds + 0.999));
    return;
}

sub _ensure_cache_dir {
    my ($self) = @_;
    my $dir = dirname($self->{path});
    make_path($dir, { mode => 0700 }) unless -d $dir;
    return;
}

sub _with_journal {
    my ($self, $code) = @_;
    open my $fh, '+>>', $self->{path} or die "arpcli: cannot open rate-limit journal $self->{path}: $!\n";
    flock($fh, LOCK_EX) or die "arpcli: cannot lock rate-limit journal: $!\n";
    my $ok = eval { $code->($fh); 1 };
    my $err = $@;
    flock($fh, LOCK_UN);
    close $fh;
    die $err if $err;
    return;
}

sub _reload_if_stale {
    my ($self, $fh) = @_;
    my $mtime = (stat($self->{path}))[9] // 0;
    return if $mtime == $self->{_mtime};
    $self->_load_from_handle($fh);
    $self->{_mtime} = $mtime;
    return;
}

sub _load_locked {
    my ($self) = @_;
    $self->_with_journal(sub {
        my ($fh) = @_;
        $self->_load_from_handle($fh);
        $self->{_mtime} = (stat($self->{path}))[9] // 0;
    });
    return;
}

sub _load_from_handle {
    my ($self, $fh) = @_;
    my @events;
    if (seek($fh, 0, 0)) {
        while (my $line = <$fh>) {
            chomp $line;
            next if $line eq '' || $line =~ /\A#/;
            my ($ts, $key_id, $bucket) = split /\t/, $line, 3;
            next unless defined $bucket && $key_id eq $self->{key_id};
            next unless $bucket =~ /\A(?:general|server_create|retry_after)\z/;
            next unless defined $ts && $ts =~ /\A[0-9]+(?:\.[0-9]+)?\z/;
            push @events, { ts => 0 + $ts, bucket => $bucket };
        }
    }
    $self->{_events} = \@events;
    $self->_prune;
    $self->_rewrite_journal($fh);
    return;
}

sub _prune {
    my ($self) = @_;
    my $now    = $self->{clock}->();
    my $cutoff = $now - WINDOW_SEC;
    my $events = $self->{_events};
    @$events = grep {
        ($_->{bucket} eq 'retry_after' && $_->{ts} > $now)
            || ($_->{bucket} ne 'retry_after' && $_->{ts} >= $cutoff)
    } @$events;
    return;
}

sub _active_retry_after {
    my ($self) = @_;
    my $now = $self->{clock}->();
    my $until;
    for my $ev (@{ $self->{_events} }) {
        next unless $ev->{bucket} eq 'retry_after' && $ev->{ts} > $now;
        $until = $ev->{ts} if !defined $until || $ev->{ts} < $until;
    }
    return $until;
}

sub _count_bucket {
    my ($self, $bucket) = @_;
    my $n = 0;
    for my $ev (@{ $self->{_events} }) {
        $n++ if $ev->{bucket} eq $bucket
            || ($bucket eq 'general' && $ev->{bucket} eq 'server_create');
    }
    return $n if $bucket eq 'general';
    return scalar grep { $_->{bucket} eq $bucket } @{ $self->{_events} };
}

sub _wait_for_retry_after {
    my ($self) = @_;
    while (1) {
        my $until = $self->_active_retry_after;
        return unless defined $until;
        my $wait = $until - $self->{clock}->();
        return if $wait <= 0;
        $self->_sleep(
            $wait,
            'honoring Retry-After cooldown from journal',
        );
        $self->_prune;
    }
}

sub _wait_for_slot {
    my ($self, $bucket) = @_;
    while (1) {
        my $general = $self->_count_bucket('general');
        my $create  = $self->_count_bucket('server_create');
        my @waits;

        if ($general >= LIMIT_KEY) {
            push @waits, _wait_until($self, 'general', LIMIT_KEY);
        }
        if ($general >= LIMIT_IP) {
            push @waits, _wait_until($self, 'general', LIMIT_IP);
        }
        if ($bucket eq 'server_create' && $create >= LIMIT_SERVER_CREATE) {
            push @waits, _wait_until($self, 'server_create', LIMIT_SERVER_CREATE);
        }

        return unless @waits;
        my $wait = (sort { $b <=> $a } @waits)[0];
        $wait = 1 if $wait <= 0;
        $self->_sleep(
            $wait,
            'rate limit margin reached; pausing before next request',
        );
        $self->_prune;
    }
}

sub _wait_until {
    my ($self, $bucket, $limit) = @_;
    my @hits = grep { $_->{bucket} eq $bucket } @{ $self->{_events} };
    if ($bucket eq 'general') {
        @hits = sort { $a->{ts} <=> $b->{ts} }
            grep { $_->{bucket} eq 'general' || $_->{bucket} eq 'server_create' }
            @{ $self->{_events} };
    }
    else {
        @hits = sort { $a->{ts} <=> $b->{ts} } @hits;
    }
    return 0 unless @hits >= $limit;
    my $oldest = $hits[0]{ts};
    return ($oldest + WINDOW_SEC) - $self->{clock}->() + 0.05;
}

sub _sleep {
    my ($self, $seconds, $reason) = @_;
    return unless defined $seconds && $seconds > 0;
    $seconds = 0.05 if $seconds < 0.05;
    if ($self->{verbose}) {
        $self->{warn}->(
            sprintf(
                "arpcli: %s; sleeping %ds\n",
                $reason,
                int($seconds + 0.999),
            ),
        );
    }
    $self->{sleeper}->($seconds);
    return;
}

sub _record {
    my ($self, $fh, $bucket) = @_;
    my $ts = $self->{clock}->();
    push @{ $self->{_events} }, { ts => $ts, bucket => $bucket };
    seek($fh, 0, SEEK_END) or die "arpcli: cannot seek rate-limit journal: $!\n";
    print {$fh} _format_line($ts, $self->{key_id}, $bucket);
    $self->{_mtime} = (stat($self->{path}))[9] // $self->{_mtime};
    return;
}

sub _record_retry_after {
    my ($self, $fh, $seconds) = @_;
    my $until = $self->{clock}->() + $seconds;
    push @{ $self->{_events} }, { ts => $until, bucket => 'retry_after' };
    seek($fh, 0, SEEK_END) or die "arpcli: cannot seek rate-limit journal: $!\n";
    print {$fh} _format_line($until, $self->{key_id}, 'retry_after');
    $self->{_mtime} = (stat($self->{path}))[9] // $self->{_mtime};
    return;
}

sub _rewrite_journal {
    my ($self, $fh) = @_;
    truncate($fh, 0) or die "arpcli: cannot truncate rate-limit journal: $!\n";
    seek($fh, 0, 0) or die "arpcli: cannot seek rate-limit journal: $!\n";
    print {$fh} "# ", VERSION, " key=", $self->{key_id}, "\n";
    for my $ev (sort { $a->{ts} <=> $b->{ts} } @{ $self->{_events} }) {
        print {$fh} _format_line($ev->{ts}, $self->{key_id}, $ev->{bucket});
    }
    $self->{_mtime} = (stat($self->{path}))[9] // 0;
    return;
}

sub _format_line {
    my ($ts, $key_id, $bucket) = @_;
    return sprintf("%.6f\t%s\t%s\n", $ts, $key_id, $bucket);
}

sub key_fingerprint {
    my ($api_key) = @_;
    require Digest::SHA;
    return substr(Digest::SHA::sha256_hex($api_key), 0, 12);
}

1;