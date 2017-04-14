package Mastodon::Entity::Mention;

our $VERSION = '0';

use Moo;
use Types::Standard qw( Str Int );
use Mastodon::Types qw( URI Acct );

has acct     => ( is => 'ro', isa => Acct, coerce => 1 );
has id       => ( is => 'ro', isa => Int );
has url      => ( is => 'ro', isa => URI,  coerce => 1 );
has username => ( is => 'ro', isa => Str );

1;
