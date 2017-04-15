package Mastodon::Role::Entity;

use Moo::Role;

has _client => (
  is => 'rw',
);

1;
