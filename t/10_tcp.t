use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::TCP;
use Test::Warnings 'warning';
use LWP::UserAgent;
use Mastodon::Client;

use lib 't/lib';

use Plack::Runner;
use Plack::App::Mastodon::MockServer::v1;

# use Log::Any::Adapter;
# Log::Any::Adapter->set( 'Stderr',
#   category => 'Mastodon',
#   log_level => 'debug',
# );

use Net::EmptyPort qw( empty_port );
my $host = '0.0.0.0';
my $port = empty_port();

test_tcp(
  host => $host,
  server => sub {
    my $port = shift;
    my $runner = Plack::Runner->new;
    $runner->parse_options(
      '--host'   => $host,
      '--port'   => $port,
      '--env'    => 'test',
      '--server' => 'HTTP::Server::PSGI'
    );
    $runner->run(Plack::App::Mastodon::MockServer::v1->new->to_app);
  },
  client => sub {
    my ($port, $server_pid) = @_;
    my $url = "http://$host:$port";

    my $client = Mastodon::Client->new(
      instance => $url,
      coerce_entities => 1,
    );

    ok my $instance = $client->fetch_instance, 'fetch_instance succeeds';
    isa_ok $instance, 'Mastodon::Entity::Instance';
    isa_ok $client->instance, 'Mastodon::Entity::Instance';

    # Override internal base URL
    $client->instance->{uri} = "http://$host:$port";

    # get_account
    {
      my $response;
      ok $response = $client->get_account();
      isa_ok $response, 'Mastodon::Entity::Account';
      like $response->username, qr/a/i, 'Fetches self';

      is_deeply $response, $client->account, 'Cache self account';

      ok $response = $client->get_account(2);
      isa_ok $response, 'Mastodon::Entity::Account';
      like $response->username, qr/b/i, 'Fetches other';

      ok $response = $client->get_account({});
      isa_ok $response, 'Mastodon::Entity::Account';
      like $response->username, qr/a/i, 'Fetches self';

      ok $response = $client->get_account(2, {});
      isa_ok $response, 'Mastodon::Entity::Account';
      like $response->username, qr/b/i, 'Fetches other';
    }

    # followers
    {
      use Mastodon::Types qw( is_Account );
      use List::Util qw( all );

      my $response;
      ok $response = $client->followers(), 'followers()';
      isa_ok $response, 'ARRAY';
      is scalar(@{$response}), 2, 'a has two followers';
      ok( (all { is_Account($_) } @{$response}), 'List of Account');
      like $response->[0]->username, qr/b/i, 'Followed by b';
      like $response->[1]->username, qr/c/i, 'Followed by c';

      ok $response = $client->followers(2), 'followers(Int)';
      isa_ok $response, 'ARRAY';
      is scalar(@{$response}), 0, 'b has no followers';

      ok $response = $client->followers({}), 'followers(HashRef)';
      isa_ok $response, 'ARRAY';
      is scalar(@{$response}), 2, 'a has two followers';
      ok( (all { is_Account($_) } @{$response}), 'List of Account');
      like $response->[0]->username, qr/b/i, 'a followed by b';
      like $response->[1]->username, qr/c/i, 'a followed by c';

      ok $response = $client->followers(2, {}), 'followers(Int, HashRef)';
      isa_ok $response, 'ARRAY';
      is scalar(@{$response}), 0, 'b has no followers';
    }

    # following
    {
      use Mastodon::Types qw( is_Account );
      use List::Util qw( all );

      my $response;
      ok $response = $client->following(), 'following()';
      isa_ok $response, 'ARRAY';
      ok( (all { is_Account($_) } @{$response}), 'List of Account');
      like $response->[0]->username, qr/c/i, 'a follows c';

      ok $response = $client->following(2), 'following(Int)';
      isa_ok $response, 'ARRAY';
      ok( (all { is_Account($_) } @{$response}), 'List of Account');
      like $response->[0]->username, qr/a/i, 'b follows a';

      ok $response = $client->following({}), 'following(HashRef)';
      isa_ok $response, 'ARRAY';
      ok( (all { is_Account($_) } @{$response}), 'List of Account');
      like $response->[0]->username, qr/c/i, 'a follows c';

      ok $response = $client->following(2, {}), 'following(Int, HashRef)';
      isa_ok $response, 'ARRAY';
      ok( (all { is_Account($_) } @{$response}), 'List of Account');
      like $response->[0]->username, qr/a/i, 'b follows a';
    }

    # statuses
    {
      my $response;
      ok $response = $client->statuses(), 'statuses()';
      ok $response = $client->statuses(2), 'statuses(Int)';
      ok $response = $client->statuses({}), 'statuses(HashRef)';
      ok $response = $client->statuses(2, {}), 'statuses(Int, HashRef)';
    }
  },
);

done_testing();
