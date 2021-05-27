#! /usr/bin/perl
##################################################################
# Copyright 2020 FAST LTA GmbH
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
my $ip = '172.100.51.61';
my $user = 'admin';
my $pass = 'adminadmin';

my $SilentBrickAPI = FAST::ApiPublic->new({
                                    host => $ip,
                                    user => $user,
                                    password => $pass,
                                });



### Optional: Modifying Hostname
$SilentBrickAPI->setHost({
        host => $ip,

 });

### Optional: Modifying credentials
$SilentBrickAPI->setCredentials({
        user        => 'admin',
        password    => 'adminadmin',
    });


# ### Reading all Volumes
# my $vols        = $SilentBrickAPI->getVolumes();
# if( $vols->{rc} == 1 ){
# 	print "Found Volumes:";
# 	print Dumper ($vols->{content});
# }
# else{
# 	print "Failed to retrieve Volumes.";
# 	print Dumper ($vols->{content});
# }

# ### Reading all Libraries
# my $libs        = $SilentBrickAPI->getLibraries();
# if( $libs->{rc} == 1 ){
# 	print "Found Libraries:";
# 	print Dumper ($libs->{content});
# }
# else{
# 	print "Failed to retrieve Libraries.";
# 	print Dumper ($libs->{content});
# }

# # ### Reading all Issues by type
# my $issues 		= $SilentBrickAPI->getOpenIssues( { type => "error" });
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
#my $uuid = '69b5a696-f943-40d1-9f7e-e00fed5299ad';

# ### Reading Volume Details
# my $vols        = $SilentBrickAPI->getVolumeDetails( { volume_uuid => $uuid } );
# if( $vols->{rc} == 1 ){
# 	print "Found Volume:";
# 	print Dumper ($vols->{content});
# }
# else{
# 	print "Failed to retrieve Volume.";
# 	print Dumper ($vols->{content});
# }

### Setting a Volume offline by UUID
# my $offline_ret   = $SilentBrickAPI->setVolumeOfflineByUUID( {volume_uuid => $uuid} );
# if( $offline_ret->{rc} == 1 ){
# 	print "Setting offline successful:";
# 	print Dumper ($offline_ret->{content});
# }
# else{
# 	print "Failed to set offline.";
# 	print Dumper ($offline_ret->{content});
# }

# ### Setting a Volume online by UUID
#  my $online_ret      = $SilentBrickAPI->setVolumeOnlineByUUID( {volume_uuid => $uuid} );
#  if( $online_ret->{rc} == 1 ){
#  	print "Setting online successful:";
#  	print Dumper ($online_ret->{content});
#  }
#  else{
#  	print "Failed to set online.";
#  	print Dumper ($online_ret->{content});
#  }


# ### Listing all Free Bricks
# my $free_bricks_ret = $SilentBrickAPI->getFreeBricks( );
# if( $free_bricks_ret->{rc} == 1 ){
# 	print "Retrieval successful:";
# 	print Dumper ($free_bricks_ret->{content});
# }
# else{
# 	print "Failed to retrieve a list of free bricks.";
# 	print Dumper ($free_bricks_ret->{content});
# }


### Listing all Snapshots of a Volume by UUID
# my $snapshots_ret      = $SilentBrickAPI->getSnapshotsByVolume( {volume_uuid => $uuid} );
# if( $snapshots_ret->{rc} == 1 ){
# 	print "Retrieval successful:";
# 	print Dumper ($snapshots_ret->{content});
# }
# else{
# 	print "Failed to retrieve a list of snapshots";
# 	print Dumper ($snapshots_ret->{content});
# }


### Creating a Snapshot for a Volume with the name of the Epoc Timestamp
# my $snapshot_ret      = $SilentBrickAPI->setEpocSnapshotByUUID( {volume_uuid => $uuid} );
# if( $snapshot_ret->{rc} == 1 ){
# 	print "Creating snapshot successful:";
# 	print Dumper ($snapshot_ret->{content});
# }
# else{
# 	print "Failed to create snapshot.";
# 	print Dumper ($snapshot_ret->{content});
# }


# ### Delete a Snapshot by UUID

# my $snapshot_uuid = "a265261a-e26c-4862-9492-3c6d4734eec2"; 
# my $snapshotsdel_ret      = $SilentBrickAPI->deleteSnapshotByUUID( {snapshot_uuid => $snapshot_uuid} );
# if( $snapshotsdel_ret->{rc} == 1 ){
# 	print "Deletion successful:";
# 	print Dumper ($snapshotsdel_ret->{content});
# }
# else{
# 	print "Failed to delete snapshots";
# 	print Dumper ($snapshotsdel_ret->{content});
# }
# 

# ### List all Free Bricks
# my $freeBricks = $SilentBrickAPI->getFreeBricks();
# if( $freeBricks->{rc} == 1 ){
#  	print "Listing successful:";
#  	print Dumper ($freeBricks->{content});
# }
# else{
#  	print "Failed to list Bricks";
#  	print Dumper ($freeBricks->{content});
# }

# ### List all Bricks
# my $Bricks = $SilentBrickAPI->getBricks();
# if( $Bricks->{rc} == 1 ){
#  	print "Listing successful:";
#  	print Dumper ($Bricks->{content});
# }
# else{
#  	print "Failed to List Bricks";
#  	print Dumper ($Bricks->{content});
# }

# ### Get a Brick ID by serial
# my $Brick = $SilentBrickAPI->getBrickUUIDBySerial({brick_serial => 'W10AFDFD' });
# if( $Brick->{rc} == 1 ){
#  	print "Retrieving UUID successful:";
#  	print Dumper ($Brick->{content});
# }
# else{
#  	print "Failed retieve UUID";
#  	print Dumper ($Brick->{content});
# }

# # ### Set Brick Description by Serial
# my $UpdateBrick = $SilentBrickAPI->setBrickDescription({brick_serial => 'W10AFDFD', description => 'Test', display_mode => '3' });
# if( $UpdateBrick->{rc} == 1 ){
#  	print "Update successful:";
#  	print Dumper ($UpdateBrick->{content});
# }
# else{
#  	print "Failed to update";
#  	print Dumper ($UpdateBrick->{content});
# }

# ### Create Tape Library
my $CreateLib = $SilentBrickAPI->createLibrary({ name => "Test1",
													description => "Test123",
													vendor => "ADIC",
													product => "Scalar 1000",
													barcode_start => "3000001",
													barcode_end   => "3000ZZZ",
													tape_drive_vendor => "IBM",
													tape_drive_product => "ULT3580-TD5",
													tape_drive_prefix => "Drivee-",
													tape_drive_count  => "2",
													tape_name_prefix  => "Tapey-",
													tape_count => "2" });

if( $CreateLib->{rc} == 1 ){
 	print "Creation successful:";
 	print Dumper ($CreateLib->{content});
}
else{
 	print "Creation failed";
 	print Dumper ($CreateLib->{content});
}












