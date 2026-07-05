use strict;
use warnings;

use Test::More;
use lib 'lib';

use ArpCLI::Util qw(
    trim is_uuid format_bytes format_specs flatten_os_templates paginate_all
);

is(trim('  hi  '), 'hi');
is(trim(undef), '');
ok(is_uuid('52326bc0-79df-012c-d6f1-00163ec95f4c'));
ok(!is_uuid('not-a-uuid'));
ok(!is_uuid(''));
ok(!is_uuid(undef));

is(format_bytes(0), '0 B');
is(format_bytes(1024), '1.00 KB');
is(format_bytes(undef), 'n/a');

is(
    format_specs([
        { name => 'CPU', quantity => 1, unit => 'core' },
        { name => 'RAM', quantity => 1.5, unit => 'GB' },
    ]),
    'CPU=1core, RAM=1.5GB',
);
is(format_specs([]), '');
is(format_specs(undef), '');

my $flat = flatten_os_templates({
    debian => {
        title => 'Debian',
        series => [
            { title => 'Debian', version => '12', code => 'debian-12-amd64' },
        ],
    },
    ubuntu => {
        title => 'Ubuntu',
        series => [
            { title => 'Ubuntu', version => '24.04', code => 'ubuntu-24.04-amd64' },
        ],
    },
});
is(scalar @$flat, 2);
is($flat->[0]{code}, 'debian-12-amd64');

my $pages = paginate_all(sub {
    my ($page) = @_;
    return {
        items => [ { id => $page } ],
        pagination => {
            next_page => $page < 3 ? $page + 1 : undef,
        },
    };
});
is(scalar @$pages, 3);

$pages = paginate_all(sub {
    return { items => [1, 2], pagination => {} };
});
is(scalar @$pages, 2);

done_testing;