#!/usr/bin/env perl

binmode STDOUT, ':utf8';

use warnings;
use strict;
use diagnostics;

use Mastodon::Client;
use Config::Tiny;

unless (scalar @ARGV) {
  print "  Missing arguments
  USAGE: $0 <CONFIG>

  <CONFIG> should be an INI file with a valid 'client_secret', 'client_id', and
  'access_token', and an 'instance' key with the URL to a Mastodon instance.\n";
  exit(1);
}

my $config = (scalar @ARGV) ? Config::Tiny->read( $ARGV[0] )->{_} : {};
my $app = Mastodon::Client->new({
  %{$config},
  coerce_entities => 1,
});

my $listener = $app->stream( 'public' );

$listener->on( update => sub {
  my ($listener, $status) = @_;

  use Term::ANSIColor qw(:constants);
  use HTML::FormatText::WithLinks;
  my $f = HTML::FormatText::WithLinks->new;

  local $Term::ANSIColor::AUTORESET = 1;

  print BOLD BLUE sprintf("%s (%s):\n",
    $status->account->display_name,
    $status->account->acct,
  );
  print $f->parse($status->content);
});
$listener->start;
