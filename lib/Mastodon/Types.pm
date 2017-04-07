package Mastodon::Types;

use Type::Library
  -base,
  -declare => qw(
    UserAgent
    Client
  );

use Type::Utils qw( class_type duck_type );
use Types::Standard qw( HashRef );

duck_type 'UserAgent', [qw( get post delete )];

class_type 'Client', { class => 'Mastodon::Client' };

1;
