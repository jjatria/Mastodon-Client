package Mastodon::Entity::Instance;

our $VERSION = '0.005';

use strict;
use warnings;

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Bool Str );
use Mastodon::Types qw( URI );

has email       => ( is => 'ro', isa => Str );
has description => ( is => 'ro', isa => Str );
has title       => ( is => 'ro', isa => Str );
has uri         => ( is => 'ro', isa => URI, coerce => 1, required => 1 );

1;
