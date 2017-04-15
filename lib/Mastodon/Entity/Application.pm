package Mastodon::Entity::Application;

our $VERSION = '0';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str );
use Mastodon::Types qw( URI );

has name     => ( is => 'ro', isa => Str );
has website  => ( is => 'ro', isa => URI, coerce => 1);

1;
