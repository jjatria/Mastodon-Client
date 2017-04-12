package Mastodon::Types;

our $VERSION = '';

use Type::Library
  -base,
  -declare => qw(
    UserAgent
    App
  );

use Type::Utils qw( class_type duck_type coerce from via );
use Types::Standard qw( Str HashRef Num );
use URI;
use DateTime;

duck_type 'UserAgent', [qw( get post delete )];

class_type 'DateTime', { class => 'DateTime' };

class_type 'App', { class => 'Mastodon::App' };

class_type 'URI', { class => 'URI' };

coerce 'URI', from Str, via {
  s%^/+%%g;
  my $uri = URI->new((m%^https?://% ? '' : 'https://') . $_);
  $uri->scheme('https') unless $uri->scheme;
  return $uri;
};

coerce 'DateTime', from Num, via { DateTime->from_epoch( epoch => $_ ) };

1;
