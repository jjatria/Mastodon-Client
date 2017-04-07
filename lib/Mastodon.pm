package Mastodon;

use v5.10.0;
use Moo;

use Log::Any qw ( $log );

use Types::Standard qw(
  Bool Undef Str Maybe Num ArrayRef HashRef Dict slurpy
);
use Types::Path::Tiny qw( Path File );
use Mastodon::Types qw( App );
use Type::Params qw( compile );
use Path::Tiny qw( cwd path );

with 'Mastodon::Role::UserAgent';

has apps => (
  is => 'ro',
  isa => HashRef[App],
  init_arg => undef,
  lazy => 1,
  default => sub { {} },
);

sub create_app {
  my $self = shift;

  use Try::Tiny;
  require JSON;
  use Encode qw( encode );

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
      to_file => Bool|Path->plus_coercions(
        Str, sub { path($_) },
        Undef, sub { 0 },
      ),
    ],
  );
  my ($name, $opt) = $check->(@_);

  my $data = {
    client_name  => $name,
    redirect_uris => $opt->{redirect_uris},
    scopes       => join ' ', @{$opt->{scopes}},
  };

  my $response;
  use DDP;
  p $data;
  try {
    my $resp = $self->post('apps', data => $data );
    $resp->is_success or die $resp->status_line;
    $response = JSON::decode_json( encode('utf8', $resp->decoded_content) );
  }
  catch {
    die 'Could not complete request: ', $_;
  };

  require Mastodon::App;
  my $client = Mastodon::App->new({
    name => $name,
    %{$response}
  });
  $self->apps->{$name} = $client;

  if (defined $opt->{to_file}) {
    $client->save($opt->{to_file});
  }

  return $self->apps->{$name};
}

sub load_app {
  my $self = shift;

  state $check = compile(
    File->plus_coercions( Str, sub { path( $_ ) } ),
  );
  my ($path) = $check->(@_);

  use Config::Tiny;
  my $config = Config::Tiny->read( $path );
  require Mastodon::App;

  my $name = $path->basename;
  $name =~ s/\.ini$//;

  my $client = Mastodon::App->new({
    name => $name,
    %{$config->{_}}
  });

  if (ref $self eq 'Mastodon') {
    $self->apps->{$name} = $client;
  }

  return $client;
}

# Returns a stream listener
sub stream { ... }

# Sets/Gets the client's authentication tokens
sub auth { ... }

1;
