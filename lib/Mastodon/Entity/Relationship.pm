package Mastodon::Entity::Relationship;

our $VERSION = '0.007';

use strict;
use warnings;

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Bool );

has id          => ( is => 'ro', isa => Int );
has blocking    => ( is => 'ro', isa => Bool );
has followed_by => ( is => 'ro', isa => Bool );
has following   => ( is => 'ro', isa => Bool );
has muting      => ( is => 'ro', isa => Bool, required => 1 );
has requested   => ( is => 'ro', isa => Bool );

1;
