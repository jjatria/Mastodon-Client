package Mastodon::Entity::Error;

our $VERSION = '0';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str );

has error => ( is => 'ro', isa => Str );

1;
