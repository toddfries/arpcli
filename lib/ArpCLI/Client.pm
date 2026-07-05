package ArpCLI::Client;

use strict;
use warnings;

use ArpCLI::Config;
use ArpCLI::HTTP;
use ArpCLI::API::Locations;
use ArpCLI::API::Isos;
use ArpCLI::API::Plans;
use ArpCLI::API::OsTemplates;
use ArpCLI::API::Servers;
use ArpCLI::API::ServerActions;
use ArpCLI::API::DnsRecords;
use ArpCLI::API::SshKeys;

sub new {
    my ($class, %args) = @_;
    my $config = $args{config} // ArpCLI::Config->new(
        defined $args{config_path} ? (path => $args{config_path}) : (),
    );
    my $http = $args{http} // ArpCLI::HTTP->new(
        base_url => $config->base_url,
        api_key  => $config->api_key,
        (defined $args{agent} ? (agent => $args{agent}) : ()),
    );

    my $self = bless {
        config => $config,
        http   => $http,
    }, $class;

    $self->{locations}    = ArpCLI::API::Locations->new($http);
    $self->{isos}         = ArpCLI::API::Isos->new($http);
    $self->{plans}        = ArpCLI::API::Plans->new($http);
    $self->{os_templates} = ArpCLI::API::OsTemplates->new($http);
    $self->{servers}      = ArpCLI::API::Servers->new($http);
    $self->{actions}      = ArpCLI::API::ServerActions->new($http);
    $self->{dns_records}  = ArpCLI::API::DnsRecords->new($http);
    $self->{ssh_keys}     = ArpCLI::API::SshKeys->new($http);

    return $self;
}

sub config       { $_[0]->{config} }
sub http         { $_[0]->{http} }
sub locations    { $_[0]->{locations} }
sub isos         { $_[0]->{isos} }
sub plans        { $_[0]->{plans} }
sub os_templates { $_[0]->{os_templates} }
sub servers      { $_[0]->{servers} }
sub actions      { $_[0]->{actions} }
sub dns_records  { $_[0]->{dns_records} }
sub ssh_keys     { $_[0]->{ssh_keys} }

sub discover {
    my ($self, %args) = @_;
    my $bandwidth_range = $args{bandwidth_range} // '30d';

    my $servers      = _array_or_empty(sub { $self->servers->list });
    my $dns_records  = _array_or_empty(sub { $self->dns_records->list });
    my $ssh_keys     = _array_or_empty(sub { $self->ssh_keys->list });
    my $locations    = _array_or_empty(sub { $self->locations->list });
    my $plans        = _array_or_empty(sub { $self->plans->list });
    my $isos         = _array_or_empty(sub { $self->isos->list });
    my $os_templates = eval { $self->os_templates->list } // {};

    my %server_detail;
    for my $server (@$servers) {
        my $uuid = $server->{uuid};
        next unless defined $uuid && length $uuid;
        $server_detail{$uuid} = {
            bandwidth     => scalar(eval { $self->servers->bandwidth($uuid, range => $bandwidth_range) }),
            billing       => scalar(eval { $self->servers->billing($uuid) }),
            ssh_host_keys => scalar(eval { $self->servers->ssh_host_keys($uuid) }),
        };
    }

    return {
        servers        => $servers,
        server_detail  => \%server_detail,
        dns_records    => $dns_records,
        ssh_keys       => $ssh_keys,
        locations      => $locations,
        plans          => $plans,
        isos           => $isos,
        os_templates   => $os_templates,
        bandwidth_range => $bandwidth_range,
    };
}

sub _array_or_empty {
    my ($cb) = @_;
    my $result = eval { $cb->() };
    return [] if $@;
    return (ref $result eq 'ARRAY') ? $result : [];
}

1;