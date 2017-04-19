#!/usr/bin/env perl

binmode STDOUT, ':utf8';

use warnings;
use strict;
use diagnostics;

use Mastodon::Client;
use AnyEvent;
use Config::Tiny;

# use Log::Any::Adapter;
# my $log = Log::Any::Adapter->set( 'Stderr',
#   category => 'Mastodon',
#   log_level => 'debug',
# );

unless (scalar @ARGV) {
  print "  Missing arguments
  USAGE: $0 <CONFIG>

  <CONFIG> should be an INI file with a valid 'client_secret', 'client_id', and
  'access_token', and an 'instance' key with the URL to a Mastodon instance.\n";
  exit(1);
}

my ($configfile, $stream) = @ARGV;

my $config = (defined $configfile)
  ? Config::Tiny->read( $configfile )->{_} : {};

my $app = Mastodon::Client->new({
  %{$config},
  coerce_entities => 1,
});

my $listener = $app->stream( $stream // 'public' );

# Counter for statuses
my $n = 0;

$listener->on( update => sub {
  my ($listener, $data) = @_;

  # Only print 10 first statuses
  $listener->stop if ++$n >= 10;

  use Term::ANSIColor qw(:constants);
  use HTML::FormatText::WithLinks;
  my $f = HTML::FormatText::WithLinks->new;

  local $Term::ANSIColor::AUTORESET = 1;

  print BOLD BLUE sprintf("%s (%s):\n",
    $data->account->display_name,
    $data->account->acct,
  );
  print $f->parse($data->content);
});

$listener->on( delete => sub {
  my ($listener, $data) = @_;
  print BOLD RED sprintf("Status %s was deleted!\n\n", $data);
});

$listener->on( notification => sub {
  my ($listener, $data) = @_;

  use Lingua::EN::Inflexion;
  my $line = $data->account->acct . ' ' . verb($data->type)->past . ' you';
  if ($data->type =~ /(blog|fav)/) {
    $line .= 'r status';
  }

  print BOLD GREEN "$line!\n";
});

$listener->on( error => sub {
  my $listener = shift;
  print pop(@_), "\n";
});

$listener->start;
