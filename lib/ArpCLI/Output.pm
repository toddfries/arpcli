package ArpCLI::Output;

use strict;
use warnings;

use ArpCLI::Util qw(format_bytes format_specs flatten_os_templates);

sub new {
    my ($class, %args) = @_;
    return bless {
        fh => $args{fh} // \*STDOUT,
    }, $class;
}

sub fh { $_[0]->{fh} }

sub print_discovery {
    my ($self, $data) = @_;
    my $fh = $self->fh;

    $self->_line($fh, 'arp.account');
    $self->_line($fh, '  services.servers.count', scalar @{ $data->{servers} // [] });
    $self->_line($fh, '  services.dns_records.count', scalar @{ $data->{dns_records} // [] });
    $self->_line($fh, '  services.ssh_keys.count', scalar @{ $data->{ssh_keys} // [] });
    $self->_line($fh, '  catalog.locations.count', scalar @{ $data->{locations} // [] });
    $self->_line($fh, '  catalog.plans.count', scalar @{ $data->{plans} // [] });
    $self->_line($fh, '  catalog.isos.count', scalar @{ $data->{isos} // [] });
    my $templates = flatten_os_templates($data->{os_templates});
    $self->_line($fh, '  catalog.os_templates.count', scalar @$templates);

    $self->_blank($fh);
    $self->_section_servers($fh, $data);
    $self->_blank($fh);
    $self->_section_dns($fh, $data);
    $self->_blank($fh);
    $self->_section_ssh_keys($fh, $data);
    $self->_blank($fh);
    $self->_section_catalog($fh, $data, $templates);
    return;
}

sub _section_servers {
    my ($self, $fh, $data) = @_;
    $self->_line($fh, 'arp.servers');
    my $servers = $data->{servers} // [];
    return $self->_line($fh, '  (none)') unless @$servers;

    my @rows;
    for my $s (sort { ($a->{label} // '') cmp ($b->{label} // '') } @$servers) {
        push @rows, {
            label   => $s->{label} // '',
            uuid    => $s->{uuid} // '',
            state   => $s->{state} // '',
            plan    => $s->{plan} // '',
            os      => $s->{os_template} // '',
            ipv4    => $s->{primary_ipv4} // '-',
            ipv6    => $s->{primary_ipv6} // '-',
        };
    }
    $self->_table($fh, '  ', [qw(LABEL UUID STATE PLAN OS IPv4 IPv6)], \@rows,
        sub {
            my ($r) = @_;
            ($r->{label}, $r->{uuid}, $r->{state}, $r->{plan}, $r->{os}, $r->{ipv4}, $r->{ipv6});
        },
    );

    for my $s (sort { ($a->{label} // '') cmp ($b->{label} // '') } @$servers) {
        my $uuid = $s->{uuid};
        my $detail = $data->{server_detail}{$uuid} // {};
        $self->_blank($fh);
        $self->_line($fh, "  server.$uuid");
        $self->_sysctl($fh, '    ', {
            'label'                => $s->{label},
            'state'                => $s->{state},
            'provisioning_status'  => $s->{provisioning_status},
            'billing_mode'         => $s->{billing_mode},
            'billing_interval'     => $s->{billing_interval},
            'location'             => $s->{location},
            'plan'                 => $s->{plan},
            'os_template'          => $s->{os_template},
            'specs'                => format_specs($s->{specs}),
            'primary_ipv4'         => $s->{primary_ipv4},
            'primary_ipv6'         => $s->{primary_ipv6},
            'ip_space'             => $s->{ip_space},
            'created_at'           => $s->{created_at},
        });

        if (my $bw = $detail->{bandwidth}) {
            $self->_line($fh, '    bandwidth');
            $self->_sysctl($fh, '      ', {
                range          => $bw->{range} // $data->{bandwidth_range},
                inbound_bytes  => format_bytes($bw->{inbound_bytes}),
                outbound_bytes => format_bytes($bw->{outbound_bytes}),
                total_bytes    => format_bytes($bw->{total_bytes}),
            });
        }

        if (my $bill = $detail->{billing}) {
            $self->_line($fh, '    billing');
            $self->_sysctl($fh, '      ', {
                billing_mode     => $bill->{billing_mode},
                interval         => $bill->{interval},
                total            => defined $bill->{total} ? sprintf('%.2f', $bill->{total}) : undef,
                free             => $bill->{free},
                est_monthly      => defined $bill->{est_monthly} ? sprintf('%.2f', $bill->{est_monthly}) : undef,
                uninvoiced_hours => $bill->{uninvoiced_hours},
                uninvoiced_amount => defined $bill->{uninvoiced_amount}
                    ? sprintf('%.2f', $bill->{uninvoiced_amount}) : undef,
            });
            if (ref $bill->{line_items} eq 'ARRAY' && @{ $bill->{line_items} }) {
                $self->_line($fh, '      line_items');
                for my $item (@{ $bill->{line_items} }) {
                    $self->_line($fh, sprintf(
                        '        %-20s qty=%-4s unit=%-8s amount=%s',
                        $item->{label} // '',
                        $item->{quantity} // '',
                        defined $item->{unit_price} ? sprintf('%.4f', $item->{unit_price}) : '-',
                        defined $item->{amount} ? sprintf('%.2f', $item->{amount}) : '-',
                    ));
                }
            }
        }

        if (my $keys = $detail->{ssh_host_keys}) {
            $self->_line($fh, '    ssh_host_keys');
            if (ref $keys eq 'ARRAY' && @$keys) {
                for my $k (@$keys) {
                    $self->_line($fh, sprintf('      %-8s %s', $k->{type} // '', $k->{fingerprint} // ''));
                }
            } else {
                $self->_line($fh, '      (none)');
            }
        }
    }
}

sub _section_dns {
    my ($self, $fh, $data) = @_;
    $self->_line($fh, 'arp.dns_records');
    my $records = $data->{dns_records} // [];
    return $self->_line($fh, '  (none)') unless @$records;

    $self->_table($fh, '  ', [qw(ID ARPA_NAME CONTENT DOMAIN)], $records, sub {
        my ($r) = @_;
        ($r->{id}, $r->{name}, $r->{content}, $r->{domain});
    });
}

sub _section_ssh_keys {
    my ($self, $fh, $data) = @_;
    $self->_line($fh, 'arp.ssh_keys');
    my $keys = $data->{ssh_keys} // [];
    return $self->_line($fh, '  (none)') unless @$keys;

    $self->_table($fh, '  ', [qw(ID NAME USERNAME TYPE FINGERPRINT)], $keys, sub {
        my ($k) = @_;
        ($k->{id}, $k->{name}, $k->{username} // '-', $k->{key_type}, $k->{fingerprint_sha256});
    });
}

sub _section_catalog {
    my ($self, $fh, $data, $templates) = @_;
    $self->_line($fh, 'arp.catalog');
    $self->_line($fh, '  locations');
    for my $loc (sort { ($a->{code} // '') cmp ($b->{code} // '') } @{ $data->{locations} // [] }) {
        $self->_line($fh, sprintf(
            '    %-4s %-20s %s',
            $loc->{code} // '',
            $loc->{name} // '',
            $loc->{country} // '',
        ));
    }

    $self->_line($fh, '  plans');
    for my $plan (sort { ($a->{id} // 0) <=> ($b->{id} // 0) } @{ $data->{plans} // [] }) {
        my $prices = $plan->{prices} // {};
        my @price_bits;
        for my $k (sort keys %$prices) {
            push @price_bits, "$k=\$" . sprintf('%.4f', $prices->{$k});
        }
        $self->_line($fh, sprintf(
            '    id=%-4d %-22s %s  %s',
            $plan->{id} // 0,
            $plan->{name} // '',
            format_specs($plan->{specs}),
            join(' ', @price_bits),
        ));
    }

    $self->_line($fh, '  isos');
    my $iso_count = scalar @{ $data->{isos} // [] };
    $self->_line($fh, "    count=$iso_count");
    for my $iso (sort @{ $data->{isos} // [] }) {
        $self->_line($fh, "    $iso");
    }

    $self->_line($fh, '  os_templates');
    for my $t (sort { ($a->{code} // '') cmp ($b->{code} // '') } @$templates) {
        $self->_line($fh, sprintf(
            '    %-30s %-12s %s',
            $t->{code} // '',
            $t->{family} // '',
            $t->{version} // '',
        ));
    }
}

sub _sysctl {
    my ($self, $fh, $indent, $pairs) = @_;
    for my $key (sort keys %$pairs) {
        my $val = $pairs->{$key};
        $val = 'n/a' unless defined $val;
        $self->_line($fh, "$indent$key=$val");
    }
}

sub _table {
    my ($self, $fh, $indent, $headers, $rows, $extract) = @_;
    my @data = map { [ $extract->($_) ] } @$rows;
    my @widths;
    for my $i (0 .. $#$headers) {
        my $w = length $headers->[$i];
        for my $row (@data) {
            my $len = length($row->[$i] // '');
            $w = $len if $len > $w;
        }
        push @widths, $w;
    }
    $self->_line($fh, $indent . join(' ', map { sprintf("%-*s", $widths[$_], $headers->[$_]) } 0 .. $#$headers));
    for my $row (@data) {
        $self->_line($fh, $indent . join(' ', map {
            sprintf("%-*s", $widths[$_], $row->[$_] // '')
        } 0 .. $#$headers));
    }
}

sub _line {
    my ($self, $fh, $text) = @_;
    print {$fh} $text, "\n";
}

sub _blank {
    my ($self, $fh) = @_;
    print {$fh} "\n";
}

1;