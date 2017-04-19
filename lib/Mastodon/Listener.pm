package Mastodon::Listener;

our $VERSION = '0';

use strict;
use warnings;

use Moo;
extends 'AnyEvent::Emitter';

use Carp;
use Types::Standard qw( Str Bool );
use AnyEvent::HTTP;

use Log::Any;
my $log = Log::Any->get_logger(category => 'Mastodon');

has url => (
  is => 'ro',
  required => 1,
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
  is => 'ro',
  init_arg => undef,
  lazy => 1,
  default => sub { AnyEvent->condvar },
);

has coerce_entities => (
  is => 'rw',
  isa => Bool,
  lazy => 1,
  default => 1,
);

sub BUILD {
  my ($self, $arg) = @_;

  $self->connection_guard( my $x = http_request GET => $self->url,
    headers => { Authorization => 'Bearer ' . $self->access_token },
    want_body_handle => 1,
    sub {
      my ($handle, $headers) = @_;

      if ($headers->{Status} !~ /^2/) {
        $self->emit( error => $handle, 1,
          'Could not connect to ' . $self->url . ': ' . $headers->{Reason}
        );
        undef $handle;
        return $self->cv->send(0);
      }

      unless ($handle) {
        $self->emit( error => $handle, 1,
          'Could not connect to ' . $self->url
        );
        return $self->cv->send(0);
      }

      my ($parse_event, $parse_data);
      my $event;

      # Event detector
      $parse_event = sub {
        my ($handle, $line) = @_;

        if ($line =~ /^event: (\w+)/) {
          $event = $1;
          $handle->push_read (line => $parse_data );
        }
        elsif ($line =~ /^:thump/) {
          $self->emit( 'heartbeat' );
          $handle->push_read (line => $parse_event);
        }
        else {
          $handle->push_read (line => $parse_event );
        }
      };

      # Data detector
      $parse_data = sub {
        my ($handle, $line) = @_;

        if ($line =~ /^data: /) {
          $line =~ s/^data: //;
          $self->_emitter($event => $line);
          $handle->push_read (line => $parse_event );
        }
        else {
          $handle->push_read (line => $parse_data );
        }
      };

      # Push initial reader: look for event name
      $handle->on_read(sub {
        my ($handle) = @_;
        $handle->push_read (line => $parse_event );
      });

      $handle->on_error(sub {
        undef $handle;
        $self->emit( error => @_ );
      });

      $handle->on_eof(sub {
        undef $handle;
        $self->emit( eof => @_ );
      });

    }
  );
}

sub start {
  shift->cv->recv;
}

sub stop {
  shift->cv->send;
}

sub _emitter {
  my ($self, $event, $data) = @_;

  return unless $event;
  return unless $data;

  use Try::Tiny;
  require JSON;

  if ($event ne 'delete') {
    $data = try {
      JSON::decode_json( $data );
    }
    catch {
      croak $log->fatalf('Error decoding: %s', $_);
    };

    if ($self->coerce_entities) {
      use Mastodon::Types qw( to_Status to_Notification );
      $data = to_Notification($data) if $event eq 'notification';
      $data = to_Status($data)       if $event eq 'update';
    }
  }

  $self->emit( $event => $data );
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
