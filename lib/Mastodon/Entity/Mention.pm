package Mastodon::Entity::Mention;

our $VERSION = '0';

use strict;
use warnings;

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str Int );
use Mastodon::Types qw( URI Acct );

has acct     => ( is => 'ro', isa => Acct, coerce => 1, required => 1 );
has id       => ( is => 'ro', isa => Int );
has url      => ( is => 'ro', isa => URI,  coerce => 1 );
has username => ( is => 'ro', isa => Str, required => 1);

1;
