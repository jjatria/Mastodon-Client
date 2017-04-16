package Mastodon::Entity::Notification;

our $VERSION = '0.003';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Enum );
use Mastodon::Types qw( Status URI DateTime Account Acct );

has account    => ( is => 'ro', isa => Account );
has created_at => ( is => 'ro', isa => DateTime );
has id         => ( is => 'ro', isa => Int );
has status     => ( is => 'ro', isa => Status, required => 1, coerce => 1 );
has type       => ( is => 'ro', isa => Enum[qw(
  mention reblog favourite follow
)] );

1;
