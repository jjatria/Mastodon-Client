package Mastodon::Entity::Status;

our $VERSION = '0.007';

use strict;
use warnings;

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Maybe Int Str Bool ArrayRef Enum );
use Mastodon::Types qw(
  URI Account Status DateTime Attachment Mention Tag Application
);

use Log::Any;
my $log = Log::Any->get_logger( category => 'Mastodon' );

has account => (
  is => 'ro', isa => Account, coerce => 1, required => 1
);

has application => (
  is => 'ro', isa => Maybe [Application], coerce => 1
);

has content => (
  is => 'ro', isa => Str
);

has created_at => (
  is => 'ro', isa => DateTime, coerce => 1
);

has favourited => (
  is => 'ro', isa => Bool
);

has favourites_count => (
  is => 'ro', isa => Int, required => 1
);

has id => (
  is => 'ro', isa => Int
);

has in_reply_to_account_id => (
  is => 'ro', isa => Maybe [Int]
);

has in_reply_to_id => (
  is => 'ro', isa => Maybe [Int]
);

has media_attachments => (
  is => 'ro', isa => ArrayRef [Attachment], coerce => 1
);

has mentions => (
  is => 'ro', isa => ArrayRef [Mention], coerce => 1
);

has reblog => (
  is => 'ro', isa => Maybe [Status], coerce => 1
);

has reblogged => (
  is => 'ro', isa => Bool
);

has reblogs_count => (
  is => 'ro', isa => Int
);

has sensitive => (
  is => 'ro', isa => Bool
);

has spoiler_text => (
  is => 'ro', isa => Str
);

has tags => (
  is => 'ro', isa => ArrayRef [Tag], coerce => 1
);

has uri => (
  is => 'ro', isa => Str
);

has url => (
  is => 'ro', isa => URI, coerce => 1
);

has visibility => (
  is => 'ro', isa => Enum[qw(
    public unlisted private direct
  )],
  required => 1,
);

foreach my $pair (
    [ fetch            => 'get_status' ],
    [ fetch_context    => 'get_status_context' ],
    [ fetch_card       => 'get_status_card' ],
    [ fetch_reblogs    => 'get_status_reblogs' ],
    [ fetch_favourites => 'get_status_favourites' ],
    [ delete           => 'delete_status' ],
    [ boost            => 'reblog' ],
    [ unboost          => 'unreblog' ],
    [ favourite        => undef ],
    [ unfavourite      => undef ],
  ) {

  my ($name, $method) = @{$pair};
  $method //= $name;
#
  no strict 'refs';
  *{ __PACKAGE__ . "::" . $name } = sub {
    my $self = shift;
    croak $log->fatal("Cannot call '$name' without client")
      unless $self->_client;
    $self->_client->$method($self->id, @_);
  };
}


1;
