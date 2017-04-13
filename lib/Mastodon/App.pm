# ABSTRACT: An app for the Mastodon platform
package Mastodon::App;

our $VERSION = '0.001';

use v5.10.0;
use Moo;

use Types::Standard qw( Str Optional Bool Maybe Undef HashRef ArrayRef Dict slurpy );
use Types::Common::String qw( NonEmptyStr );
use Mastodon::Types qw( DateTime Image URI );

use Carp;

use Log::Any qw( $log );
with 'Mastodon::Role::UserAgent';

has name => (
  is => 'ro',
  isa => NonEmptyStr,
);

has client_id => (
  is => 'rw',
  isa => NonEmptyStr,
  lazy => 1,
);

has client_secret => (
  is => 'rw',
  isa => NonEmptyStr,
  lazy => 1,
);

has access_token => (
  is => 'rw',
  isa => NonEmptyStr,
  lazy => 1,
);

has authorized => (
  is => 'rw',
  isa => Maybe[DateTime],
  lazy => 1,
  default => sub { undef },
  coerce => 1,
);

has scopes => (
  is => 'ro',
  isa => ArrayRef,
  lazy => 1,
  default => sub { [qw( read write follow )] },
);

sub get_account {
  my $self = shift;
  state $check = compile( Optional[Str] );
  my ($id) = $check->(@_);
  $id //= 'verify_credentials';

  return $self->get("accounts/$id");

}

sub update_account {
  my $self = shift;

  state $check = compile( slurpy Dict[
    display_name => Optional[Str],
    note => Optional[Str],
    avatar => Optional[Image],
    header => Optional[Image],
  ]);
  my ($data) = $check->(@_);

  return $self->patch('accounts/update_credentials', data => $data);
}

sub stream {
  my $self = shift;

  state $check = compile( slurpy Dict[
      name  => NonEmptyStr->plus_coercions( Undef, sub { 'user' } ),
      tag   => Maybe[NonEmptyStr],
    ]
  );
  my ($params) = $check->(@_);

  croak $log->fatalf('"%s" is not a known timeline name"', $params->{name})
    if $params->{name} !~ /(user|public)/;

  my $endpoint = $self->instance
    . '/api/v' . $self->api_version
    . '/streaming/'
    . ((defined $params->{tag} and $params->{tag})
      ? ('hashtag?' . $params->{tag})
      : $params->{name});

  use Mastodon::Listener;
  return Mastodon::Listener->new(
    url => $endpoint,
    access_token => $self->access_token,
  );
}

sub timeline {
  my $self = shift;

  state $check = compile( slurpy Dict[
      name  => NonEmptyStr->plus_coercions( Undef, sub { 'home' } ),
      local => Bool->plus_coercions( Undef, sub { 0 } ),
      tag   => Maybe[NonEmptyStr],
    ]
  );
  my ($params) = $check->(@_);

  croak $log->fatalf('"%s" is not a known timeline name"', $params->{name})
    if $params->{name} !~ /(home|public)/;

  my $endpoint = (defined $params->{tag})
    ? 'timelines/tag/' . $params->{tag}
    : 'timelines/'     . $params->{name};
  $endpoint .= '?local' if $params->{local};

  return $self->get($endpoint);
}

sub register {
  my $self = shift;

  if ($self->client_id && $self->client_secret) {
    $log->warn('App is already registered');
    return $self;
  }

  state $check = compile( slurpy Dict[
    instance      => URI->plus_coercions( Undef, sub { $self->instance } ),
    redirect_uris => Str->plus_coercions( Undef, sub { $self->redirect_uri } ),
    scopes        => ArrayRef->plus_coercions( Undef, sub { $self->scopes } ),
    website       => Str->plus_coercions( Undef, sub { '' } ),
  ]);
  my ($params) = $check->(@_);

  my $data = {
    client_name   => $self->name,
    redirect_uris => $params->{redirect_uris},
    scopes        => join ' ', sort(@{$params->{scopes}}),
  };

  my $response = $self->post( 'apps', data => $data );

  $self->client_id($response->{client_id});
  $self->client_secret($response->{client_secret});

  return $self;
}

sub authorize {
  my $self = shift;

  unless ($self->client_id and $self->client_secret) {
    croak $log->fatal(
      'Cannot authorize APP without client_id and client_secret'
    );
  }

  if ($self->access_token) {
    $log->warn('App is already authorised');
    return $self;
  }

  state $check = compile(
    slurpy Dict[
      access_code => Str->plus_coercions( Undef, sub { '' } ),
      username => Str->plus_coercions( Undef, sub { '' } ),
      password => Str->plus_coercions( Undef, sub { '' } ),
    ],
  );
  my ($params) = $check->(@_);

  my $data = {
    client_id => $self->client_id,
    client_secret => $self->client_secret,
    redirect_uri => $self->redirect_uri,
  };

  if ($params->{access_code}) {
    $data->{grant_type} = 'authorization_code';
    $data->{code} = $params->{access_code};
  }
  else {
    $data->{grant_type} = 'password';
    $data->{username} = $params->{username};
    $data->{password} = $params->{password};
  }

  my $response = $self->post('oauth/token', data => $data );

  if (defined $response->{error}) {
    $log->warn($response->{error_description});
  }
  else {
    my $granted_scopes = join ' ', sort split(/ /, $response->{scope});
    my $requested_scopes = join ' ', sort @{$self->scopes};

    croak $log->fatal('Granted and requested scopes do not match')
      if $granted_scopes ne $requested_scopes;

    $self->access_token($response->{access_token});
    $self->authorized($response->{created_at});
  }

  return $self;
}

1;
