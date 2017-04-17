package Mastodon::Entity::Account;

our $VERSION = '0.004';

use strict;
use warnings;

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Str Bool );
use Mastodon::Types qw( Acct URI DateTime );

has acct            => ( is => 'ro', isa => Acct, required => 1 );
has avatar          => ( is => 'ro', isa => URI, coerce => 1, required => 1 );
has avatar_static   => ( is => 'ro', isa => URI, coerce => 1 );
has created_at      => ( is => 'ro', isa => DateTime, coerce => 1 );
has display_name    => ( is => 'ro', isa => Str );
has followers_count => ( is => 'ro', isa => Int );
has following_count => ( is => 'ro', isa => Int );
has header          => ( is => 'ro', isa => URI, coerce => 1 );
has header_static   => ( is => 'ro', isa => URI, coerce => 1 );
has id              => ( is => 'ro', isa => Int );
has locked          => ( is => 'ro', isa => Bool );
has note            => ( is => 'ro', isa => Str );
has statuses_count  => ( is => 'ro', isa => Int );
has url             => ( is => 'ro', isa => URI, coerce => 1 );
has username        => ( is => 'ro', isa => Str );

1;
