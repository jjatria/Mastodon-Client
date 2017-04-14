use strict;
use warnings;

use Test::More;

use Mastodon::Client;

my $client = Mastodon::Client->new(
    instance      => 'mastodon.cloud',
    name          => 'JJ',
    client_id     => 'id',
    client_secret => 'secret',
    access_token  => 'token',
);

isa_ok( $client, 'Mastodon::Client' );

is $client->name, 'JJ', 'Correct name';

done_testing();
