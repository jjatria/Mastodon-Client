package Mastodon::Entity::Report;

use Moo;

use Types::Standard qw( Int Any );

has id           => ( is => 'ro', isa => Int );
has action_taken => ( is => 'ro', isa => Any ); # What is this?

1;
