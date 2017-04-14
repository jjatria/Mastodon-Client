package Mastodon::Entity::Card;

use Moo;

use Types::Standard qw( Any Str );
use Mastodon::Types qw( URI );

has url         => ( is => 'ro', isa => URI, coerce => 1);
has title       => ( is => 'ro', isa => Str );
has description => ( is => 'ro', isa => Str );
has image       => ( is => 'ro', isa => Any ); # What is this?

1;
