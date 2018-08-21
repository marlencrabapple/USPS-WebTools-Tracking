package USPS::WebTools::Tracking;

use strict;
use warnings;

use Socket;
use XML::LibXML;
use URI::Escape;
use LWP::UserAgent;
use Carp qw(croak);
use Net::Domain qw(hostfqdn);
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

  my $dom = $self->_create_base_document('TrackRequest');
  my $root = $dom->documentElement();

  foreach my $track_id (@track_ids) {
    my $elem = $dom->createElement('TrackID');
    $elem->setAttribute('ID', $track_id);

    $root->appendChild($elem)
  }

  my $req = GET $self->{api_uri} . uri_escape_utf8($dom->toString());

  return $self->_send_request($req)
}

sub track_field_request {
  my ($self, %args) = @_;

  croak "No tracking IDs provided." unless scalar @{ $args{track_ids} };
  croak "More than 10 tracking IDs provided." unless scalar @{ $args{track_ids} } <= 10;

  my $dom = $self->_create_base_document('TrackFieldRequest');
  my $root = $dom->documentElement();

  if($args{revision} && $args{revision} == 1) {
    my $elem = $dom->createElement('Revision');
    $elem->appendTextNode($args{revision});

    $root->appendChild($elem);

    $elem = $dom->createElement('ClientIp');
    $elem->appendTextNode(_get_ip());

    $root->appendChild($elem);

    if($args{source_id}) {
      croak "Invalid source id provided." unless $args{source_id} =~ /^[a-z0-9]+$/i
    }
    else {
      croak "No source id provided."
    }

    $elem = $dom->createElement('SourceId');
    $elem->appendTextNode($args{source_id});

    $root->appendChild($elem)
  }
  elsif($args{revision}) {
    croak "Invalid revision value."
  }

  if($args{source_id_zip} && $args{source_id_zip} =~ /^[0-9]{5}$/) {
    my $elem = $dom->createElement('SourceIdZIP');
    $elem->appendTextNode($args{source_id_zip});

    $root->appendChild($elem)
  }
  elsif($args{source_id_zip}) {
    croak "Invalid source id zip code value."
  }

  foreach my $track_id (@{ $args{track_ids} }) {
    my $elem = $dom->createElement('TrackID');
    $elem->setAttribute('ID', $track_id);

    $root->appendChild($elem)
  }

  if($args{destination_zip_code} && $args{destination_zip_code} =~ /^[0-9]{5}$/) {
    my $elem = $dom->createElement('DesinationZipCode');
    $elem->appendTextNode($args{destination_zip_code});

    $root->appendChild($elem)
  }
  elsif($args{destination_zip_code}) {
    croak "Invalid destination zip code value."
  }

  if($args{mailing_date} && $args{mailing_date} =~ /^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/) {
    my $elem = $dom->createElement('MailingDate');
    $elem->appendTextNode($args{mailing_date});

    $root->appendChild($elem)
  }
  elsif($args{mailing_date}) {
    croak "Mailing date value not in YYYY-MM-DD form."
  }

  my $req = GET $self->{api_uri} . uri_escape_utf8($dom->toString());

  return $self->_send_request($req)
}

sub _create_base_document {
  my ($self, $root_name) = @_;

  my $dom = XML::LibXML::Document->createDocument('1.0', 'UTF-8');

  my $elem = $dom->createElement($root_name);
  $elem->setAttribute('USERID', $self->{username});

  $dom->setDocumentElement($elem);

  return $dom
}

sub _get_ip {
  my $host = hostfqdn();
  return inet_ntoa(scalar gethostbyname($host || 'localhost'))
}

sub _send_request {
  my ($self, $req) = @_;

  my $res = $ua->request($req);

  return $res->is_success
    ? XML::LibXML->load_xml( string => $res->decoded_content )
    : croak $res->status_line, $res->decoded_content
}

1