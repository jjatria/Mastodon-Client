package Mastodon::Role::Entity;

use strict;
use warnings;

our $VERSION = '0.017';

use Moo::Role;

has _client => ( is => 'rw', weaken => 1);

1;
