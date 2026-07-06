use strict;
use warnings;

use Test::More;

my $man = 'man/arpcli.1';
open my $fh, '<', $man or die "cannot read $man: $!";
my $src = do { local $/; <$fh> };
close $fh;

unlike($src, qr/(?<![-])\bFl json\b/, 'man page does not use .Fl json (use .Fl -json for --json)');
unlike($src, qr/Op Fl json\b/, 'man page does not use Op Fl json (use Op Fl -json)');
unlike($src, qr/(?<![-])\bFl thunder\b/, 'man page does not use .Fl thunder (use .Fl -thunder)');
unlike($src, qr/Op Fl thunder\b/, 'man page does not use Op Fl thunder (use Op Fl -thunder)');

like($src, qr/\.Fl -json/, 'man page documents --json');
like($src, qr/Fl -range/, 'man page documents --range');
like($src, qr/\.Fl -thunder/, 'man page documents --thunder');

ok(system('mandoc', '-T', 'ascii', $man) == 0, 'mandoc renders arpcli.1');

done_testing;