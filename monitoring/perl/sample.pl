#! /usr/bin/perl
##################################################################
# Copyright 2018 FAST LTA AG
# 
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
# Authors   : jgelhorn, rweber
# Version   : 1.0
# Date      : 26.03.2018
#
##################################################################



use strict;
use warnings;
use Data::Dumper;
use MIME::Base64;
use FAST::ApiPublic;


### Set you Silent Brick System IP and credentials
my $ip = '172.20.60.70';
my $user = 'admin';
my $pass = 'adminadmin';

my $object = FAST::ApiPublic->new({
                                    host => $ip,
                                    user => $user,
                                    password => $pass,
                                });



### Optional: Modifying Hostname
$object->setHost({
        host => $ip,

 });

### Optional: Modifying credentials
$object->setCredentials({
        user        => 'admin',
        password    => 'adminadmin',
    });


### Reading all Volumes
my $vols        = $object->getVolumes();
if( $vols->{rc} == 1 ){
	print "Found Volumes:";
	print Dumper ($vols->{content});
}
else{
	print "Failed to retrieve Volumes.";
	print Dumper ($vols->{content});
}

### Reading all Libraries
my $libs        = $object->getLibraries();
if( $libs->{rc} == 1 ){
	print "Found Libraries:";
	print Dumper ($libs->{content});
}
else{
	print "Failed to retrieve Libraries.";
	print Dumper ($libs->{content});
}

### Reading all Issues by type
my $issues 		= $object->getOpenIssues( { type => "error" });
if( $issues->{rc} == 1 ){
	print "Found Issues:";
	print Dumper ($issues->{content});
}
else{
	print "Failed to retrieve Issues.";
	print Dumper ($issues->{content});
}



### Choose a valid UUID of your Volume. 
### Use getVolumes to retrieve a valid list of Volumes
my $uuid = '2a4de596-d9b8-4659-bcac-6836af838374';


### Setting a Volume offline by UUID
my $offline_ret   = $object->SetVolumeOfflineByUUID( {volume_uuid => $uuid} );
if( $offline_ret->{rc} == 1 ){
	print "Setting offline successful:";
	print Dumper ($offline_ret->{content});
}
else{
	print "Failed to set offline.";
	print Dumper ($offline_ret->{content});
}

### Setting a Volume online by UUID
my $online_ret      = $object->SetVolumeOnlineByUUID( {volume_uuid => $uuid} );
if( $online_ret->{rc} == 1 ){
	print "Setting online successful:";
	print Dumper ($online_ret->{content});
}
else{
	print "Failed to set online.";
	print Dumper ($online_ret->{content});
}











