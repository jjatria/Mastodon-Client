package Mastodon::Entity::Attachment;

use Moo;

use Types::Standard qw( Maybe Enum Int Str Bool );
use Mastodon::Types qw( Acct URI );

has id          => ( is => 'ro', isa => Int );
has type        => ( is => 'ro', isa => Enum[qw( image video gifv )] );
has url         => ( is => 'ro', isa => URI, coerce => 1 );
has remote_url  => ( is => 'ro', isa => URI, coerce => 1 );
has preview_url => ( is => 'ro', isa => URI, coerce => 1 );
has text_url    => ( is => 'ro', isa => Maybe[URI], coerce => 1 );

1;
