package Mastodon::Entity::Error;

use Moo;

use Types::Standard qw( Str );

has error => ( is => 'ro', isa => Str );

1;
