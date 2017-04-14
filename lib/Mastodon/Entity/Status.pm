package Mastodon::Entity::Status;

use Moo;

use Types::Standard qw( Maybe Int Str Bool ArrayRef Enum );
use Mastodon::Types qw(
  URI Account Status DateTime Attachment Mention Tag Application
);

has id                     => ( is => 'ro', isa => Int );
has uri                    => ( is => 'ro', isa => URI, coerce => 1 );
has url                    => ( is => 'ro', isa => URI, coerce => 1 );
has account                => ( is => 'ro', isa => Account, coerce => 1 );
has in_reply_to_id         => ( is => 'ro', isa => Maybe[Int] );
has in_reply_to_account_id => ( is => 'ro', isa => Maybe[Int] );
has reblog                 => ( is => 'ro', isa => Maybe[Status], coerce => 1 );
has content                => ( is => 'ro', isa => Str );
has created_at             => ( is => 'ro', isa => DateTime, coerce => 1 );
has reblogs_count          => ( is => 'ro', isa => Int );
has favourites_count       => ( is => 'ro', isa => Int );
has reblogged              => ( is => 'ro', isa => Bool );
has favourited             => ( is => 'ro', isa => Bool );
has sensitive              => ( is => 'ro', isa => Bool );
has spoiler_text           => ( is => 'ro', isa => Str );
has media_attachments      => ( is => 'ro', isa => ArrayRef[Attachment], coerce => 1 );
has mentions               => ( is => 'ro', isa => ArrayRef[Mention], coerce => 1 );
has tags                   => ( is => 'ro', isa => ArrayRef[Tag], coerce => 1 );
has application            => ( is => 'ro', isa => Maybe[Application], coerce => 1 );
has visibility             => ( is => 'ro', isa => Enum[qw(
  public unlisted private direct
)] );

1;
