package Mastodon::Role::Entity;

our $VERSION = '0.002';

use Moo::Role;

has _client => (
  is => 'rw',
);

1;
