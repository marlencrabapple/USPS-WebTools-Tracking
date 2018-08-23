package USPS::WebTools::Tracking::Codes;

use strict;
use warnings;

use Readonly;

use Exporter 'import';

our @EXPORT_OK = qw(name_to_code code_to_name code_is_return_to_sender name_is_return_to_sender); 
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#
# USPS Tracking Code/Name Lookup Tables
#

Readonly our %return_to_sender => (
  return_to_sender => '09',
  return_to_sender_no_such_number => '21',
  return_to_sender_insufficient_address => '22',
  return_to_sender_moved => '23',
  return_to_sender_forward_expired => '24',
  return_to_sender_addressee_unknown => '25',
  return_to_sender_vacant => '26',
  return_to_sender_unclaimed => '27',
  return_to_sender_deceased => '28', # ;_;
  return_to_sender_other => '29',
  return_to_sender_not_picked_up => '31'
);

Readonly our %name_to_code => (
  manifest_acknowledgement => 'MA',
  out_for_delivery => 'OF',
  sorting_processing_complete => 'PC',
  delivered => '01',
  delivery_status_not_updated => 'DX',
  attempted_notice_left => '02',
  notice_left => '52',
  receptacle_blocked => '53',
  receptacle_full_item_oversized => '54',
  no_secure_location_available => '55',
  no_authorized_recipient_available => '56',
  accept_or_pickup_by_carrier => '03',
  truck_manifest_shipment_acceptance => 'TM',
  refused => '04',
  undeliverable_as_addressed => '05',
  forwarded => '06',
  arrival_at_unit => '07',
  missent => '08',
  %return_to_sender,
  processed => '10',
  passive_acceptance_shipment_acceptance => 'PA',
  dead_letter => '11',
  arrival_at_pickup_point => '14',
  mis_shipped => '15',
  available_for_pickup => '16',
  picked_up_by_agent => '17',
  dc_evs_arrive => '19',
  recieved_at_opening_unit => '41',
  usps_handoff_to_shipping_partner => '42',
  picked_up => '43',
  customer_recall => '44',
  business_closed => '51',
  picked_up_by_shipping_partner => '80',
  arrived_at_shipping_partner_facility => '81',
  departed_shipping_partner_facility => '82',
  departed_sort_facility => 'EF',
  departed_post_office => 'SF'
);

Readonly::Hash our %code_to_name => map {
  $name_to_code{$_}, $_
} keys %name_to_code;

sub name_to_code {
  my $name = shift;
  return $name_to_code{$name}
}

sub code_to_name {
  my $code = shift;
  return $code_to_name{$code}
}

sub code_is_return_to_sender {
  my $code = shift;
  return 1 if $return_to_sender{$code}
}

sub name_is_return_to_sender {
  my $name = shift;
  return 1 if $return_to_sender{$name}
}

1;