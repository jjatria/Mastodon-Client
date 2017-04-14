package Mastodon::Entity::Results;

use Moo;

use Types::Standard qw( ArrayRef );
use Mastodon::Types qw( Account Status );

has accounts => ( is => 'ro', isa => ArrayRef[Account] );
has statuses => ( is => 'ro', isa => ArrayRef[Status] );
has hashtags => ( is => 'ro', isa => ArrayRef[Str] );

1;
