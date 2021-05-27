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
# Authors   : jgelhorn, rwr
# Version   : 1.2
# Date      : 15.10.2018
# 
# Changelog : Adjusted to fit with the latest release 
#
##################################################################



package FAST::ApiPublic;

use strict;
use warnings;

use REST::Client;
use MIME::Base64;
use JSON;
use Data::Dumper;




#** @class FAST::ApiPublic
# 
#   @brief Class for Querying Silent Brick API
# 
#   This class is the base for commandline script to query or modify
#   the Silent Brick System
#   
#   @params host required Hostname or IP address of the Silent Brick System
#   @params user required Username for the Silent Brick User Interface
#   @params password required Password for the user
#   
#*

sub new {

    my $class        = shift;        
    my $param        = shift; 

    my $host = $param->{host}           || return "Error: No host set";
    my $user = $param->{user}           || return "Error: No user provided";
    my $password = $param->{password}   || return "Error: No password provided";


    my $headers     = {
                         Authorization => 'Basic '.encode_base64($user.':'.$password),
                         Accept        => 'application/json',
                        };
    my $target      = 'https://'."$host".'/sb-public-api/api/v1';


    my $self        = {};       
    bless($self, $class);

    $self->{host}       = $host;
    $self->{user}       = $user;
    $self->{password}   = $password;
    $self->{headers}    = $headers;
    $self->{target}     = $target;

    return $self;

}


#****************************************************** Connection Methods *******************************+*******#

#** @method public int setHost
#
#   @brief Sets the target in the class object
#   @params host Hostname or IP
#   @retval 1   Returns 1 and sets target of the class
#   
#*

sub setHost {
    my ($self, $param) = @_;

    my $ip = $param->{host};
    $self->{target} = 'https://'."$ip".'/sb-public-api/api/v1';

    return 1;
}

#** @method public int setHeaders
#
#   @brief Sets the headers in the class object
#   @retval 1 Returns 1 since only headers are set
#*

sub setHeaders {
    my ($self, $param) = @_;

    my $user        = $self->{user};
    my $password    = $self->{password};


    if ($param){
        my $headers = $param;
        $self->{headers} = $param;

    }else {
            $self->{headers}    = {
                                        Authorization => 'Basic '.encode_base64($self->{user}.':'.$self->{password}),
                                        Accept        => 'application/json',
                                    };
    }


    return 1;
}



#** @method public int setCredentials
#
#   @brief Sets the credentials in the class object
#   @params user Username for the Webinterface
#   @params password Password of the User
#   
#   @retval 1 Returns 1 since only headers are set
#*

sub setCredentials {

    my ($self, $param)  = @_;

    my $user            = $param->{user};
    my $pass            = $param->{password};

    $self->{user}       = $user;
    $self->{password}   = $pass;

    return 1;
}



#****************************************************** Generic Methods *******************************+*******#


#** @method public int getCall
#
#   @brief Sends a GET request to the API
#   @params get_string
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub getCall {

  
    my ($self, $param) = @_;

    my $get_string = $param->{endpoint} || return { rc=>0, content=>"No Endpoint String given" };

    my $headers     = $self->{headers};
    my $target      = $self->{target};


    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->GET($get_string, $headers);

    if ($response->{'_res'}{'_rc'} == 200) {
        my $data = decode_json($response->{'_res'}{'_content'});
        return { rc=>1, content=>$data };
    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return { rc=>0, content=>$error};
    }

}


#** @method public int setCall
#
#   @brief Sends a PUT request to the API
#   @params set_string
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub setCall {

    my ($self, $param) = @_;


    my $endpoint = $param->{endpoint} || return { rc=>0, content=>"No endpoint given" };
    my $payload  = $param->{payload}  || '';

   
    my $headers     = $self->{headers};
    my $target      = $self->{target};

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);


   if( $payload ){
        $payload = $client->buildQuery($payload);
   }



    my $response = $client->PUT($endpoint.$payload, undef, $headers);

    if ($response->{'_res'}{'_rc'} == 200) {
        my $data = decode_json($response->{'_res'}{'_content'});
        return { rc=>1, content=>$data };
    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return { rc=>0, content=>$error};
    }
}

