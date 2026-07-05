package Test::Throws;

use strict;
use warnings;

use Exporter qw(import);
use Test::More;

our @EXPORT_OK = qw(throws_ok);

sub throws_ok (&$;$) {
    my ($code, $class, $name) = @_;
    $name //= "throws $class";
    eval { $code->() };
    my $err = $@;
    if (!$err) {
        fail($name);
        return;
    }
    if (ref $err eq $class) {
        pass($name);
        return $err;
    }
    fail("$name (got " . (ref $err || $err) . ")");
    return $err;
}

1;