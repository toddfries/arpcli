use strict;
use warnings;

use Test::More;
use lib 't/lib';
use Test::Throws qw(throws_ok);
use lib 'lib';

use ArpCLI::Config;
use ArpCLI::Error;

my $tmp = 't/tmp-config-$$.ini';
END { unlink $tmp if -e $tmp }

sub write_config {
    my ($content) = @_;
    open my $fh, '>', $tmp or die $!;
    print {$fh} $content;
    close $fh;
}

write_config(<<'INI');
[api]
base_url = https://example.test/
api_key = test_key_123
INI

my $cfg = ArpCLI::Config->new(path => $tmp);
is($cfg->base_url, 'https://example.test');
is($cfg->api_key, 'test_key_123');

write_config("[api]\n");
throws_ok { ArpCLI::Config->new(path => $tmp) } 'ArpCLI::Error';

throws_ok { ArpCLI::Config->new(path => 't/no-such-config.ini') } 'ArpCLI::Error';

write_config(<<'INI');
; comment
[api]
base_url=https://arpnetworks.com
api_key = spaced key
INI
$cfg = ArpCLI::Config->new(path => $tmp);
is($cfg->api_key, 'spaced key');

done_testing;