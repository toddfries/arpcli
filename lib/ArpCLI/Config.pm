package ArpCLI::Config;

use strict;
use warnings;

use ArpCLI::Error;

use constant DEFAULT_CONFIG_PATH => $ENV{HOME} . '/.config/arpcli/conf';
use constant DEFAULT_BASE_URL    => 'https://arpnetworks.com';

sub new {
    my ($class, %args) = @_;
    my $path = $args{path} // DEFAULT_CONFIG_PATH;
    my $self = bless { path => $path }, $class;
    $self->_load unless $args{defer};
    return $self;
}

sub path      { $_[0]->{path} }
sub base_url  { $_[0]->{base_url} }
sub api_key   { $_[0]->{api_key} }

sub _load {
    my ($self) = @_;
    my $path = $self->{path};

    unless (-e $path) {
        die ArpCLI::Error->new(
            type    => 'config_missing',
            message => "configuration file not found: $path",
        );
    }

    open my $fh, '<', $path or die ArpCLI::Error->new(
        type    => 'config_unreadable',
        message => "cannot read configuration file: $path: $!",
    );

    my %ini;
    my $section;
    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/\s+#.*$//;
        $line =~ s/^\s+|\s+$//g;
        next if $line eq '' || $line =~ /^;/ || $line =~ /^#/;
        if ($line =~ /^\[(.+)\]$/) {
            $section = $1;
            next;
        }
        if ($line =~ /^([^=]+)=(.*)$/) {
            my ($key, $value) = ($1, $2);
            $key   =~ s/^\s+|\s+$//g;
            $value =~ s/^\s+|\s+$//g;
            $ini{$section}{$key} = $value if defined $section;
        }
    }
    close $fh;

    my $api = $ini{api} // {};
    my $base_url = $api->{base_url} // DEFAULT_BASE_URL;
    my $api_key  = $api->{api_key};

    unless (defined $api_key && length $api_key) {
        die ArpCLI::Error->new(
            type    => 'config_invalid',
            message => "api_key is required in [$path] section [api]",
        );
    }

    $base_url =~ s{/\z}{};
    $self->{base_url} = $base_url;
    $self->{api_key}  = $api_key;
    return $self;
}

1;