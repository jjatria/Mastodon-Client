package Mastodon::Entity::Relationship;

use Moo;

use Types::Standard qw( Bool );

has following   => ( is => 'ro', isa => Bool );
has followed_by => ( is => 'ro', isa => Bool );
has blocking    => ( is => 'ro', isa => Bool );
has muting      => ( is => 'ro', isa => Bool );
has requested   => ( is => 'ro', isa => Bool );

1;
