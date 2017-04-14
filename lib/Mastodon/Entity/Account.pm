package Mastodon::Entity::Account;

use Moo;

use Types::Standard qw( Int Str Bool );
use Mastodon::Types qw( Acct URI DateTime );

has id              => ( is => 'ro', isa => Int );
has acct            => ( is => 'ro', isa => Acct );
has avatar          => ( is => 'ro', isa => URI, coerce => 1 );
has header          => ( is => 'ro', isa => URI, coerce => 1 );
has created_at      => ( is => 'ro', isa => DateTime, coerce => 1 );
has display_name    => ( is => 'ro', isa => Str );
has followers_count => ( is => 'ro', isa => Int );
has following_count => ( is => 'ro', isa => Int );
has locked          => ( is => 'ro', isa => Bool );
has note            => ( is => 'ro', isa => Str );
has statuses_count  => ( is => 'ro', isa => Int );
has url             => ( is => 'ro', isa => URI, coerce => 1 );
has username        => ( is => 'ro', isa => Str );

1;
