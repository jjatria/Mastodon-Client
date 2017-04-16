package Mastodon::Entity::Application;

our $VERSION = '0.002';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str );
use Mastodon::Types qw( URI );

has name     => ( is => 'ro', isa => Str, required => 1 );
has website  => ( is => 'ro', isa => Maybe[URI], coerce => 1);

1;
