package Mastodon::Entity::Context;

use Moo;

use Types::Standard qw( ArrayRef );
use Mastodon::Types qw( Status );

has ancestors   => ( is => 'ro', isa => ArrayRef[Status] );
has descendants => ( is => 'ro', isa => ArrayRef[Status] );

1;
