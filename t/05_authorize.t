use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::Warnings 'warning';

use Mastodon::Client;

my $client = Mastodon::Client->new();

dies_ok { $client->authorize; } 'Authorize died when no params';

$client = Mastodon::Client->new(
    client_id     => 'id',
    client_secret => 'secret',
    access_token  => 'token',
);

use Data::Dumper;
ok warning { $client->authorize; }, 'Warns if access_token';

done_testing();
