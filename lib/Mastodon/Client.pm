# ABSTRACT: Talk to a Mastodon server
package Mastodon::Client;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '0.002';

use Carp;
use Mastodon::Types qw( Account DateTime Image URI );
use Moo;
use Types::Common::String qw( NonEmptyStr );
use Types::Standard
  qw( Int Str Optional Bool Maybe Undef HashRef ArrayRef Dict slurpy );

use Log::Any;
my $log = Log::Any->get_logger(category => 'Mastodon');

with 'Mastodon::Role::UserAgent';

has coerce_entities => (
  is   => 'rw',
  isa  => Bool,
  lazy => 1,
  default => 0,
);

has access_token => (
  is   => 'rw',
  isa  => NonEmptyStr,
  lazy => 1,
);

has authorized => (
  is      => 'rw',
  isa     => Maybe [DateTime],
  lazy    => 1,
  default => sub {undef},
  coerce  => 1,
);

has client_id => (
  is   => 'rw',
  isa  => NonEmptyStr,
  lazy => 1,
);

has client_secret => (
  is   => 'rw',
  isa  => NonEmptyStr,
  lazy => 1,
);

has name => (
  is  => 'ro',
  isa => NonEmptyStr,
);

has account => (
  is  => 'rw',
  isa => HashRef|Account,
  init_arg => undef,
  lazy => 1,
  default => sub {
    $_[0]->get_account;
  },
);

has scopes => (
  is      => 'ro',
  isa     => ArrayRef,
  lazy    => 1,
  default => sub { [ 'read' ] },
);

sub authorize {
  my $self = shift;

  unless ( $self->client_id and $self->client_secret ) {
    croak $log->fatal(
      'Cannot authorize client without client_id and client_secret');
  }

  if ( $self->access_token ) {
    $log->warn('Client is already authorised');
    return $self;
  }

  state $check = compile(
    slurpy Dict [
      access_code => Str->plus_coercions( Undef, sub {''} ),
      username  => Str->plus_coercions( Undef, sub {''} ),
      password  => Str->plus_coercions( Undef, sub {''} ),
    ],
  );
  my ($params) = $check->(@_);

  my $data = {
    client_id     => $self->client_id,
    client_secret => $self->client_secret,
    redirect_uri  => $self->redirect_uri,
  };

  if ( $params->{access_code} ) {
    $data->{grant_type} = 'authorization_code';
    $data->{code}       = $params->{access_code};
  }
  else {
    $data->{grant_type} = 'password';
    $data->{username}   = $params->{username};
    $data->{password}   = $params->{password};
  }

  my $response = $self->post( 'oauth/token' => $data );

  if ( defined $response->{error} ) {
    $log->warn( $response->{error_description} );
  }
  else {
    my $granted_scopes   = join ' ', sort split( / /, $response->{scope} );
    my $requested_scopes = join ' ', sort @{ $self->scopes };

    croak $log->fatal('Granted and requested scopes do not match')
      if $granted_scopes ne $requested_scopes;

    $self->access_token( $response->{access_token} );
    $self->authorized( $response->{created_at} );
  }

  return $self;
}

sub get_account {
  my $self = shift;
  state $check = compile( Optional [Str] );
  my ($id) = $check->(@_);
  $id //= 'verify_credentials';

  my $data = $self->get( "accounts/$id" );

  # We fetched authenticated user account's data
  # Update local reference
  $self->account($data) if (scalar @_ == 1);
  return $data;
}

sub follow {
  my $self = shift;
  state $check = compile(Int);
  my ($id) = $check->(@_);
  return $self->post( "accounts/$id/follow" );
}

sub followers {
  my $self = shift;
  state $check = compile( Optional [Int] );
  my ($id) = $check->(@_);
  $id //= $self->account->{id};
  return $self->get( "accounts/$id/followers" );
}

sub following {
  my $self = shift;
  state $check = compile( Optional [Int] );
  my ($id) = $check->(@_);
  $id //= $self->account->{id};
  return $self->get( "accounts/$id/following" );
}

