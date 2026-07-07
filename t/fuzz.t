use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';

my $perl = $^X;
my $bin  = 'bin/arpcli';
my $tmp  = "t/tmp-fuzz-config-$$.ini";
my $bad  = "t/tmp-fuzz-missing-$$.ini";
END {
    unlink $tmp if -e $tmp;
    unlink $bad if -e $bad;
}

open my $fh, '>', $tmp or die $!;
print {$fh} <<'INI';
[api]
base_url = https://example.test
api_key = fuzz_test_key
INI
close $fh;

sub run_cli {
    my (@args) = @_;
    my $quoted = join ' ', map { qq('$_') } @args;
    my $out = qx($perl -Ilib $bin -c $tmp $quoted 2>&1);
    return ($? >> 8, $out);
}

{
    local $ENV{__ARPCLI_TEST_EXIT} = 0;
    like(qx($perl -Ilib $bin 2>&1), qr/usage: arpcli/, 'bare arpcli prints usage');
    is($? >> 8, 0, 'bare arpcli exits 0');
}

{
    local $ENV{__ARPCLI_TEST_EXIT} = 0;
    my $out = qx($perl -Ilib $bin -c $bad 2>&1);
    my $exit = $? >> 8;
    unlike($out, qr/usage: arpcli/, '-c missing config alone does not mask error with usage');
    like($out, qr/configuration file not found/, '-c missing config alone reports missing file');
    is($exit, 1, '-c missing config alone exits 1');
}

my $uuid = '52326bc0-79df-012c-d6f1-00163ec95f4c';
my $huge   = 'A' x 256;

my @cases = (
    [ ['nosuchcmd'],                                              255, qr/unknown command/ ],
    [ ['-x'],                                                     255, qr/unknown option/ ],
    [ ['-c'],                                                     255, qr/-c requires a path/ ],
    [ [''],                                                       255, qr/unknown command/ ],
    [ ['servers'],                                                255, qr/requires a subcommand/ ],
    [ ['servers', 'nosuch'],                                      255, qr/unknown servers subcommand/ ],
    [ ['servers', 'show'],                                        255, qr/requires <uuid>/ ],
    [ ['servers', 'show', 'not-a-uuid'],                            1, qr/uuid is required/ ],
    [ ['servers', 'show', '../../../etc/passwd'],                   1, qr/uuid is required/ ],
    [ ['servers', 'show', "$uuid\n"],                               1, qr/uuid is required/ ],
    [ ['servers', 'show', $huge],                                   1, qr/uuid is required/ ],
    [ ['servers', 'list', '--thunder'],                           255, qr/unknown servers list option/ ],

    [ ['servers', 'delete'],                                      255, qr/requires <uuid>/ ],
    [ ['servers', 'boot'],                                        255, qr/requires <uuid>/ ],
    [ ['servers', 'change-iso'],                                  255, qr/requires <uuid> <iso_file>/ ],
    [ ['servers', 'change-iso', 'baduuid'],                       255, qr/requires <uuid> <iso_file>/ ],
    [ ['servers', 'bandwidth', '--range'],                          1, qr/uuid is required/ ],
    [ ['servers', 'bandwidth', 'baduuid', '--range'],             255, qr/--range requires a value/ ],
    [ ['servers', 'set-parameter', 'a', 'b'],                   255, qr/requires <uuid> <param> <value>/ ],
    [ ['servers', 'set-parameter', 'baduuid', 'boot-menu', 'on', 'extra'], 255, qr/unknown servers set-parameter option/ ],
    [ ['servers', 'create'],                                      255, qr/unknown servers subcommand/ ],

    [ ['status', '--range'],                                      255, qr/--range requires a value/ ],
    [ ['status', '--brief'],                                        0, qr/services\.servers\.count=/ ],
    [ ['status', '--bogus'],                                      255, qr/unknown status option/ ],
    [ ['dns-records'],                                            255, qr/requires a subcommand/ ],
    [ ['dns-records', 'create'],                                  255, qr/requires <ip_address> <hostname>/ ],
    [ ['dns-records', 'create', '10.0.0.2'],                     255, qr/requires <ip_address> <hostname>/ ],
    [ ['dns-records', 'create', '10.0.0.2', 'ptr.example.com'],   1, qr/insufficient_scope|invalid JSON|HTTP|Could not connect/ ],
    [ ['dns-records', 'update'],                                  255, qr/requires <id> <hostname>/ ],
    [ ['dns-records', 'update', 'xxxx'],                          255, qr/requires <id> <hostname>/ ],
    [ ['dns-records', 'update', 'xxxx', 'ptr.example.com'],         1, qr/insufficient_scope|invalid JSON|HTTP|Could not connect/ ],
    [ ['dns-records', 'delete'],                                  255, qr/requires <id>/ ],
    [ ['dns-records', 'delete', 'xxxx'],                            1, qr/insufficient_scope|invalid JSON|HTTP|Could not connect/ ],
    [ ['ssh-keys', 'create'],                                     255, qr/requires <name> <username> <key>/ ],
    [ ['ssh-keys', 'create', 'Laptop'],                           255, qr/requires <name> <username> <key>/ ],
    [ ['ssh-keys', 'create', 'Laptop', 'deploy'],                 255, qr/requires <name> <username> <key>/ ],
    [ ['ssh-keys', 'create', 'Laptop', 'deploy', 'ssh-ed25519 AAAA'], 1, qr/insufficient_scope|invalid JSON|HTTP|Could not connect/ ],
    [ ['ssh-keys', 'delete'],                                   255, qr/requires <id>/ ],
    [ ['ssh-keys', 'delete', '1'],                                  1, qr/insufficient_scope|invalid JSON|HTTP|Could not connect/ ],
    [ ['plans', 'create'],                                        255, qr/unknown plans subcommand/ ],
    [ ['plans', '--json'],                                          1, qr/invalid JSON|HTTP|Could not connect|"plans"/ ],
    [ ['plans', '--thunder', '--json'],                             1, qr/invalid JSON|HTTP|Could not connect|"plans"/ ],
    [ ['locations', '--json'],                                      1, qr/invalid JSON|HTTP|Could not connect|"locations"/ ],
    [ ['isos', '--json'],                                           1, qr/invalid JSON|HTTP|Could not connect|"isos"/ ],
    [ ['isos', 'list', '--thunder'],                              255, qr/unknown isos list option/ ],
    [ ['os-templates', 'list', '--range', '30d'],                 255, qr/unknown os-templates list option/ ],
    [ ['locations', 'list', '--thunder'],                         255, qr/unknown locations list option/ ],

    [ ['servers list; echo pwned'],                               255, qr/unknown command/ ],
);

for my $case (@cases) {
    my ($args, $want_exit, $pattern) = @$case;
    my ($exit, $out) = run_cli(@$args);
    unlike($out, qr/unknown (?:plans|locations|isos|os-templates) subcommand: --json/,
        join(' ', @$args) . ' does not treat --json as subcommand')
        if grep { $_ eq '--json' } @$args;
    like($out, $pattern, join(' ', @$args) . ' stderr');
    is($exit, $want_exit, join(' ', @$args) . " exit $want_exit");
}

# Convention from fuzzing: CLI parse/usage errors exit 255; API/config errors exit 1.
is((run_cli('servers', 'show', 'not-a-uuid'))[0], 1, 'API-layer uuid validation exits 1');
is((run_cli('servers', 'nosuch'))[0], 255, 'CLI unknown subcommand exits 255');

done_testing;