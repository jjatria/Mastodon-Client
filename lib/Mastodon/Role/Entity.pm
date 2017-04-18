package Mastodon::Role::Entity;

our $VERSION = '0.007';

use strict;
use warnings;

use Moo::Role;

has _client => ( is => 'rw', weaken => 1);

1;