sub register {
  my $self = shift;

  if ( $self->client_id && $self->client_secret ) {
    $log->warn('Client is already registered');
    return $self;
  }

  state $check = compile(
    slurpy Dict [
      instance => URI->plus_coercions( Undef, sub { $self->instance } ),
      redirect_uris =>
        Str->plus_coercions( Undef, sub { $self->redirect_uri } ),
      scopes =>
        ArrayRef->plus_coercions( Undef, sub { $self->scopes } ),
      website => Str->plus_coercions( Undef, sub {''} ),
    ]
  );
  my ($params) = $check->(@_);

  my $response = $self->post(
    apps => {
      client_name   => $self->name,
      redirect_uris => $params->{redirect_uris},
      scopes        => join ' ', sort( @{ $params->{scopes} } ),
    }
  );

  $self->client_id( $response->{client_id} );
  $self->client_secret( $response->{client_secret} );

  return $self;
}

sub statuses {
  my $self = shift;
  state $check = compile( Optional [HashRef|Int], Optional [HashRef]);
  my ($id, $params) = $check->(@_);
  if (ref $id) {
    $params = $id;
    $id = undef;
  }
  $id //= $self->account->{id};
  $params //= {};

  foreach (keys %{$params}) {
    croak $log->fatalf('%s is not a valid parameter for statuses', $_)
      unless /^(exclude_replies|only_media)$/;
  }

  return $self->get( "accounts/$id/statuses", $params );
}

sub stream {
  my $self = shift;

  state $check = compile(
    slurpy Dict [
      name            => NonEmptyStr->plus_coercions( Undef, sub {'user'} ),
      tag             => Maybe [NonEmptyStr],
    ]
  );

  my ($params) = $check->(@_);

  croak $log->fatalf( '"%s" is not a known timeline name"',
    $params->{name} )
    if $params->{name} !~ /(user|public)/;

  my $endpoint
    = $self->instance
    . '/api/v'
    . $self->api_version
    . '/streaming/'
    . (( defined $params->{tag} and $params->{tag} )
        ? ( 'hashtag?' . $params->{tag} )
        : $params->{name}
      );

  use Mastodon::Listener;
  return Mastodon::Listener->new(
    url          => $endpoint,
    access_token => $self->access_token,
    coerce_entities => $self->coerce_entities,
  );
}

sub timeline {
  my $self = shift;

  state $check = compile(
    slurpy Dict [
      name  => NonEmptyStr->plus_coercions( Undef, sub {'home'} ),
      local => Bool->plus_coercions( Undef,    sub {0} ),
      tag   => Maybe [NonEmptyStr],
    ]
  );
  my ($params) = $check->(@_);

  croak $log->fatalf( '"%s" is not a known timeline name"',
    $params->{name} )
    if $params->{name} !~ /(home|public)/;

  my $endpoint
    = ( defined $params->{tag} )
    ? 'timelines/tag/' . $params->{tag}
    : 'timelines/' . $params->{name};
  $endpoint .= '?local' if $params->{local};

  return $self->get($endpoint);
}

sub unfollow {
  my $self = shift;
  state $check = compile(Int);
  my ($id) = $check->(@_);
  return $self->post( "accounts/$id/unfollow" );
}

sub update_account {
  my $self = shift;

  state $check = compile(
    slurpy Dict [
      display_name => Optional [Str],
      note         => Optional [Str],
      avatar       => Optional [Image],
      header       => Optional [Image],
    ]
  );
  my ($data) = $check->(@_);

  return $self->patch( 'accounts/update_credentials' => $data );
}

1;

__END__

=encoding utf8

=head1 NAME

Mastodon::Client - Talk to a Mastodon server

=head1 SYNOPSIS

  use Mastodon::Client;

  my $client = Mastodon::Client->new(
    instance      => 'mastodon.social',
    name          => 'PerlBot',
    client_id     => $client_id,
    client_secret => $client_secret,
    access_token  => $access_token,
  );

  $client->post( statuses => {
    status     => 'Posted to a Mastodon server!',
    visibility => 'public',
  })

  # Streaming interface might change!
  my $listener = $client->stream(
    name            => 'public',
  );
  $listener->on( update => sub {
    my ($listener, $status) = @_;
    printf "%s said: %s\n",
      $status->account->display_name,
      $status->content;
  });
  $listener->start;

=head1 DESCRIPTION

Mastodon::Client lets you talk to a Mastodon server.

This distribution is still in development, and the interface might
change in the future. But changes should mostly be to add convenience
methods for the more common tasks.

The use of the request methods (B<post>, B<get>, etc) is not likely to
change, and as long as you know the endpoints you are reaching, this
should be usable right now.

=head1 AUTHOR

=over 4

=item *

José Joaquín Atria <jjatria@cpan.org>

=item *

Lance Wicks <lancew@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
