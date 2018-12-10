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
my $ip = '172.100.51.247';
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

# ### Reading all Libraries
# my $libs        = $object->getLibraries();
# if( $libs->{rc} == 1 ){
# 	print "Found Libraries:";
# 	print Dumper ($libs->{content});
# }
# else{
# 	print "Failed to retrieve Libraries.";
# 	print Dumper ($libs->{content});
# }

# # ### Reading all Issues by type
# my $issues 		= $object->getOpenIssues( { type => "error" });
# if( $issues->{rc} == 1 ){
# 	print "Found Issues:";
#  	print Dumper ($issues->{content});
#  }
#  else{
#  	print "Failed to retrieve Issues.";
#  	print Dumper ($issues->{content});
#  }



# # ### Choose a valid UUID of your Volume. 
# # ### Use getVolumes to retrieve a valid list of Volumes
my $uuid = '69b5a696-f943-40d1-9f7e-e00fed5299ad';

# ### Reading Volume Details
# my $vols        = $object->getVolumeDetails( { volume_uuid => $uuid } );
# if( $vols->{rc} == 1 ){
# 	print "Found Volume:";
# 	print Dumper ($vols->{content});
# }
# else{
# 	print "Failed to retrieve Volume.";
# 	print Dumper ($vols->{content});
# }

### Setting a Volume offline by UUID
my $offline_ret   = $object->setVolumeOfflineByUUID( {volume_uuid => $uuid} );
if( $offline_ret->{rc} == 1 ){
	print "Setting offline successful:";
	print Dumper ($offline_ret->{content});
}
else{
	print "Failed to set offline.";
	print Dumper ($offline_ret->{content});
}

### Setting a Volume online by UUID
 my $online_ret      = $object->setVolumeOnlineByUUID( {volume_uuid => $uuid} );
 if( $online_ret->{rc} == 1 ){
 	print "Setting online successful:";
 	print Dumper ($online_ret->{content});
 }
 else{
 	print "Failed to set online.";
 	print Dumper ($online_ret->{content});
 }


# ### Listing all Free Bricks
# my $free_bricks_ret = $object->getFreeBricks( );
# if( $free_bricks_ret->{rc} == 1 ){
# 	print "Retrieval successful:";
# 	print Dumper ($free_bricks_ret->{content});
# }
# else{
# 	print "Failed to retrieve a list of free bricks.";
# 	print Dumper ($free_bricks_ret->{content});
# }


### Listing all Snapshots of a Volume by UUID
my $snapshots_ret      = $object->getSnapshotsByVolume( {volume_uuid => $uuid} );
if( $snapshots_ret->{rc} == 1 ){
	print "Retrieval successful:";
	print Dumper ($snapshots_ret->{content});
}
else{
	print "Failed to retrieve a list of snapshots";
	print Dumper ($snapshots_ret->{content});
}


### Creating a Snapshot for a Volume with the name of the Epoc Timestamp
my $snapshot_ret      = $object->setEpocSnapshotByUUID( {volume_uuid => $uuid} );
if( $snapshot_ret->{rc} == 1 ){
	print "Creating snapshot successful:";
	print Dumper ($snapshot_ret->{content});
}
else{
	print "Failed to create snapshot.";
	print Dumper ($snapshot_ret->{content});
}


# ### Delete a Snapshot by UUID

# my $snapshot_uuid = "a265261a-e26c-4862-9492-3c6d4734eec2"; 
# my $snapshotsdel_ret      = $object->deleteSnapshotByUUID( {snapshot_uuid => $snapshot_uuid} );
# if( $snapshotsdel_ret->{rc} == 1 ){
# 	print "Deletion successful:";
# 	print Dumper ($snapshotsdel_ret->{content});
# }
# else{
# 	print "Failed to delete snapshots";
# 	print Dumper ($snapshotsdel_ret->{content});
# }









