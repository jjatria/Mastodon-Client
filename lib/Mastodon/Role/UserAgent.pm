package Mastodon::Role::UserAgent;

our $VERSION = '';

use v5.10.0;
use Moo::Role;

use Log::Any qw( $log );

use Types::Standard qw( Undef Str Num ArrayRef HashRef Dict slurpy );
use Mastodon::Types qw( URI UserAgent );
use Type::Params qw( compile );
use Carp;

has instance => (
  is => 'ro',
  isa => URI,
  default => 'https://mastodon.social',
  coerce => 1,
);

has api_version => (
  is => 'ro',
  isa => Num,
  default => 1,
);

has redirect_uri => (
  is => 'ro',
  isa => Str,
  lazy => 1,
  default => 'urn:ietf:wg:oauth:2.0:oob',
);

has user_agent => (
  is => 'ro',
  isa => UserAgent,
  default => sub {
    require LWP::UserAgent;
    LWP::UserAgent->new;
  },
);

sub authorization_url {
  my $self = shift;

  unless ($self->client_id and $self->client_secret) {
    croak $log->fatal(
      'Cannot get authorization URL without client_id and client_secret'
    );
  }

  state $check = compile( slurpy Dict[
    instance => URI->plus_coercions( Undef, sub { $self->instance } ),
  ]);

  use URI::QueryParam;
  my ($params) = $check->(@_);
  my $uri = URI->new('/oauth/authorize')->abs($params->{instance});
  $uri->query_param(redirect_uri => $self->redirect_uri);
  $uri->query_param(response_type => 'code');
  $uri->query_param(client_id => $self->client_id);
  return $uri;
}

sub _build_url {
  my $self = shift;

  state $check = compile(
    URI->plus_coercions(
      Str, sub {
        s%(^/|/$)%%g;
        require URI;
        my $api = (m%^/?oauth/%) ? '' : 'api/v' . $self->api_version . '/';
        URI->new(join '/', $self->instance, $api . $_);
      },
    )
  );

  my ($url) = $check->(@_);
  return $url;
}

sub get   { shift->_request( get   => @_ ) }
sub post  { shift->_request( post  => @_ ) }
sub patch { shift->_request( patch => @_ ) }

sub _request {
  my $self = shift;

  state $check = compile( Str,
    URI->plus_coercions( Str, sub { $self->_build_url($_) } ),
    slurpy Dict[
      params  => HashRef->plus_coercions(
        Undef, sub { {} }
      ),
      headers => HashRef->plus_coercions(
        ArrayRef, sub { { @{$_} } },
        Undef,    sub { {} },
      ),
      data => HashRef->plus_coercions(
        ArrayRef, sub { {@{$_}} },
        Undef,   sub { [] },
      ),
    ],
  );
  my ($method, $target, $params) = $check->(@_);
  $method = uc($method);

  if ($self->can('access_token') and $self->access_token) {
    $params->{headers} = {
      Authorization => 'Bearer ' . $self->access_token,
      %{$params->{headers}},
    };
  }

  # $log->debugf('Method: %s', $method);
  # $log->debugf('Target: %s', $target);
  # $log->debugf('Params: %s', Dumper($params));

  use Encode qw( encode );
  use Try::Tiny;

  return try {
    my @args = $target;
    push @args, [%{$params->{data}}] unless $method eq 'GET';
    @args = (@args, %{$params->{headers}});

    require HTTP::Request::Common;
    my $type = ($method eq 'PATCH') ? 'POST' : $method;
    my $request = HTTP::Request::Common->can($type)->( @args );
    $request->method($method);

    my $response = $self->user_agent->request( $request );

    require JSON;
    my $data = JSON::decode_json( encode('utf8', $response->decoded_content) );
    die $data->{error} if defined $data->{error};
    die $response->status_line unless $response->is_success;

    return $data;
  }
  catch {
    croak $log->fatalf('Could not complete request: %s', $_);
  };
}

1;
