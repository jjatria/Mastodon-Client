package Mastodon::Entity::Mention;

use Moo;

use Types::Standard qw( Str Int );
use Mastodon::Types qw( URI Acct );

has id       => ( is => 'ro', isa => Int );
has url      => ( is => 'ro', isa => URI );
has username => ( is => 'ro', isa => Str );
has acct     => ( is => 'ro', isa => Acct );

1;
