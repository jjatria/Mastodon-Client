package Mastodon::Entity::Context;

our $VERSION = '0.002';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( ArrayRef );
use Mastodon::Types qw( Status );

has ancestors   => ( is => 'ro', isa => ArrayRef [Status], required => 1 );
has descendants => ( is => 'ro', isa => ArrayRef [Status] );

1;
