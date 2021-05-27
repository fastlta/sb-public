#! /usr/bin/perl
##################################################################
# Copyright 2020 FAST LTA GmbH
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License. 
# 
# 
# #########
#
# Description:
#   - Script will check for Errors and Warnings
#   - Script will report about Errors ( CRIT ) or Warnings ( WARN )
# 
# 
# Installation:
# 
#   - Install Perl
# 	- Make sure all needed perl modules are installed:
# 		- REST::Client;
#		- MIME::Base64
#		- JSON
#		- Getopt::Long
#		
# 
# 	- Install script to nagios plugins folder
# 	- Install FAST::ApiPublic into nagios plugins/FAST Folder
# 	
# Usage:
# 
#   check_volume_fillstate.pl -h hostname -u username -p password -w warn -c crit [ -n name ] [--help]
#   
#   	hostname: 	hostname or IP
#   	username:	valid username for the UI
#   	password:	valid password for the UI
#   	warn: 		Percentage of usage to report Warning
#   	crit:		Percentage of usage to report Critical
#   	name: 		valid name of a SNAS Volume or Compliant Archive. Attention: Compliant Archive Names are not transferred as in UI.
#   	
#   
##################################################################

use FindBin;   
use lib "$FindBin::Bin/..";
use strict;
use warnings;
use Data::Dumper;
use MIME::Base64;
use FAST::ApiPublic;
use Getopt::Long;

sub usage {
	
	my $command = $0;
   	$command =~ s#^.*/##;

   	  print STDERR (
      "\nUsage: $command -h hostname -u username -p password -w warn -c crit [ -n name ] [--help]\n\n".
      "\thostname : Hostname or IP of the Silent Brick System\n".
      "\tusername : Valid UI logon user\n".
      "\tpassword : Valid password for the logon user\n".
      "\tname     : Optional SNAS Volume name or Brick Archive ID. If not set, all Volumes will be reported including name/ID\n".
      "\twarn     : Maximum used percentage before Warning is triggered.\n".
      "\tcrit	  : Maximum used percentage before Critical is triggered.\n"

  
   		);

   exit 1;

}



my $host;
my $user;
my $pass;
my $help;
my $warn;
my $crit;
my $search_name;

GetOptions ( "h=s" 	=> \$host,   # string
           	 "u=s"  => \$user,   # string
             "p=s" 	=> \$pass,   # string
             "w=i"  => \$warn,   # int
             "c=i"  => \$crit,   # int
             "n:s"  => \$search_name,    # string optional
             "help!"	=> \$help,

					) or usage();

if( !$host || !$user || !$pass || !$warn || !$crit || $help ){
	usage();
}


my $object = FAST::ApiPublic->new({
                                    host => $host,
                                    user => $user,
                                    password => $pass,
                                });



my $ret 		= $object->getVolumes( );


if( $ret->{rc} != 1 ){
	print "Failed to read volumes\n";
	exit 3;
}

my $vol_uuid;
my $vol_name;
my $vol_net;
my $vol_used;
my $vol_perc;
my $all_volumes_string = "";
my $volume_usages;
my $max_error = 0;

my $exit_state_prefix = {  0 => "OK",
						   1 => "WARN",
						   2 => "CRIT",
						   3 => "UNKOWN" 
						};


foreach( @{$ret->{volumes}} ){

	if( $_->{status} ne 'online'){
		next;
	}

	$vol_uuid = $_->{uuid};
	$vol_name = $_->{name};

	my $get_details = $object->getVolumeDetails( { volume_uuid => $vol_uuid } );

	if( $get_details->{rc} != 1 ){
		print "Failed to read details for $vol_name";
		exit 3;
	}


	$vol_net  = $get_details->{content}[0]->{net_size};
	$vol_used = $get_details->{content}[0]->{net_used};
	$vol_perc = int( $vol_used / $vol_net * 100 );

	$volume_usages->{$vol_name} = { 'used' => $vol_used,
									'size' => $vol_net,
									'perc' => $vol_perc,
								 };

    $all_volumes_string .= " $vol_name ($vol_perc\%);";

	if( $vol_perc >= $crit ){
		$volume_usages->{$vol_name}->{exit_state} = 2;
	}
	elsif( $vol_perc >= $warn  ){
		$volume_usages->{$vol_name}->{exit_state} = 1;
	}else{
		$volume_usages->{$vol_name}->{exit_state} = 0;
	}

	if($volume_usages->{$vol_name}->{exit_state} > $max_error){
			$max_error = $volume_usages->{$vol_name}->{exit_state};
	}


}

chop($all_volumes_string);

if( $search_name && ( $volume_usages->{$search_name} ) ){

	print $exit_state_prefix->{$volume_usages->{$search_name}->{exit_state}}." - $search_name is filled ".$volume_usages->{$search_name}->{perc}." %";

	exit $volume_usages->{$search_name}->{exit_state};
}
elsif( $search_name ){
	print "UNKN - Volume $search_name not found";
	exit 3;
}

print  $exit_state_prefix->{$max_error}." - $all_volumes_string\n";
exit $max_error;


exit;
