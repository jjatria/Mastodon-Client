package Mastodon::Listener;

our $VERSION = '';

use Moo;
use Carp;

extends 'Mojo::EventEmitter';
use Log::Any qw( $log );
use Types::Standard qw( Str );

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

has buffer => (
  is => 'rw',
  isa => Str,
  default => '',
);

has access_token => (
  is => 'ro',
  required => 1,
);

has tx => (
  is => 'rw',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $tx = $self->ua->build_tx( GET => $self->url );
    $tx->req->headers->authorization('Bearer ' . $self->access_token);
    $tx->res->content
      ->unsubscribe('read')
      ->on(read => sub { $self->parse_message(@_) });
    return $tx;
  },
);

# Would love to move away from Mojo::UserAgent
# But how?
has ua => (
  is => 'rw',
  lazy => 1,
  default => sub {
    use Mojo::UserAgent;
    Mojo::UserAgent->new(max_response_size => 0);
  },
);

sub start {
  $_[0]->ua->start($_[0]->tx);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

{
  my $buffer;

  sub parse_message {
    my ($self, $msg) = @_;

    my $chunk = $msg->{buffer};
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
        if ($event !~ /delete/) {
          try {
            require JSON;
            $data = JSON::decode_json( $data );
          }
          catch { $log->warn($_) };
        }
        $self->emit( $event => $data);
      }
    }
  }
}

1;
