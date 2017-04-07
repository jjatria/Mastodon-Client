package Mastodon::Client;

use Moo;
use Types::Standard qw( Str );

with 'Mastodon::Role::UserAgent';

has id => (
  is => 'rw',
  isa => Str,
);

has secret => (
  is => 'rw',
  isa => Str,
);

has access_token => (
  is => 'rw',
  isa => Str,
);

sub log_in {
  my $self = shift;

  state $check = compile( Str, Str,
    slurpy Dict[
      scopes => ArrayRef->plus_coercions(
        Undef, sub { [qw( read write follow )] }
      ),
      scopes => Str->plus_coercions(
        Undef, sub { 'password' }
      ),
    ],
  );
  my ($username, $password, $opt) = $check->(@_);
  $opt->{scopes} = sort @{$opt->{scopes}};
  my $requested_scopes = join ' ', @{$opt->{scopes}};

  my $params = {
    grant_type => $opt->{grant_type},
    scopes => $requested_scopes,
  };

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

  $response->{scope} = sort @{$response->{scope}};
  my $granted_scopes = join ' ', @{$response->{scope}};

  if ($requested_scopes ne $granted_scopes) {
    die "Granted scopes '$granted_scopes' differ from requested scopes '$requested_scopes'";
  }

#   if to_file != None:
#       with open(to_file, 'w') as token_file:
#           token_file.write(response['access_token'] + '\n')

  return $self->access_token;
}

1;
