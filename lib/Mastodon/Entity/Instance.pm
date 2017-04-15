package Mastodon::Entity::Instance;

our $VERSION = '0';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str );
use Mastodon::Types qw( URI );

has email       => ( is => 'ro', isa => Str ); # Should be a more specific type
has description => ( is => 'ro', isa => Str );
has title       => ( is => 'ro', isa => Str );
has uri         => ( is => 'ro', isa => URI, coerce => 1 );

1;
