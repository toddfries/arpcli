package ArpCLI::API::ServerActions;

use strict;
use warnings;

use parent 'ArpCLI::API::Base';

use ArpCLI::Error;
use ArpCLI::Util qw(is_uuid);

my %ACTIONS = map { $_ => 1 } qw(boot shutdown poweroff reset);

sub boot      { shift->_action('boot',      @_) }
sub shutdown  { shift->_action('shutdown',  @_) }
sub poweroff  { shift->_action('poweroff',  @_) }
sub reset     { shift->_action('reset',     @_) }

sub change_iso {
    my ($self, $uuid, $iso_file) = @_;
    $self->_require_uuid($uuid);
    return $self->http->post(
        "/api/v1/servers/$uuid/actions/change_iso",
        body => { iso_file => $iso_file },
    );
}

sub set_parameter {
    my ($self, $uuid, $param, $value) = @_;
    $self->_require_uuid($uuid);
    return $self->http->post(
        "/api/v1/servers/$uuid/actions/set_parameter",
        body => { param => $param, value => $value },
    );
}

sub _action {
    my ($self, $action, $uuid) = @_;
    $self->_require_uuid($uuid);
    die ArpCLI::Error->new(
        type    => 'invalid_action',
        message => "unknown server action: $action",
    ) unless $ACTIONS{$action};
    return $self->http->post("/api/v1/servers/$uuid/actions/$action");
}

sub _require_uuid {
    my ($self, $uuid) = @_;
    require ArpCLI::Error;
    die ArpCLI::Error->new(
        type    => 'invalid_uuid',
        message => 'server uuid is required and must be valid',
    ) unless is_uuid($uuid);
    return;
}

1;