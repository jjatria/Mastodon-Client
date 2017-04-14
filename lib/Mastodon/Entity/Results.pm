package Mastodon::Entity::Results;

our $VERSION = '0';

use Moo;
use Types::Standard qw( ArrayRef );
use Mastodon::Types qw( Account Status );

has accounts => ( is => 'ro', isa => ArrayRef [Account] );
has hashtags => ( is => 'ro', isa => ArrayRef [Str] );      # Not Tag objects!
has statuses => ( is => 'ro', isa => ArrayRef [Status] );

1;
