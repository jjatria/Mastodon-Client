# ABSTRACT: Talk to a Mastodon server
package Mastodon::Client;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '0.002';

use Carp;
use Mastodon::Types qw( Acct Account DateTime Image URI );
use Moo;
use Types::Common::String qw( NonEmptyStr );
use Types::Standard
  qw( Int Str Optional Bool Maybe Undef HashRef ArrayRef Dict slurpy );
use Types::Path::Tiny qw( File );

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

has website => (
  is  => 'ro',
  isa => Str,
  lazy => 1,
  default => '',
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

# Authorize follow requests by account ID
sub authorize_follow {
  my $self = shift;
  state $check = compile( Int );
  my ($id) = $check->(@_);
  return $self->post( 'follow_requests/authorize' => { id => $id } );
}

# Clears notifications
sub clear_notifications {
  my $self = shift;
  state $check = compile();
  $check->(@_);

  return $self->post( 'notifications/clear' );
}

# Delete a status by ID
sub delete_status {
  my $self = shift;

  state $check = compile( Int );
  my ($id) = $check->(@_);

  return $self->delete( "statuses/$id" );
}

sub fetch_instance {
  my $self = shift;
  $self->instance($self->get( 'instance' ));
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

# Get a single notification by ID
sub get_notification {
  my $self = shift;
  state $check = compile( Int );
  my ($id) = $check->(@_);

  return $self->get( "notifications/$id" );
}

# Get a single status by ID
sub get_status {
  my $self = shift;
  state $check = compile( Int );
  my ($id) = $check->(@_);

  return $self->get( "statuses/$id" );
}

# Post a status
sub post_status {
  my $self = shift;
  state $check = compile( Str|HashRef, Optional[HashRef]);
  my ($text, $params) = $check->(@_);
  $params //= {};

  my $payload;
  if (ref $text eq 'HASH') {
    $params = $text;
    croak $log->fatal('Post must contain a (possibly empty) status text')
      unless defined $params->{status};
    $payload = $params;
  }
  else {
    $payload = { status => $text, %{$params} };
  }

  return $self->post( 'statuses', $payload);
}

# Delete a status by ID
sub reblog_status {
  my $self = shift;

  state $check = compile( Int );
  my ($id) = $check->(@_);

  return $self->delete( "statuses/$id/reblog" );
}

sub register {
  my $self = shift;

  if ( $self->client_id && $self->client_secret ) {
    $log->warn('Client is already registered');
    return $self;
  }

  state $check = compile(
    slurpy Dict [
      instance => Instance->plus_coercions( Undef, sub { $self->instance } ),
      redirect_uris =>
        Str->plus_coercions( Undef, sub { $self->redirect_uri } ),
      scopes =>
        ArrayRef->plus_coercions( Undef, sub { $self->scopes } ),
      website => Str->plus_coercions( Undef, sub { $self->website } ),
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

  return $self->get( "accounts/$id/statuses", $params );
}

# Reject follow requsts by account ID
sub reject_follow {
  my $self = shift;
  state $check = compile( Int );
  my ($id) = $check->(@_);
  return $self->post( 'follow_requests/reject' => { id => $id } );
}

# Follow a remote user by acct (username@instance)
sub remote_follow {
  my $self = shift;
  state $check = compile( Acct );
  my ($acct) = $check->(@_);
  return $self->post( 'follows' => { uri => $acct } );
}

# Report a user account or list of statuses
sub report {
  my $self = shift;
  state $check = compile( slurpy Dict[
    account_id => Optional[Int],
    status_ids => Optional[ArrayRef->plus_coercions( Int, sub { [ $_ ] } ) ],
    comment => Optional[Str],
  ]);
  my ($data) = $check->(@_);

  croak $log->fatal('Either account_id or status_ids are required for report')
    unless join(' ', keys(%{$data})) =~ /\b(account_id|status_ids)\b/;

  return $self->post( 'reports' => $data );
}

sub relationships {
  my $self = shift;

  state $check = compile( slurpy ArrayRef [Int|HashRef] );
  my ($ids) = $check->(@_);
  my $params = (ref $ids->[-1] eq 'HASH') ? pop(@{$ids}) : {};

  croak $log->fatal('At least one ID number needed in relationships')
    unless scalar @{$ids};

  $params = {
    id => $ids,
    %{$params},
  };

  return $self->get( "accounts/relationships", $params );
}

sub search {
  my $self = shift;

  state $check = compile( Str, Optional [HashRef] );
  my ($query, $params) = $check->(@_);
  $params //= {};

  $params = {
    'q' => $query,
    %{$params},
  };

  return $self->get( "accounts/search", $params );
}

sub stream {
  my $self = shift;

  state $check = compile(
    slurpy Dict [
      name => NonEmptyStr->plus_coercions( Undef, sub {'user'} ),
      tag  => Maybe [NonEmptyStr],
    ]
  );

  my ($params) = $check->(@_);

  croak $log->fatalf( '"%s" is not a known timeline name"',
    $params->{name} )
    if $params->{name} !~ /(user|public)/;

  my $endpoint
    = $self->instance->uri
    . '/api/v'
    . $self->api_version
    . '/streaming/'
    . (( defined $params->{tag} and $params->{tag} )
        ? ( 'hashtag?' . $params->{tag} )
        : $params->{name}
      );

  use Mastodon::Listener;
  return Mastodon::Listener->new(
    url             => $endpoint,
    access_token    => $self->access_token,
    coerce_entities => $self->coerce_entities,
    ua              => $self->user_agent,
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

sub upload_media {
  my $self = shift;

  state $check = compile(
    File->plus_coercions( Str, sub { Path::Tiny::path($_) } )
  );
  my ($file) = $check->(@_);

  return $self->post( 'media' =>
    { file => [ $file, undef ] },
    headers => { Content_Type => 'form-data' },
  );
}

# POST requests with no data and a mandatory ID number
foreach my $pair ([
    [ statuses => [qw( reblog unreblog favourite unfavourite     )] ],
    [ accounts => [qw( mute unmute block unblock follow unfollow )] ],
  ]) {

  my ($base, $endpoints) = @{$pair};

  foreach my $endpoint (@{$endpoints}) {
    my $method = ($base eq 'statuses') ? $endpoint . '_status' : $endpoint;

    no strict 'refs';
    *{ __PACKAGE__ . "::" . $method } = sub {
      my $self = shift;
      state $check = compile( Int );
      my ($id) = $check->(@_);

      return $self->post( "$base/$id/$endpoint" );
    };
  }
}

# GET requests with no parameters but optional parameter hashref
for my $action (qw(
    blocks favourites follow_requests mutes notifications reports
  )) {

  no strict 'refs';
  *{ __PACKAGE__ . "::" . $action } = sub {
    my $self = shift;
    state $check = compile(Optional [HashRef]);
    my $params = $check->(@_) // {};

    return $self->get( $action, $params );
  };
}

# GET requests with optional ID and parameter hashref
# ID number defaults to authenticated account's ID
for my $action (qw( following followers )) {
  no strict 'refs';
  *{ __PACKAGE__ . "::" . $action } = sub {
    my $self = shift;
    state $check = compile( Optional [Int], Optional [HashRef] );
    my ($id, $params) = $check->(@_);

    $id     //= $self->account->{id};
    $params //= {};

    return $self->get( "accounts/$id/$action", $params );
  };
}

# GET requests for status details
foreach my $pair ([
    [ get_status_context    => 'context'       ],
    [ get_status_card       => 'card'          ],
    [ get_status_reblogs    => 'reblogged_by'  ],
    [ get_status_favourites => 'favourited_by' ],
  ]) {

  my ($method, $endpoint) = @{$pair};

  no strict 'refs';
  *{ __PACKAGE__ . "::" . $method } = sub {
    my $self = shift;
    state $check = compile( Int );
    my ($id) = $check->(@_);

    return $self->get( "statuses/$id/$endpoint" );
  };
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

=head1 METHODS

=over 4

=item B<get($url)>

=item B<get($url, $params)>

Send a GET request to the specified URL and return the deserialised response.
C<$url> can be a L<URI> object or a string with the variable parts of the API
endpoint (ie. not including the C<HOST/api/v1> part).

Query parameters can be passed as part of the URL, or more conveniently as an
additional hash reference, which will be added to the URL before the request
is sent.

=item B<post($url)>

=item B<post($url, $data)>

=item B<patch($url)>

=item B<patch($url, $data)>

Send a POST or PATCH request to the specified URL and return the deserialised
response. C<$url> can be a L<URI> object or a string with the variable parts
of the API endpoint (ie. not including the C<HOST/api/v#> part).

An additional hash reference will be sent as form data.

=back

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
