package Mastodon::Listener;

our $VERSION = '0';

use strict;
use warnings;

use Moo;
extends 'AnyEvent::Emitter';

use Carp;
use Types::Standard qw( Int Str Bool );
use Mastodon::Types qw( Instance );
use AnyEvent::HTTP;
use Try::Tiny;

use Log::Any;
my $log = Log::Any->get_logger(category => 'Mastodon');

has instance => (
  is => 'ro',
  isa => Instance,
  coerce => 1,
  default => 'mastodon.cloud',
);

has api_version => (
  is => 'ro',
  isa => Int,
  default => 1,
);

has url => (
  is => 'ro',
  lazy => 1,
  default => sub {
      $_[0]->instance
    . '/api/v' . $_[0]->api_version
    . '/streaming/' . $_[0]->stream;
  },
);

has stream => (
  is => 'ro',
  lazy => 1,
  default => 'public',
);

has access_token => (
  is => 'ro',
  required => 1,
);

has connection_guard => (
  is => 'rw',
  init_arg => undef,
);

has cv => (
  is => 'rw',
  init_arg => undef,
  lazy => 1,
  default => sub { AnyEvent->condvar },
);

has coerce_entities => (
  is => 'rw',
  isa => Bool,
  lazy => 1,
  default => 0,
);

sub BUILD {
  my ($self, $arg) = @_;
  $self->reset;
}

sub start {
  return $_[0]->cv->recv;
}

sub stop {
  return shift->cv->send(@_);
}

sub reset {
  $_[0]->connection_guard($_[0]->_set_connection);
  return $_[0];
}

sub _emitter {
  my ($self, $event, $data) = @_;

  return unless $event;
  return unless $data;

  require JSON;

  if ($event ne 'delete') {
    $data = try {
      JSON::decode_json( $data );
    }
    catch {
      die $log->fatalf('Error decoding: %s', $_);
    };

    if ($self->coerce_entities) {
      use Mastodon::Types qw( to_Status to_Notification );
      $data = to_Notification($data) if $event eq 'notification';
      $data = to_Status($data)       if $event eq 'update';
    }
  }

  $self->emit( $event => $data );
}

sub _set_connection {
  my $self = shift;
  my $x = http_request GET => $self->url,
    headers => { Authorization => 'Bearer ' . $self->access_token },
    handle_params => {
      max_read_size => 8168,
    },
    want_body_handle => 1,
    sub {
      my ($handle, $headers) = @_;

      if ($headers->{Status} !~ /^2/) {
        $self->emit( error => $handle, 1,
          'Could not connect to ' . $self->url . ': ' . $headers->{Reason}
        );
        $self->stop;
        undef $handle;
        return;
      }

      unless ($handle) {
        $self->emit( error => $handle, 1,
          'Could not connect to ' . $self->url
        );
        $self->stop;
        return;
      }

      my $event_pattern = qr{(:thump|event: (\w+)).*?data: (.*)}s;

      my $parse_event;
      $parse_event = sub {
        my ($handle, $chunk) = @_;

        my ($event_line, $event, $data) = ($1, $2, $3);
        $data =~ s/\s+$//s;

        if ($event_line =~ /thump/) {
          $self->emit( 'heartbeat' );
        }
        else {
          try   { $self->_emitter( $event => $data ) }
          catch { $self->emit( error => $handle, 0, $_) };
        }

        $handle->push_read( regex => $event_pattern, $parse_event );
      };

      # Push initial reader: look for event name
      $handle->on_read(sub {
        my ($handle) = @_;
        $handle->push_read( regex => $event_pattern, $parse_event );
      });

      $handle->on_error(sub {
        undef $handle;
        $self->emit( error => @_ );
      });

      $handle->on_eof(sub {
        undef $handle;
        $self->emit( eof => @_ );
      });

    };
  return $x;
}

1;

__END__

=encoding utf8

=head1 NAME

Mastodon::Listener - Access the streaming API of a Mastodon server

=head1 SYNOPSIS

  # From Mastodon::Client
  my $listener = $client->stream( 'public' );

  # Or use it directly
  my $listener = Mastodon::Listener->new(
    url => 'https://mastodon.cloud/api/v1/streaming/public',
    access_token => $token,
    coerce_entities => 1,
  )

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

Mastodon::Listener objects inherit from L<AnyEvent::Emitter>. Please refer to
their documentation for details on how to register callbacks for the different
events.

Once callbacks have been registered, the listener can be set in motion by
calling its B<start> method, which takes no arguments and never returns.
The B<stop> method can be called from within callbacks to disconnect from the
stream.

=head1 ATTRIBUTES

=over 4

=item B<url>

=item B<stream>

=item B<instance>

=item B<api_version>

=item B<coerce_entities>

=item B<access_token>

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

=item B<error>

Inherited from L<AnyEvent::Emitter>, will be emitted when an error was found.
The callback will be called with the same arguments as the B<on_error> callback
for L<AnyEvent::Handle>: the handle of the current connection, a fatal flag,
and an error message.

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
