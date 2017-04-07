package Mastodon::App;

use v5.10.0;
use Moo;
use Types::Standard qw( Str Maybe Undef ArrayRef Dict slurpy );
use Types::Path::Tiny qw( Path );

with 'Mastodon::Role::UserAgent';

has name => (
  is => 'ro',
  isa => Str,
  lazy => 1,
);

has id => (
  is => 'ro',
  isa => Str,
  lazy => 1,
);

has client_id => (
  is => 'ro',
  isa => Str,
  lazy => 1,
);

has client_secret => (
  is => 'ro',
  isa => Str,
  lazy => 1,
);

has access_token => (
  is => 'ro',
  isa => Str,
  lazy => 1,
);

sub log_in {
  my $self = shift;

  state $check = compile(
    slurpy Dict[
      client_id => Str->plus_coercions(
        Undef, sub { $self->client_id },
      ),
      client_secret => Str->plus_coercions(
        Undef, sub { $self->client_secret },
      ),
      username => Maybe[Str],
      password => Maybe[Str],
      scopes => ArrayRef->plus_coercions(
        Undef, sub { [qw( read write follow )] }
      ),
      grant_type => Str->plus_coercions(
        Undef, sub { 'password' }
      ),
    ],
  );
  my ($opt) = $check->(@_);
  $opt->{scopes} = [ sort @{$opt->{scopes}} ];
  my $requested_scopes = join ' ', @{$opt->{scopes}};

  my $params = {
    grant_type => $opt->{grant_type},
    scope => $requested_scopes,
    client_id => $opt->{client_id},
    client_secret => $opt->{client_secret},
  };
  if (defined $opt->{username} and defined $opt->{password}) {
    $params->{username} = $opt->{username};
    $params->{password} = $opt->{password};
  }

  my $response;
  try {
    my $resp = $self->post('oauth/token', params => $params );
    $resp->is_success or die $resp->status_line;
    $response = JSON::decode_json $resp->content;
    $self->access_token($response->{access_token});
  }
  catch {
    die 'Invalid user name and password: ', $_;
  };

  $response->{scope} = [ sort @{$response->{scope}} ];
  my $granted_scopes = join ' ', @{$response->{scope}};

  if ($requested_scopes ne $granted_scopes) {
    die "Granted scopes '$granted_scopes' differ from requested scopes '$requested_scopes'";
  }

#   if to_file != None:
#       with open(to_file, 'w') as token_file:
#           token_file.write(response['access_token'] + '\n')

  return $self->access_token;
}

sub save {
  my $self = shift;

  use Path::Tiny qw( cwd path );
  state $check = compile(
    Path->plus_coercions(
      Str, sub { path( $_ ) },
      Undef, sub { cwd->child( $self->name . '.ini' ) },
    ),
  );
  my ($path) = $check->(@_);

  use Config::Tiny;
  my $config = Config::Tiny->new;
  $config->{$self->name} = {
    id            => $self->id,
    name          => $self->name,
    client_id     => $self->client_id,
    client_secret => $self->client_secret,
  };

  return $config->write( $path, 'utf8' );
}

1;
