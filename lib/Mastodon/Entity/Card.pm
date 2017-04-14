package Mastodon::Entity::Card;

our $VERSION = '0';

use Moo;
use Types::Standard qw( Any Str );
use Mastodon::Types qw( URI );

has description => ( is => 'ro', isa => Str );
has image       => ( is => 'ro', isa => Any ); # What type of data is this?
has title       => ( is => 'ro', isa => Str );
has url         => ( is => 'ro', isa => URI, coerce => 1);

1;
