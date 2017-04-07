package Mastodon::Role::UserAgent;

use v5.10.0;
use Moo::Role;

use Log::Any qw( $log );

use Types::Standard qw( Bool Undef Str Num ArrayRef HashRef Dict slurpy );
use Mastodon::Types qw( UserAgent );
use Type::Params qw( compile );

has instance => (
  is => 'ro',
  isa => Str,
  default => 'https://mastodon.cloud',
);

has api_version => (
  is => 'ro',
  isa => Num,
  default => 1,
);

has autorization_url => (
  is => 'ro',
  isa => Str,
  init_arg => undef,
  lazy => 1,
  default => sub { ... },
);

has user_agent => (
  is => 'ro',
  isa => UserAgent,
  default => sub {
    require LWP::UserAgent;
    return LWP::UserAgent->new;
  },
);

sub get  { shift->_request( get  => @_ ) }

sub post { shift->_request( post => @_ ) }

sub _request {
  my $self = shift;

  state $check = compile( Str, Str,
    slurpy Dict[
      params  => HashRef->plus_coercions(
        Undef, sub { {} }
      ),
      headers => ArrayRef->plus_coercions(
        HashRef, sub { %{$_} },
        Undef,   sub { [] },
      ),
      data => ArrayRef->plus_coercions(
        HashRef, sub { [%{$_}] },
        Undef,   sub { [] },
      ),
    ],
  );
  my ($method, $url, $params) = $check->(@_);
  $method = lc($method);

  use URI;
  use URI::QueryParam;
  my $uri = URI->new(join '/', $self->instance, 'api', 'v' . $self->api_version, $url);
  $uri->query_param(%{$params->{params}});

  my @fields = (
#     Authorization => 'Bearer ' . $self->access_token,
    @{$params->{headers}},
  );
  $log->trace(uc($method), $uri, "\n", @fields);
  if ($method =~ /(put|post)/ and scalar @{$params->{data}}) {
    push @fields, 'Content';
    push @fields, $params->{data};
  }

  return $self->user_agent->$method( $uri, @fields );
}

1;
