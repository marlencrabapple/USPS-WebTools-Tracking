package USPS::WebTools::Tracking::Codes;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(code_to_description code_is_return_to_sender code_is_attempted_notice_left); 
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#
# USPS Tracking Code/Name Lookup Tables
#

our %return_to_sender = (
  '09' => 'Return to Sender',
  '21' => 'No Such Number',
  '22' => 'Insufficient Address',
  '23' => 'Moved, Left No Address',
  '24' => 'Forward Expired',
  '25' => 'Addressee Unknown',
  '26' => 'Vacant',
  '27' => 'Unclaimed',
  '28' => 'Deceased',
  '29' => 'Other',
  '31' => 'Not Picked Up'
);

our %attempted_notice_left = (
  '02' => 'Attempted / Notice Left',
  '52' => 'Notice Left',
  '53' => 'Receptacle Blocked',
  '54' => 'Receptacle Full / Item Oversized',
  '55' => 'No Secure Location Available',
  '56' => 'No Authorized Recipient Available'
);

our %codes = (
  %return_to_sender,
  %attempted_notice_left,

  'MA' => 'Manifest Acknowledgement',
  'OF' => 'Out for Delivery',
  'PC' => 'Sorting / Processing Complete',
  '01' => 'Delivered',
  'DX' => 'Delivery Status Not Updated',
  '03' => 'Accept or Pickup (by carrier)',
  'TM' => 'Truck manifest, provided as "Shipment Acceptance"',
  '04' => 'Refused',
  '05' => 'Undeliverable as Addressed',
  '06' => 'Forwarded',
  '07' => 'Arrival at Unit',
  '08' => 'Missent',
  '10' => 'Processed',
  'PA' => 'Passive Acceptance, provided as "Shipment Acceptance"',
  '11' => 'Dead Letter',
  '14' => 'Arrival at Pickup Point',
  '15' => 'Mis-shipped',
  '16' => 'Available for Pickup',
  '17' => 'Picked Up By Agent',
  '19' => 'DC eVS Arrive',
  '41' => 'Received at Opening Unit (Reserved for Open & Distribute)',
  '42' => 'USPS Handoff to Shipping Partner',
  '43' => 'Picked Up',
  '44' => 'Customer Recall',
  '51' => 'Business Closed',
  '80' => 'Picked Up by Shipping Partner',
  '81' => 'Arrived Shipping Partner Facility',
  '82' => 'Departed Shipping Partner Facility',
  'EF' => 'Departed Sort Facility',
  'SF' => 'Departed Post Office',
  '71' => 'Rescheduled to Next Delivery Day',
  '30' => 'Delivery Attempted - No Access to Delivery Location'
);

sub code_to_description {
  my $code = shift;
  return $codes{$code}
}

sub code_is_return_to_sender {
  my $code = shift;
  return 1 if $return_to_sender{$code}
}

sub code_is_attempted_notice_left {
  my $code = shift;
  return 1 if $attempted_notice_left{$code}
}

1;