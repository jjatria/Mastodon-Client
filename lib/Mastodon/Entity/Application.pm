package Mastodon::Entity::Application;

use Moo;

use Types::Standard qw( Str );
use Mastodon::Types qw( URI );

has name     => ( is => 'ro', isa => Str );
has website  => ( is => 'ro', isa => URI );

1;
