package Mastodon;

use v5.10.0;
use Moo;

use Log::Any qw ( $log );

use Types::Standard qw(
  Bool Undef Str Num ArrayRef HashRef Dict slurpy
);
use Mastodon::Types qw( Client );
use Type::Params qw( compile );

with 'Mastodon::Role::UserAgent';

has clients => (
  is => 'ro',
  isa => HashRef[Client],
  init_arg => undef,
  lazy => 1,
  default => sub { {} },
);

sub create_client {
  my $self = shift;

  use Try::Tiny;
  require JSON;

  state $check = compile( Str,
    slurpy Dict[
      redirect_uris => Str->plus_coercions(
        Undef, sub { 'urn:ietf:wg:oauth:2.0:oob' }
      ),
      scopes => ArrayRef->plus_coercions(
        Undef, sub { [qw( read write follow )] }
      ),
      website => Str->plus_coercions(
        Undef, sub { '' }
      ),
      to_file => Bool->plus_coercions(
        Undef, sub { 0 }
      ),
    ],
  );
  my ($client_name, $opt) = $check->(@_);

  my $data = {
    client_name   => $client_name,
    redirect_uris => $opt->{redirect_uris},
    scopes        => join ' ', @{$opt->{scopes}},
  };

  my $response;
  try {
    my $resp = $self->post('apps', data => $data );
    $resp->is_success or die $resp->status_line;
    $response = JSON::decode_json $resp->content;
  }
  catch {
    die 'Could not complete request: ', $_;
  };

  require Mastodon::Client;
  $self->clients->{$client_name} = Mastodon::Client->new(
    id     => $response->{client_id},
    secret => $response->{client_secret}
  );

  return $self->clients->{$client_name};
}

# Returns a stream listener
sub stream { ... }

# Sets/Gets the client's authentication tokens
sub auth { ... }

1;
