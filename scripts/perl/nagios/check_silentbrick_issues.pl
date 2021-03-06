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
#   check_issues.pl -h hostname -u username -p password  [--help]
#   
#   	hostname: 	hostname or IP
#   	username:	valid username for the UI
#   	password:	valid password for the UI
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
      "\nUsage: $command -h hostname -u username -p password [--help]\n\n".
      "\thostname : Hostname or IP of the Silent Brick System\n".
      "\tusername : Valid UI logon user\n".
      "\tpassword : Valid password for the logon user\n"
  
   		);

   exit 1;

}

#** @method public int print_titles
#
#   @brief Prints the titles of all messages in the array
#   @params array with all messages
#   @retval 1
#*
sub print_titles {

	my $content = shift;
	my $string;

	foreach my $message ( @{$content} ){
		if( $message->{'Title'} ){
			$string .= " ".$message->{'Title'}." |";
		}
	}
	chop($string);
	print $string . "\n";

	return 1;	

}

my $host;
my $user;
my $pass;
my $help;

GetOptions ( "h=s" 	=> \$host,   # string
           	 "u=s"  => \$user,   # string
             "p=s" 	=> \$pass,   # string
             "help!"	=> \$help,

					) or usage();

if( !$host || !$user || !$pass || $help ){
	usage();
}


my $object = FAST::ApiPublic->new({
                                    host => $host,
                                    user => $user,
                                    password => $pass,
                                });


# ATTENTION: returncode rc may be 1 if contetn is empty.
#           rc reflects the return code of the service, means successful call or not
my $errors 			= $object->getOpenIssues( { type => 'Error' });
my $warnings 		= $object->getOpenIssues( { type => 'Warning' });

my $bESuccess = ( $errors->{rc} == 1 );
my $bRSuccess = ( $warnings->{rc} == 1 );
my $exitCode = 0;

if( 0!= $bRSuccess ){
	if( @{$warnings->{content}}  gt 0 ){
			print "WARN - ";
			print_titles( $warnings->{content} );
         $exitCode = 1;
	}
}

if(  0!= $bESuccess ){
   if( @{$errors->{content}}  gt 0 ){
      print "CRIT -";
      print_titles( $errors->{content} );
      $exitCode = 2;
   }
}

if ( !($bESuccess || $bRSuccess) ) {
	print "UNK - Failed to connect to your system. Please verify IP and software version >= 2.10";
	$exitCode = 3;
}

exit $exitCode;