#** @method public int setCall
#
#   @brief Sends a PUT request to the API
#   @params set_string
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub postCall {

    my ($self, $param) = @_;


    my $endpoint = $param->{endpoint} || return { rc=>0, content=>"No endpoint given" };
    my $payload  = $param->{payload}  || '';

   
    my $headers     = $self->{headers};
    my $target      = $self->{target};

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);


   if( $payload ){
        $payload = $client->buildQuery($payload);
   }



    my $response = $client->POST($endpoint.$payload, undef, $headers);

    if ($response->{'_res'}{'_rc'} == 200) {
        my $data = decode_json($response->{'_res'}{'_content'});
        return { rc=>1, content=>$data };
    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return { rc=>0, content=>$error};
    }
}

#** @method public int deleteCall
#
#   @brief Sends a DELETE request to the API
#   @params del_string
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub deleteCall {

    my ($self, $param) = @_;


    my $endpoint = $param->{endpoint} || return { rc=>0, content=>"No endpoint given" };
    

    my $headers     = $self->{headers};
    my $target      = $self->{target};



    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->DELETE($endpoint, $headers);

    if ($response->{'_res'}{'_rc'} == 200) {
        my $data = decode_json($response->{'_res'}{'_content'});
        return { rc=>1, content=>$data };
    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return { rc=>0, content=>$error};
    }
}


#****************************************************** Get Methods *******************************+*******#

#** @method public int getLibraries
#
#   @brief Reads all Libraries from the system
#   
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub getLibraries{

    my ($self, $param) = @_;

    my $endpoint      = 'libraries';

    return $self->getCall( { endpoint=>$endpoint } );


}


#** @method public int getVolumes
#
#   @brief Reads all Volumes from the system
#   
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub getVolumes{

    my ($self, $param) = @_;

    my $endpoint      = 'volumes';

    return $self->getCall( { endpoint=>$endpoint } );

}

#** @method public int getVolumeDetails
#
#   @brief Reads Partition information for a Volumes
#   @params volume_uuid UUID of the volume to be set offline
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub getVolumeDetails{

    my ($self, $param) = @_;

    my $volume_uuid = $param->{volume_uuid} || return { rc=>0, content=>"No Volume UUID given" };

    my $endpoint    = 'volumes';
    my $task        = "partitions";

    $endpoint       = $endpoint.'/'.$volume_uuid.'/'.$task;

    return $self->getCall( { endpoint=>$endpoint } );

}


#** @method public int getOpenIssues
#
#   @brief Reads all open issues from the system
#   @params type Optional. May be all (default), error, info, warning. 
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*
sub getOpenIssues {

    my ($self, $param) = @_;

    my $issues_type = $param->{type} || 'all';

    my $endpoint      = 'open_issues';
    my $headers     = $self->{headers};
    my $target      = $self->{target};


    my $response = $self->getCall( { endpoint=>$endpoint } );

    if ($response->{'rc'} == 1) {

        my $data   = $response->{'content'};
        my @issues; 
        
        if( lc $issues_type ne "all" ){
            foreach my $issue( @{$data} ){
                if( lc $issue->{'Error Level'} eq lc $issues_type ){
                    push( @issues, $issue );
                }
            }
        }else{
            @issues = @{$data};
        }

        
        return { rc=>1, content=>\@issues};

    }else {
        my $error = ["$response->{'content'}"];
        return { rc=>0, content=>$error };
    }

}



#** @method public int getFreeBricks
#
#   @brief Returns a list of all free or unassigned bricks
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub getFreeBricks {


   my ($self, $param) = @_;

    my $endpoint      = 'bricks';
    
    return $self->getCall( { endpoint=>$endpoint } );

}

#** @method public int getBricks
#
#   @brief Returns a list of all bricks
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub getBricks {


   my ($self, $param) = @_;

    my $endpoint      = 'bricks.json?all';
    
    return $self->getCall( { endpoint=>$endpoint } );

}

#** @method public int getBrickUUIDBySerial
#
#   @brief Returns a list of all bricks
#   @param brick_serial Serial of the Brick
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub getBrickUUIDBySerial {

   my ($self, $param) = @_;

    my $brick_serial = $param->{brick_serial} || return { rc=>0, content=>"No Serial given" };


    my $endpoint      = 'bricks.json?all';
    
    my $bricks = $self->getCall( { endpoint=>$endpoint } );


    if( $bricks->{rc} == 1 ){
        foreach( @{$bricks->{content}->{bricks}} ){
            if( $_->{serial} eq $brick_serial ){
               return { rc=>1, content => $_->{uuid} };
           }
        }
    }

    return { rc=>0, content=>"Unknown Brick" };

}




