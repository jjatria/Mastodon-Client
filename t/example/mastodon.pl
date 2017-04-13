#!/usr/bin/env perl

use v5.24.0;
binmode STDOUT, ':utf8';

use warnings;
use strict;
use diagnostics;

use Mastodon::Client;
use Log::Any qw( $log );
use Log::Any::Adapter;
Log::Any::Adapter->set( 'Stdout' );

use Config::Tiny;
my $config = (scalar @ARGV) ? Config::Tiny->read( $ARGV[0] )->{_} : {};
my $app = Mastodon::Client->new( $config );

my $listener = $app->stream( name => 'public' );

$listener->on( update => sub {
  my ($listener, $msg) = @_;

  use Term::ANSIColor qw(:constants);
  use HTML::FormatText::WithLinks;
  my $f = HTML::FormatText::WithLinks->new;

  local $Term::ANSIColor::AUTORESET = 1;

  say BOLD BLUE sprintf('%s (%s):',
    $msg->{account}{display_name},
    $msg->{account}{acct},
  );
  print $f->parse($msg->{content});
});
$listener->start;

# # Subscribe to public stream
# # Defaults to 'user'
# my $listener = $app->stream( name => 'public' );
# $listener->on( update => sub {
#   my ($listener, $msg) = @_;
#   $log->infof('%s (%s) says: %s',
#     $msg->{account}{display_name},
#     $msg->{account}{acct},
#     $msg->{content}
#   );
# });
# $listener->start;
#
# # Get timeline as hash reference
# # Defaults to "home"
# $app->timeline;
# $app->timeline( name => 'home' );
# $app->timeline( tag => 'perl', local => 1 );
# $app->timeline( tag => 'perl' );
# $app->timeline( name => 'public', local => 1 );
# $app->timeline( name => 'public' );
#
# # Register app in instance and obtain client_id and client_secret
# # $app->register;
#
# # Get the authorization URL for this app
# $app->authorization_url;
# $app->authorization_url(
#   instance => 'mastodon.cloud',
# );
#
# # Authorize an application
# $app->authorize( access_code => 'asdasdasd' );
# $app->authorize(
#   username => 'my@email.com',
#   password => $pass,
# );
#
