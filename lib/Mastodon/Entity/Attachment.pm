package Mastodon::Entity::Attachment;

our $VERSION = '0.002';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Maybe Enum Int Str Bool );
use Mastodon::Types qw( Acct URI );

has id          => ( is => 'ro', isa => Int );
has preview_url => ( is => 'ro', isa => URI,         coerce => 1, required => 1 );
has remote_url  => ( is => 'ro', isa => URI,         coerce => 1 );
has text_url    => ( is => 'ro', isa => Maybe [URI], coerce => 1 );
has url         => ( is => 'ro', isa => URI,         coerce => 1 );
has type        => ( is => 'ro', isa => Enum[qw( image video gifv )] );

1;
