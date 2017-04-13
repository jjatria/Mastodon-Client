package Mastodon::Entity::Attachment;

use Moo;

use Types::Standard qw( Int Str Bool );
use Mastodon::Types qw( Acct URI DateTime );

has id          => ( is => 'ro', isa => Int );
has type        => ( is => 'ro', isa => Enum[qw( image video gifv )] );
has url         => ( is => 'ro', isa => URI );
has remote_url  => ( is => 'ro', isa => URI );
has preview_url => ( is => 'ro', isa => URI );
has text_url    => ( is => 'ro', isa => Maybe[URI] );

1;
