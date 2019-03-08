package USPS::WebTools::Tracking;

use v5.28;

use strict;
use warnings;

use Socket;
use XML::LibXML;
use URI::Escape;
use LWP::UserAgent;
use Carp qw(croak);
use Net::Domain qw(hostfqdn);
use HTTP::Request::Common qw(GET POST);

our $ua = LWP::UserAgent->new;

sub new {
  my ($class, %args) = @_;

  croak "No username provided." unless $args{username};
  croak "No password provided." unless $args{password};

  return bless \%args, $class
}

sub track_request {
  my ($self, @track_ids) = @_;

  croak "No tracking IDs provided." unless scalar @track_ids;
  croak "More than 10 tracking IDs provided." unless scalar @track_ids <= 10;

  my $dom = $self->_create_base_document('TrackRequest');
  my $root = $dom->documentElement;

  foreach my $track_id (@track_ids) {
    my $elem = $dom->createElement('TrackID');
    $elem->setAttribute('ID', $track_id);

    $root->appendChild($elem)
  }

  my $req = GET $self->_build_request_uri('TrackV2', $dom);

  return $self->_send_request($req)
}

sub track_field_request {
  my ($self, %args) = @_;

  croak "No tracking IDs provided." unless scalar $args{track_ids}->@*;
  croak "More than 10 tracking IDs provided." unless scalar $args{track_ids}->@* <= 10;

  my $dom = $self->_create_base_document('TrackFieldRequest');
  my $root = $dom->documentElement;

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

  foreach my $track_id ($args{track_ids}->@*) {
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

  my $req = GET $self->_build_request_uri('TrackV2', $dom);

  return $self->_send_request($req)
}

 sub proof_of_delivery_request {
  my ($self, %args) = @_;

  my $dom = $self->_create_base_document('PTSPodRequest');
  my $root = $dom->documentElement;

  if($args{RequestType}) {
    if($args{RequestType} eq 'Email') {
      croak "Missing Email1." unless $args{Email1}
    }
    elsif($args{RequestType} eq 'Fax') {
      croak "Missing FaxNumber." unless $args{FaxNumber}
    }
    elsif($args{RequestType} eq 'Mail') {
      my @fields = qw(AddressLine1 AddressLine2 City State Zip);
      @fields = grep { !$args{$_} } @fields;

      croak "Missing: " . join ',', @fields . '.' if scalar @fields;
    }
    else {
      croak "Invalid RequestType."
    }
  }
  else {
    croak "Missing RequestType."
  }

  my @ordered = qw(TrackId ClientIp MpSuffix MpDate RequestType FirstName LastName Email1 Email2 Email3
    FaxNumber AddressLine1 AddressLine2 City State Zip VerifyAddress TableCode CustRegID);

  my @required = (0, 2, 3, 4, 5, 6, 17);

  foreach my $key (@ordered) {
    if($args{$key}) {
      my $elem = $dom->createElement($key);
      $elem->appendTextNode($args{$key});
      
      $root->appendChild($elem)
    }
    elsif(grep { $key eq $_ } @ordered[@required]) {
      croak "Missing $key."
    }
  }

  my $req = GET $self->_build_request_uri('PTSPod', $dom);

  return $self->_send_request($req)
}

sub return_reciept_electronic_request {
  my ($self, %args) = @_;

  my $dom = $self->_create_base_document('PTSRreRequest');
  my $root = $dom->documentElement;

  my @ordered = qw(TrackId ClientIp MpSuffix MpDate FirstName LastName Email1 Email2 Email3 TableCode CustRegId);
  my @required = (0, 2, 3, 4, 5, 6, 9);

  foreach my $key (@ordered) {
    if($args{$key}) {
      my $elem = $dom->createElement($key);
      $elem->appendTextNode($args{$key});

      $root->appendChild($elem)
    }
    elsif(grep { $key eq $_ } @ordered[@required]) {
      croak "Missing `$key`."
    }
  }

  my $req = GET $self->_build_request_uri('PTSRre', $dom);

  return $self->_send_request($req)
}

sub _build_request_uri {
  my ($self, $api, $dom) = @_;

  croak 'No API path given' unless $api;
  croak 'No XML::LibXML::Document given.' unless $dom;

  my $uri = 'https://';
  $uri .= $self->{test_mode} ? 'stg-secure' : 'secure';
  $uri .= ".shippingapis.com/ShippingAPI.dll?API=$api&XML=" . uri_escape_utf8($dom->toString);

  return $uri
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