#** @method public int getSnapshotsByVolume
#
#   @brief Returns a list of all Snapshots by Volume UUID
#   @params volume_uuid UUID of the volume to be set offline
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub getSnapshotsByVolume {

  
    my ($self, $param) = @_;

    my $volume_uuid = $param->{volume_uuid} || return { rc=>0, content=>"No Volume UUID given" };

    my $endpoint    = 'volumes';
    my $task        = "list_snapshots";

    $endpoint       = $endpoint.'/'.$volume_uuid.'/'.$task;

    return $self->getCall( { endpoint=>$endpoint } );


}


#**************************** Set Methods ********************************#
 

#** @method public int setVolumeOfflineByUUID
#
#   @brief Sets a defined volume to offline
#   @params volume_uuid UUID of the volume to be set offline
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub setVolumeOfflineByUUID {

    my ($self, $param) = @_;

    my $volume_uuid = $param->{volume_uuid};

    my $endpoint    = 'volumes';
    my $task        = 'set_offline';
    my $payload      = undef;

    $endpoint       = $endpoint.'/'.$volume_uuid.'/'.$task;

    return $self->setCall( { endpoint=>$endpoint, payload=>$payload });
}


#** @method public int setVolumeOnlineByUUID
#
#   @brief Sets a defined volume to online
#   @params volume_uuid UUID of the volume to be set offline
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub setVolumeOnlineByUUID {

    my ($self, $param) = @_;

    my $volume_uuid = $param->{volume_uuid};

    my $endpoint    = 'volumes';
    my $task        = 'set_online';
    my $payload      = undef;

    $endpoint       = $endpoint.'/'.$volume_uuid.'/'.$task;

    return $self->setCall( { endpoint=>$endpoint, payload=>$payload });
}


#** @method public int setEpocSnapshotByUUID
#
#   @brief Sets a snapshot with epoc name on a volume
#   @params volume_uuid UUID of the volume to be set offline
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub setEpocSnapshotByUUID {

    my ($self, $param) = @_;

    my $volume_uuid = $param->{volume_uuid};

    my $endpoint    = 'volumes';
    my $task        = 'snapshot';
    my $epoc        = time();
    my $payload     = { name=>$epoc, description=>"Snapshot created via API Call" };
    $endpoint       = $endpoint.'/'.$volume_uuid.'/'.$task;


    return $self->setCall( { endpoint=>$endpoint, payload=>$payload } );
}

#** @method public int setBrickDetails
#
#   @brief Sets a defined volume to online
#   @params brick_serial Serial of the silent brick to be updated
#   @params description New Description to be set
#   @params display_mode Display Mode for the Brick Display
#       Int displaymode 
#           0 = QR - Description + ContainerID
#           1 = QR - Description only
#           2 = Text Display - Top & Left Aligned
#           3 = Text Display - Top & Center
#           4 = Text Display - Top & Right Aligned
#           5 = Text Display - Middle & Center
#       String Description
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*
sub setBrickDescription {

    my ($self, $param) = @_;

    my $brick_serial = $param->{brick_serial} || { rc=>0, content=>"Serial needed" };
    my $description = $param->{description} || '';
    my $display_mode = $param->{display_mode} || 0;

    my $brick_get_uuid = $self->getBrickUUIDBySerial( { brick_serial => $brick_serial });

    if( $brick_get_uuid->{rc} != 1 ){
        return { rc=>0, content=>"Brick not found" };
    }

    my $brick_uuid = $brick_get_uuid->{content};


    my $endpoint    = 'bricks';
    my $payload      ={ description=>$description, display_mode=>$display_mode };

    $endpoint       = $endpoint.'/'.$brick_uuid;

    return $self->setCall( { endpoint=>$endpoint, payload=>$payload });
}


