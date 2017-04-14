package Mastodon::Types;

our $VERSION = '0';

use Type::Library
  -base,
  -declare => qw(
    UserAgent
    Image
    DateTime
    URI
  );

use Type::Utils -all;
use Types::Standard qw( Str HashRef Num );
use Types::Path::Tiny qw( File to_File);

use URI;
use DateTime;
use MIME::Base64;

duck_type 'UserAgent', [qw( get post delete )];

class_type 'DateTime', { class => 'DateTime' };

class_type 'URI', { class => 'URI' };

coerce 'URI', from Str, via {
  s%^/+%%g;
  my $uri = URI->new((m%^https?://% ? '' : 'https://') . $_);
  $uri->scheme('https') unless $uri->scheme;
  return $uri;
};

coerce 'DateTime', from Num, via { 'DateTime'->from_epoch( epoch => $_ ) };

declare 'Acct', as Str;

declare 'Image', as Str, where { m%^data:image/(png|jpeg);base64,[a-zA-Z0-9/+=\n]+$% };

coerce File, from Str, via {
  require Path::Tiny;
  return Path::Tiny::path( $_ );
};

coerce 'Image',
  from File->coercibles,
  via {
    my $file = to_File($_);
    require Image::Info;
    require MIME::Base64;
    my $type = lc Image::Info::image_type( $file->stringify )->{file_type};
    my $img = "data:image/$type;base64," . MIME::Base64::encode_base64( $file->slurp );
    return $img;
  };

# Entity types

foreach my $name (qw(
    Account Application Attachment Card Context Error Instance
    Mention Notification Relationship Report Result Status Tag
  )) {

  class_type $name, { class => "Mastodon::Entity::$name" };
  coerce $name, from HashRef, via {
    eval "require Mastodon::Entity::$name";
    "Mastodon::Entity::$name"->new($_);
  };
}

1;
