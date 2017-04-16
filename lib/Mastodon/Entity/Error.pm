package Mastodon::Entity::Error;

our $VERSION = '0.003';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str );

has error => ( is => 'ro', isa => Str, required => 1 );

1;
