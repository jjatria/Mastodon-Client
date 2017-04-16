package Mastodon::Listener;

our $VERSION = '0.002';

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

__END__

=encoding utf8

=head1 NAME

Mastodon::Listener - Access the streaming API of a Mastodon server

=head1 SYNOPSIS

  use Mastodon::Client;

  my $client = Mastodon::Client->new(
    instance        => 'mastodon.social',
    name            => 'PerlBot',
    client_id       => $client_id,
    client_secret   => $client_secret,
    access_token    => $access_token,
    coerce_entities => 1,
  );

  $client->post( statuses => {
    status     => 'Posted to a Mastodon server!',
    visibility => 'public',
  })

  # Streaming interface might change!
  my $listener = $client->stream(
    name => 'public',
  );
  $listener->on( update => sub {
    my ($listener, $status) = @_;
    printf "%s said: %s\n",
      $status->account->display_name,
      $status->content;
  });
  $listener->start;

=head1 DESCRIPTION

A Mastodon::Listener object is created by calling the B<stream> method from a
L<Mastodon::Client>, and it exists for the sole purpose of parsing a stream of
events from a Mastodon server.

Matodon::Listener objects inherit from L<AnyEvent::Emitter>. Please refer to
their documentation for details on how to register callbacks for the different
events.

Once callbacks have been registered, the listener can be set in motion by
calling its B<start()> method, which takes no arguments and never returns.

=head1 EVENTS

=over 4

=item B<update>

A new status has appeared. Callback will be called with the listener and
the new status.

=item B<notification>

A new notification has appeared. Callback will be called with the listener
and the new notification.

=item B<delete>

A status has been deleted. Callback will be called with the listener and the
ID of the deleted status.

=item B<heartbeat>

A new C<:thump> has been received from the server. This is mostly for
debugging purposes.

=back

=head1 AUTHOR

=over 4

=item *

José Joaquín Atria <jjatria@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
