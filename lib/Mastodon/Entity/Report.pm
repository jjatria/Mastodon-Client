package Mastodon::Entity::Report;

our $VERSION = '0.004';

use strict;
use warnings;

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Any );

has id           => ( is => 'ro', isa => Int );
has action_taken => ( is => 'ro', isa => Any, required => 1 ); # What is this?

1;