#** @method public int createLibrary
#
#   @brief Creates a new Library
#   @params name Name of the Library
#   @params description Description field of the Library
#   @params vendor Library Vendor 
#               FAST-LTA
#               ADIC
#               SPECTRA
#               HP
#   @params product Library Product ID
#               "Scalar 1000" for ADIC
#               "Scalar 24" for ADIC
#               "SBL 2000" for FAST-LTA
#               "ESL E-Series" for HP
#               "MSL6480 Series" for HP
#               "PYTHON" for SPECTRA
#   @params barcode_start Beginning of the Barcode range ( i.e. 200001 )
#   @params barcode_end End of the Barcode range ( i.e. 200ZZZ )     
#   @params tape_drive_prefix Prefix of the Tape Drives
#   @params tape_drive_vendor Vendor of the Tape Drive
#               "HP"
#               "IBM"
#               "QUANTUM"
#   @params tape_drive_product Product ID of the Drive
#               "Ultrium 5-SCSI" for HP
#               "ULT3580-TD5" for IBM
#               "ULTRIUM 5" for QUANTUM
#   @params tape_drive_count Amount of tape drives
#   @params tape_name_prefix Name prefix of the tapes
#   @params tape_count Number of tapes to be created.
#   @params brick_uuids Array of Brick UUIDs to assign
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*
sub createLibrary {

    my ($self, $param) = @_;

    my $name        = $param->{name} || { rc=>0, content=>"Name needed" };
    my $description = $param->{description} ||"";
    my $vendor      = $param->{vendor} || "ADIC";
    my $product     = $param->{product} || "Scalar 1000";
    my $barcode_start = $param->{barcode_start} || { rc=>0, content=>"Barcode Start needed" };
    my $barcode_end = $param->{barcode_end} || { rc=>0, content=>"Barcode End needed" };
    my $tape_drive_prefix = $param->{tape_drive_prefix} || "Drive-";
    my $tape_drive_vendor = $param->{tape_drive_vendor} || "IBM";
    my $tape_drive_product = $param->{tape_drive_product} || "ULT3580-TD5";    
    my $tape_drive_count = $param->{tape_drive_count} || 1;   
    my $tape_name_prefix = $param->{tape_name_prefix} || "Brick-";
    my $tape_count  = $param->{tape_count} || 1;

    # Adding Bricks not supported at the Moment.
    # Reason: Transformation of the Array not correct by url builder.


    my $endpoint    = 'libraries.json';
    my $payload      ={ library_name => $name,
                        library_description => $description,
                        library_vendor => $vendor,
                        library_product => $product,
                        barcode_start => $barcode_start,
                        barcode_end   => $barcode_end,
                        tape_drive_prefix => $tape_drive_prefix,
                        tape_drive_vendor => $tape_drive_vendor,
                        tape_drive_product => $tape_drive_product,
                        tape_drive_count => $tape_drive_count,
                        tape_count => $tape_count
                    };

    $endpoint       = $endpoint;

    return $self->postCall( { endpoint=>$endpoint, payload=>$payload } );
}





#**************************** Delete Methods ********************************#

#** @method public int deleteSnapshotByUUID
#
#   @brief Deletes a snapshot by uuid
#   @params snapshot_uuid UUID of the Snapshot
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub deleteSnapshotByUUID {

    my ($self, $param) = @_;

    my $snapshot_uuid = $param->{snapshot_uuid};

    my $endpoint    = 'snapshots';
 
    $endpoint       = $endpoint.'/'.$snapshot_uuid;


    return $self->deleteCall( { endpoint=>$endpoint } );
}

#** @method public int unassignBrick
#
#   @brief Removes Brick from Tape Libraries or from a Volume
#   @params brick_serial Serial of the Brick
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

# sub unassignBrick {
#
#     my ($self, $param) = @_;
#
#     my $brick_serial = $param->{brick_serial} || { rc=>0, content=>"Serial needed" };
#   
#
#     my $endpoint    = 'bricks';
#     my $task        = 'unassign';
#     $endpoint       = $endpoint.'/'.$task;
#
#     my $brick_get_uuid = $self->getBrickUUIDBySerial( { brick_serial => $brick_serial });
#
#     if( $brick_get_uuid->{rc} != 1 ){
#         return { rc=>0, content=>"Brick not found" };
#     }
#
#     my $brick_uuid = $brick_get_uuid->{content};
#
#     my $payload      ={ brick_uuids=> [$brick_uuid] };
#
#     # PROBLEM: Array in Payload not correctly transformed
#     return $self->setCall( { endpoint=>$endpoint, payload=>$payload } );
# }




1;


