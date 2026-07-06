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

my @cases = (
    [ ['nosuchcmd'],                           255, qr/unknown command/ ],
    [ ['-x'],                                  255, qr/unknown option/ ],
    [ ['-c'],                                  255, qr/-c requires a path/ ],
    [ ['servers'],                             255, qr/requires a subcommand/ ],
    [ ['servers', 'nosuch'],                   255, qr/unknown servers subcommand/ ],
    [ ['servers', 'show'],                     255, qr/requires <uuid>/ ],
    [ ['servers', 'show', 'not-a-uuid'],         1, qr/uuid is required/ ],
    [ ['servers', 'list', '--thunder'],        255, qr/unknown servers list option/ ],

    [ ['status', '--range'],                   255, qr/--range requires a value/ ],
    [ ['status', '--bogus'],                   255, qr/unknown status option/ ],
    [ ['dns-records'],                         255, qr/requires a subcommand/ ],
    [ ['dns-records', 'create'],               255, qr/unknown dns-records subcommand/ ],
    [ ['ssh-keys', 'delete', '1'],             255, qr/unknown ssh-keys subcommand/ ],
    [ ['plans', 'create'],                     255, qr/unknown plans subcommand/ ],
    [ ['servers', 'set-parameter', 'a', 'b'], 255, qr/requires <uuid> <param> <value>/ ],
    [ ['servers list; echo pwned'],            255, qr/unknown command/ ],
);

for my $case (@cases) {
    my ($args, $want_exit, $pattern) = @$case;
    my ($exit, $out) = run_cli(@$args);
    like($out, $pattern, join(' ', @$args) . ' stderr');
    is($exit, $want_exit, join(' ', @$args) . " exit $want_exit");
}

done_testing;