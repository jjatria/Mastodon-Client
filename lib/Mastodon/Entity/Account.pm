package Mastodon::Entity::Account;

our $VERSION = '0.007';

use strict;
use warnings;

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Str Bool );
use Mastodon::Types qw( Acct URI DateTime );

use Log::Any;
my $log = Log::Any->get_logger( category => 'Mastodon' );

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

foreach my $pair (
    [ fetch        => 'get_account' ],
    [ followers    => undef ],
    [ following    => undef ],
    [ statuses     => undef ],
    [ follow       => undef ],
    [ unfollow     => undef ],
    [ block        => undef ],
    [ unblock      => undef ],
    [ mute         => undef ],
    [ unmute       => undef ],
    [ relationship => 'relationships' ],
    [ authorize    => 'authorize_follow' ],
    [ reject       => 'reject_follow' ],
  ) {

  my ($name, $method) = @{$pair};
  $method //= $name;

  no strict 'refs';
  *{ __PACKAGE__ . "::" . $name } = sub {
    my $self = shift;
    croak $log->fatal("Cannot call '$name' without client")
      unless $self->_client;
    $self->_client->$method($self->id, @_);
  };
}

sub remote_follow {
  my $self = shift;
  croak $log->fatal("Cannot call 'remote_follow' without client")
    unless $self->_client;
  $self->_client->remote_follow($self->acct, @_);
}

sub report {
  my ($self, $params) = @_;
  croak $log->fatal("Cannot call 'report' without client")
    unless $self->_client;
  $self->_client->report({
    %{$params},
    account_id => $self->id,
  });
}

1;
