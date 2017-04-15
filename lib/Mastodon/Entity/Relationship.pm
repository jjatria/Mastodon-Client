package Mastodon::Entity::Relationship;

our $VERSION = '0';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Bool );

has blocking    => ( is => 'ro', isa => Bool );
has followed_by => ( is => 'ro', isa => Bool );
has following   => ( is => 'ro', isa => Bool );
has muting      => ( is => 'ro', isa => Bool );
has requested   => ( is => 'ro', isa => Bool );

1;
