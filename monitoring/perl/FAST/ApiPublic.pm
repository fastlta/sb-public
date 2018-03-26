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
# Authors   : jgelhorn, rwr
# Version   : 1.0
# Date      : 22.02.2018
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
# print Dumper ($param);
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

#** @method public int getLibraries
#
#   @brief Reads all Libraries from the system
#   
#   @retval hash Returns hash with rc ( 0 or 1 ) and content
#*

sub getLibraries{

    my ($self, $param) = @_;

    my $endpoint      = 'libraries';
    my $headers     = $self->{headers};
    my $target      = $self->{target};

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->GET($endpoint, $headers);

    if ($response->{'_res'}{'_rc'} == 200) {

        my $data = decode_json($response->{'_res'}{'_content'});
        return { rc=>1, content=>$data };

    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return { rc=>0, content=>$error };
    }
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
    my $headers     = $self->{headers};
    my $target      = $self->{target};

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->GET($endpoint, $headers);
    if ($response->{'_res'}{'_rc'} == 200) {

        my $data = decode_json($response->{'_res'}{'_content'});
        return { rc=>1, content=>$data };

    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return { rc=>0, content=>$error};
    }

}

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
    my $headers     = $self->{headers};
    my $target      = $self->{target};
    my $task        = 'set_offline';
    my $payload      = undef;

    $endpoint       = $endpoint.'/'.$volume_uuid.'/'.$task;

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->PUT($endpoint, $payload, $headers);

    if ($response->{'_res'}{'_rc'} == 200) {

        my $data = decode_json($response->{'_res'}{'_content'});
        return { rc=>1, content=>$data };

    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return { rc=>0, content=>$error};
    }
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
    my $headers     = $self->{headers};
    my $target      = $self->{target};
    my $task        = 'set_online';
    my $payload      = undef;

    $endpoint       = $endpoint.'/'.$volume_uuid.'/'.$task;

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->PUT($endpoint, $payload, $headers);
# print Dumper ($response);
    if ($response->{'_res'}{'_rc'} == 200) {

        my $data = decode_json($response->{'_res'}{'_content'});
        return { rc=>1, content=>$data};

    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return {rc=>0, content=>$error};
    }
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

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->GET($endpoint, $headers);
    # print Dumper ($response);
    if ($response->{'_res'}{'_rc'} == 200) {

        my $data   = decode_json($response->{'_res'}{'_content'});
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
        my $error = ["$response->{'_res'}{'_msg'}"];
        return { rc=>0, content=>$error };
    }

}




1;


