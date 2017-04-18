package Mastodon::Entity::Card;

our $VERSION = '0.006';

use strict;
use warnings;

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Any Str );
use Mastodon::Types qw( URI );

has description => ( is => 'ro', isa => Str, required => 1 );
has image       => ( is => 'ro', isa => Any ); # What type of data is this?
has title       => ( is => 'ro', isa => Str );
has url         => ( is => 'ro', isa => URI, coerce => 1, required => 1);

1;
