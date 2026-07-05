use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 'lib';
use Test::Throws qw(throws_ok);

use ArpCLI::Util qw(paginate_all format_bytes is_uuid);
use ArpCLI::Config;
use ArpCLI::HTTP;
use ArpCLI::API::Servers;
use Test::MockHTTP;

# pagination: empty first page, no pagination key
my $empty = paginate_all(sub {
    return { items => [], pagination => { next_page => undef } };
});
is(scalar @$empty, 0);

# pagination: ludicrous page numbers still work if callback cooperates
my $one = paginate_all(sub {
    my ($page) = @_;
    return {
        items => [$page],
        pagination => { next_page => $page >= 100 ? undef : $page + 1 },
    };
});
is(scalar @$one, 100);

# bytes: negative treated as number (API shouldn't send this)
is(format_bytes(-1), '-1.00 B');

# uuid edge cases
ok(is_uuid('00000000-0000-0000-0000-000000000000'));
ok(!is_uuid("52326bc0-79df-012c-d6f1-00163ec95f4c\n"));

# config: empty file
my $tmp = "t/tmp-edge-$$.ini";
END { unlink $tmp if -e $tmp }
open my $fh, '>', $tmp or die $!;
close $fh;
throws_ok { ArpCLI::Config->new(path => $tmp) } 'ArpCLI::Error';

# http: empty 204 body
my $mock = Test::MockHTTP->new(
    responses => {
        'DELETE https://x.test/api/v1/ssh_keys/1' => { status => 204, content => '' },
    },
);
my $http = ArpCLI::HTTP->new(base_url => 'https://x.test', api_key => 'k', agent => $mock);
my $res = $http->delete('/api/v1/ssh_keys/1');
is($res->{status}, 204);
ok(!defined $res->{data});

# servers: nil uuid
my $servers = ArpCLI::API::Servers->new($http);
throws_ok { $servers->show(undef) } 'ArpCLI::Error';
throws_ok { $servers->show('') } 'ArpCLI::Error';

done_testing;