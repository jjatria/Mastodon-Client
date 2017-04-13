package Mastodon::Entity::Status;

use Moo;

use Types::Standard qw( Maybe Int Str Bool ArrayRef Enum );
use Mastodon::Types qw(
  URI Account Status DateTime Attachment Mention Tag Application
);

has id                     => ( is => 'ro', isa => Int );
has uri                    => ( is => 'ro', isa => URI );
has url                    => ( is => 'ro', isa => URI );
has account                => ( is => 'ro', isa => Account );
has in_reply_to_id         => ( is => 'ro', isa => Maybe[Int] );
has in_reply_to_account_id => ( is => 'ro', isa => Maybe[Int] );
has reblog                 => ( is => 'ro', isa => Maybe[Status] );
has content                => ( is => 'ro', isa => Str );
has created_at             => ( is => 'ro', isa => DateTime );
has reblogs_count          => ( is => 'ro', isa => Int );
has favourites_count       => ( is => 'ro', isa => Int );
has reblogged              => ( is => 'ro', isa => Bool );
has favourited             => ( is => 'ro', isa => Bool );
has sensitive              => ( is => 'ro', isa => Bool );
has spoiler_text           => ( is => 'ro', isa => Str );
has media_attachments      => ( is => 'ro', isa => ArrayRef[Attachment] );
has mentions               => ( is => 'ro', isa => ArrayRef[Mention] );
has tags                   => ( is => 'ro', isa => ArrayRef[Tag] );
has application            => ( is => 'ro', isa => Application );
has visibility             => ( is => 'ro', isa => Enum[qw(
  public unlisted private direct
)] );

1;
