package FAST::ApiPublic;

use strict;
use warnings;

use REST::Client;
use MIME::Base64;
use JSON;
use Data::Dumper;


use Exporter qw(import);

our @EXPORT_OK = qw(new );


sub new        # constructor, this method makes an object
        # that belongs to class Number
{
    my $class        = shift;        # $_[0] contains the class name
    my $param        = shift; 
# print Dumper ($param);
    my $host = $param->{host}           || return "Error: No host set";
    my $user = $param->{user}           || return "Error: No user provided";
    my $password = $param->{password}   || return "Error: No password provided";

    # my $number = shift;
                                # $_[1] contains the value of our number
    # my $host        = shift;
    # my $user        = shift;
    # my $password    = shift;
    my $headers     = {
                         Authorization => 'Basic '.encode_base64($user.':'.$password),
                         Accept        => 'application/json',
                        };
    my $target      = 'https://'."$host".'/sb-public-api/api/v1';

# it is given by the user as an argument
    my $self        = {};        # the internal structure we'll use to represent
            # the data in our class is a hash reference
    bless($self, $class);
# bless( $self, $class );    # make $self an object of class $class

    $self->{host}       = $host;
    $self->{user}       = $user;
    $self->{password}   = $password;
    $self->{headers}    = $headers;
    $self->{target}     = $target;
# $self->{num} = $number;    # give $self->{num} the supplied value
            # $self->{num} is our internal number
return $self;        # a constructor always returns an blessed()
            # object
}



sub SetHost {
    my ($self, $param) = @_;

    my $ip = $param->{host};
    $self->{target} = 'https://'."$ip".'/sb-public-api/api/v1';

    return 1;
}


### Routine to set headers to use for api call
# needs : hash reference containing all headers to use
# returns : self object
sub SetHeaders {
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


    # my $headers = $param;
    # $headers->{'Authorization'} = 'Basic '.encode_base64($user.':'.$password);

    # $self->{headers} = $headers;

    return 1;
}



sub SetCredentials {

    my ($self, $param)  = @_;

    my $user            = $param->{user};
    my $pass            = $param->{password};

    $self->{user}       = $user;
    $self->{password}   = $pass;

    return 1;
}

sub GetLibraries{

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
        return $data;

    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return $error;
    }
}


sub GetVolumes{

    my ($self, $param) = @_;

    my $endpoint      = 'volumes';
    my $headers     = $self->{headers};
    my $target      = $self->{target};

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->GET($endpoint, $headers);
# print Dumper ($response);
    if ($response->{'_res'}{'_rc'} == 200) {

        my $data = decode_json($response->{'_res'}{'_content'});
        return $data;

    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return $error;
    }

}

sub SetVolumeOfflineByUUID {

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
# print Dumper ($response);
    if ($response->{'_res'}{'_rc'} == 200) {

        my $data = decode_json($response->{'_res'}{'_content'});
        return $data;

    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return $error;
    }
}

sub SetVolumeOnlineByUUID {

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
        return $data;

    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return $error;
    }
}

sub GetVolumeByName {
    
    my ($self, $param) = @_;
   
    my $volume_name   = $param->{volume_name}; 
    my $endpoint      = 'volumes';
    my $headers     = $self->{headers};
    my $target      = $self->{target};

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->GET($endpoint, $headers);
# print Dumper ($response);
    if ($response->{'_res'}{'_rc'} == 200) {
        my $vols =  decode_json($response->{'_res'}{'_content'});
        
        foreach my $item (@$vols) {
            if ($item->{name}=~ m/$volume_name/){
                return $item;
            }
        }
        
        # my $data = decode_json($response->{'_res'}{'_content'});
        # return $data;

    }else {
        my $error = ["$response->{'_res'}{'_msg'}"];
        return $error;
    }



}



1;


