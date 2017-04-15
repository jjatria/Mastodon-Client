package Mastodon::Entity::Instance;

our $VERSION = '0';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str );
use Mastodon::Types qw( URI );

has email       => ( is => 'ro', isa => Str, required => 1 );
has description => ( is => 'ro', isa => Str, required => 1 );
has title       => ( is => 'ro', isa => Str );
has uri         => ( is => 'ro', isa => URI, coerce => 1 );

1;
