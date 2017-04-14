# NAME

Mastodon::Client - Talk to a Mastodon server

# SYNOPSIS

    use Mastodon::Client;

    my $client = Mastodon::Client->new(
      instance      => 'mastodon.social',
      name          => 'PerlBot',
      client_id     => $client_id,
      client_secret => $client_secret,
      access_token  => $access_token,
    );

    $client->post( statuses => {
      status     => 'Posted to a Mastodon server!',
      visibility => 'public',
    })

    # Streaming interface might change!
    my $listener = $client->stream(
      name            => 'public',
      coerce_entities => 1,
    );
    $listener->on( update => sub {
      my ($listener, $status) = @_;
      printf "%s said: %s\n",
        $status->account->display_name,
        $status->content;
    });
    $listener->start;

# DESCRIPTION

Mastodon::Client lets you talk to a Mastodon server.

This distribution is still in development, and the interface might
change in the future. But changes should mostly be to add convenience
methods for the more common tasks.

The use of the request methods (**post**, **get**, etc) is not likely to
change, and as long as you know the endpoints you are reaching, this
should be usable right now.

# AUTHOR

- José Joaquín Atria <jjatria@cpan.org>
- Lance Wicks <lancew@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
