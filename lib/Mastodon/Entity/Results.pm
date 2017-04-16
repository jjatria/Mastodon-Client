package Mastodon::Entity::Results;

our $VERSION = '0';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str ArrayRef );
use Mastodon::Types qw( Account Status );

has accounts => ( is => 'ro', isa => ArrayRef [Account] );
has hashtags => ( is => 'ro', isa => ArrayRef [Str], required => 1 ); # Not Tag!
has statuses => ( is => 'ro', isa => ArrayRef [Status] );

1;
