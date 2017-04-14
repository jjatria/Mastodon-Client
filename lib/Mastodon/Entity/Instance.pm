package Mastodon::Entity::Instance;

use Moo;

use Types::Standard qw( Str );
use Mastodon::Types qw( URI );

has uri         => ( is => 'ro', isa => URI, coerce => 1 );
has title       => ( is => 'ro', isa => Str );
has description => ( is => 'ro', isa => Str );
has email       => ( is => 'ro', isa => Str ); # Should be a more specific type

1;
