package Mojolicious::Command::nopaste::Service::perlbot;
use Mojo::Base 'Mojolicious::Command::nopaste::Service';
use Mojo::JSON qw/decode_json/;

use Getopt::Long;

our $VERSION=0.001;

has name => 'anonymous';
has 'irc_handled' => 1;
has desc => 'I broke this';

has 'service_usage' => 
qq{perlbot.pl specific options:

  --get-channels     Ask the pastebin about what channels it knows, and exit
  --get-languages    Ask the pastebin about what languages it knows, and exit
};

sub run {
  my ($self, @args) = @_;

  my $p = Getopt::Long::Parser->new;
  $p->configure("no_ignore_case", "pass_through");
  $p->getoptionsfromarray( \@args,
    'get-channels'     => sub {$self->display_channels; exit(1)},
    'get-languages'    => sub {$self->display_languages; exit(1)},
  );

  $self->SUPER::run(@args);
}

sub display_channels {
  my $self = shift;
  my $tx = $self->ua->get( 'https://perlbot.pl/api/v1/channels');
 
  unless ($tx->res->is_status_class(200)) {
    say "Failed to get channels, try again later.";
    exit 1;
  }

  my $response = decode_json $tx->res->body;

  my $output="";
  for my $channel (@{$response->{channels}}) {
      $output .= sprintf "%10s %20s\n", $channel->{channel_id}, $channel->{channel_name};
  }

  return $output;
}

sub display_languages {
}

sub paste {
  my $self = shift;

  my $tx = $self->ua->post( 'https://perlbot.pl/api/v1/paste', form => {
    paste    => $self->text,
    username => $self->name,
    language => $self->language || '',
    channel  => $self->channel || '',
    description => $self->desc || '',
  });
 
  unless ($tx->res->is_status_class(200)) {
    say "Paste failed, try again later.";
    exit 1;
  }

  my $response = decode_json $tx->res->body;
  return $response->{url};
}
 
1;
