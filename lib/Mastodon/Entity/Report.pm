package Mastodon::Entity::Report;

our $VERSION = '0.007';

use strict;
use warnings;

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Bool );

has id           => ( is => 'ro', isa => Int );
has action_taken => ( is => 'ro', isa => Bool, required => 1 );

1;
