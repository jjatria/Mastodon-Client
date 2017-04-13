package Mastodon::Entity::Notification;

use Moo;

use Types::Standard qw( Int Enum );
use Mastodon::Types qw( URI DateTime Account Acct );

has id         => ( is => 'ro', isa => Int );
has type       => ( is => 'ro', isa => Enum[qw( mention reblog favourite follow )] );
has created_at => ( is => 'ro', isa => DateTime );
has account    => ( is => 'ro', isa => Account );
has status     => ( is => 'ro', isa => Status );

1;
