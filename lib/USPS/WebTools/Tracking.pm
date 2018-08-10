package USPS::WebTools::Tracking;

use strict;
use warnings;

use XML::LibXML;
use LWP::UserAgent;
use Carp qw(croak);
use HTTP::Request::Common qw(GET POST);

our $prod_uri = 'http://production.shippingapis.com/ShippingAPI.dll';
our $secure_uri = 'https://secure.shippingapis.com/ShippingAPI.dll';

our $ua = LWP::UserAgent->new();

sub new {
  my ($class, %args) = @_;

  croak "No username provided." unless $args{username};
  croak "No password provided." unless $args{password};

  return bless \%args, $class
}

sub _send_request {
  my $self = shift;
}

1