use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';

my $perl = $^X;
my $bin  = 'bin/arpcli';
my $tmp  = "t/tmp-cli-config-$$.ini";
END { unlink $tmp if -e $tmp }

open my $fh, '>', $tmp or die $!;
print {$fh} <<'INI';
[api]
base_url = https://example.test
api_key = cli_test_key
INI
close $fh;

{
    local $ENV{__ARPCLI_TEST_EXIT} = 0;
    like(
        qx($perl -Ilib $bin -h 2>&1),
        qr/usage: arpcli/,
        'help text',
    );
    like(
        qx($perl -Ilib $bin -h 2>&1),
        qr/--json/,
        'help documents --json',
    );
}

done_testing;