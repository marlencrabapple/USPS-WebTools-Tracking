package USPS::WebTools::Tracking;

use strict;
use warnings;

use XML::LibXML;
use URI::Escape;
use LWP::UserAgent;
use Carp qw(croak);
use HTTP::Request::Common qw(GET POST);

our $stg_uri = 'https://stg-secure.shippingapis.com/ShippingAPI.dll?API=TrackV2&XML=';
our $secure_uri = 'https://secure.shippingapis.com/ShippingAPI.dll?API=TrackV2&XML=';

our $ua = LWP::UserAgent->new();

sub new {
  my ($class, %args) = @_;

  croak "No username provided." unless $args{username};
  croak "No password provided." unless $args{password};

  $args{api_uri} = $args{test_mode} && $args{test_mode} == 1
    ? $stg_uri
    : $secure_uri;

  return bless \%args, $class
}

sub track_request {
  my ($self, @track_ids) = @_;

  croak "No tracking IDs provided." unless scalar @track_ids;
  croak "More than 10 tracking IDs provided." unless scalar @track_ids <= 10;

  my $dom = $self->_create_base_document();
  my $root = $dom->documentElement();

  foreach my $track_id (@track_ids) {
    my $elem = $dom->createElement('TrackID');
    $elem->setAttribute('ID', $track_id);

    $root->appendChild($elem)
  }

  my $req = GET $self->{api_uri} . uri_escape_utf8($dom->toString());

  return $self->_send_request($req)
}

sub _create_base_document {
  my $self = shift;

  my $dom = XML::LibXML::Document->createDocument('1.0', 'UTF-8');

  my $elem = $dom->createElement('TrackRequest');
  $elem->setAttribute('USERID', $self->{username});

  $dom->setDocumentElement($elem);

  return $dom
}

sub _send_request {
  my ($self, $req) = @_;

  my $res = $ua->request($req);

  return $res->is_success
    ? XML::LibXML->load_xml( string => $res->decoded_content )
    : croak $res->status_line, $res->decoded_content
}

1