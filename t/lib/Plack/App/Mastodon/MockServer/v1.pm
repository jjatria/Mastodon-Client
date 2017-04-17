package Plack::App::Mastodon::MockServer::v1;

use strict;
use warnings;

use parent qw( Plack::Component );

use Plack::Util;
use JSON;

my $samples = {
  Account => {
    a => {
      acct              => 'a',
      avatar            => 'https://perl.test/path/to/image.png',
      avatar_static     => 'https://perl.test/path/to/image.png',
      created_at        => '2017-04-12T11:24:56.416Z',
      display_name      => 'Ada',
      followers_count   => 2,
      following_count   => 1,
      header            => '/headers/original/missing.png',
      header_static     => '/headers/original/missing.png',
      id                => 1,
      locked            => 0,
      note              => '',
      statuses_count    => 2,
      url               => 'https://perl.test/@a',
      username          => 'a'
    },
    b => {
      acct              => 'b',
      avatar            => 'https://perl.test/path/to/image.png',
      avatar_static     => 'https://perl.test/path/to/image.png',
      created_at        => '2015-04-12T11:24:56.416Z',
      display_name      => 'Bob',
      followers_count   => 0,
      following_count   => 1,
      header            => '/headers/original/missing.png',
      header_static     => '/headers/original/missing.png',
      id                => 2,
      locked            => 0,
      note              => '',
      statuses_count    => 0,
      url               => 'https://perl.test/@b',
      username          => 'b'
    },
    c => {
      acct              => 'c',
      avatar            => 'https://perl.test/path/to/image.png',
      avatar_static     => 'https://perl.test/path/to/image.png',
      created_at        => '2016-04-12T11:24:56.416Z',
      display_name      => 'Cid',
      followers_count   => 1,
      following_count   => 1,
      header            => '/headers/original/missing.png',
      header_static     => '/headers/original/missing.png',
      id                => 2,
      locked            => 0,
      note              => '',
      statuses_count    => 0,
      url               => 'https://perl.test/@c',
      username          => 'c'
    },
  },
  Relationship => {
    a => {
      b => {
        id          => 2,
        blocking    => 0,
        followed_by => 1,
        following   => 0,
        muting      => 0,
        requested   => 0
      },
      c => {
        id          => 3,
        blocking    => 0,
        followed_by => 1,
        following   => 1,
        muting      => 0,
        requested   => 0
      },
    },
    b => {
      a => {
        id          => 1,
        blocking    => 0,
        followed_by => 0,
        following   => 1,
        muting      => 0,
        requested   => 0
      },
      c => {
        id          => 3,
        blocking    => 0,
        followed_by => 0,
        following   => 0,
        muting      => 0,
        requested   => 0
      },
    },
    c => {
      a => {
        id          => 1,
        blocking    => 0,
        followed_by => 1,
        following   => 1,
        muting      => 0,
        requested   => 0
      },
      b => {
        id          => 2,
        blocking    => 0,
        followed_by => 0,
        following   => 0,
        muting      => 0,
        requested   => 0
      },
    },
  },
  Instance => {
    description => 'This is not a real instance',
    email       => 'admin@perl.test',
    title       => 'perl.test',
    uri         => 'https://perl.test'
  },
  Status => {
    a => [
      {},
      {},
    ],
  },
};

my $routes = {
  GET => {
    'instance' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json $samples->{Instance} ],
    ],
    'accounts/2' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json $samples->{Account}{b} ],
    ],
    'accounts/verify_credentials' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json $samples->{Account}{a} ],
    ],
    'accounts/1/followers' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [ $samples->{Account}{b}, $samples->{Account}{c} ] ],
    ],
    'accounts/2/followers' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [] ],
    ],
    'accounts/1/following' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [ $samples->{Account}{c} ] ],
    ],
    'accounts/2/following' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [ $samples->{Account}{a} ] ],
    ],
    'accounts/1/statuses' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json $samples->{Status}{a} ],
    ],
    'accounts/2/statuses' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [] ],
    ],
  },
};

sub call {
  my ($self, $env) = @_;

  my $uri      = $env->{REQUEST_URI};
  my $endpoint = $uri =~ s%^/api/v1/%%r;
  my $return = $routes->{$env->{REQUEST_METHOD}}{$endpoint} //
    [
      404,
      [ 'Content-Type' => 'text/plain' ],
      [ '' ],
    ];

  return $return;
}

1;
