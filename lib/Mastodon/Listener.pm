package Mastodon::Listener;

our $VERSION = '0';

use Moo;
extends 'AnyEvent::Emitter';

use Carp;
use Types::Standard qw( Str Bool );

use Log::Any;
my $log = Log::Any->get_logger(category => 'Mastodon');

# my $app = Mastodon::Client->new( $config->{_} );
# my $listener = $app->stream( name => 'public' );
#
# $listener->on( update => sub {
#   my ($listener, $msg) = @_;
#   $log->infof('%s (%s) says: %s',
#     $msg->{account}{display_name},
#     $msg->{account}{acct},
#     $msg->{content}
#   );
# });
#
# $listener->on( delete => sub {
#   my ($listener, $id) = @_;
#   $log->infof('Item #%s has been deleted', $id);
# });
#
# $listener->on( notification => sub {
#   my ($listener, $msg) = @_;
#   $log->infof('Received a notification! %s', $msg);
# });
#
# $listener->on( heartbeat => sub {
#   my ($listener, $msg) = @_;
#   $log->infof('THUMP');
# });
#
# $listener->start;

has url => (
  is => 'ro',
  required => 1,
);

has access_token => (
  is => 'ro',
  required => 1,
);

has ua => (
  is => 'rw',
  lazy => 1,
  default => sub {
    require LWP::UserAgent;
    LWP::UserAgent->new;
  },
);

has coerce_entities => (
  is => 'rw',
  isa => Bool,
  lazy => 1,
  default => 1,
);

sub start {
  my ($self) = @_;

  $self->ua->get( $self->url,
    Authorization => 'Bearer ' . $self->access_token,
    ':content_cb' => sub { $self->parse_message(@_) },
  );
}

{
  my $buffer;

  sub parse_message {
    my ($self, $chunk, $response, $protocol) = @_;

    chomp $chunk;
    my @chunks = split /\n/, $chunk;

    foreach my $data (@chunks) {
      if ($data =~ /^:(\w+)/) {
        $self->emit( heartbeat => $1);
      }
      elsif ($data =~ /^event: (\w+)$/) {
        croak $log->fatalf('Received two event definitions in a row!')
          if defined $buffer and $buffer ne '';
        $buffer = $1;
      }
      else {
        $data =~ s/^data:\s+//;
        next if defined $buffer and $buffer eq '';

        my $event = $buffer;
        $buffer = '';

        use Try::Tiny;

        if ($event ne 'delete') {
          require JSON;

          $data = try {
            $data = JSON::decode_json( $data );
            if ($self->coerce_entities) {
              use Mastodon::Types qw( to_Status );
              return to_Status($data) if $event eq 'update';
            }
            return $data;
          }
          catch {
            $log->warn($_);
            return $data;
          };
        }

        $self->emit( $event => $data);
      }
    }
  }
}

1;
