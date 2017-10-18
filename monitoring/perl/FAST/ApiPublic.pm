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
my $class       = shift;        # $_[0] contains the class name
# my $number = shift;    
                                # $_[1] contains the value of our number
my $target      = shift;
my $headers     = undef;
my $method      = undef;
my $payload     = undef;
my $user        = undef;
my $password    = undef;



# it is given by the user as an argument
my $self        = {};        # the internal structure we'll use to represent
            # the data in our class is a hash reference
bless($self, $class);
# bless( $self, $class );    # make $self an object of class $class

$self->{target}     = $target;
$self->{method}     = $method;
$self->{headers}    = $headers;
$self->{user}       = $user;
$self->{password}   = $password;


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

### routine for setting method for targetcontroller
# needs : string containing method for api call
# returns : $self object
sub SetMethod{
    

    my ($self, $param)  = @_;



    my $method      = $param->{method};

    $self->{method} = $method;

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
    
    my $method      = 'libraries';
    my $headers     = $self->{headers};  
    my $target      = $self->{target}; 

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->GET($method, $headers);


    my $data = decode_json($response->{'_res'}{'_content'});

    return $data;
}


sub GetVolumes{

    my ($self, $param) = @_;
    
    my $method      = 'volumes';
    my $headers     = $self->{headers};  
    my $target      = $self->{target}; 

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

    my $client = REST::Client->new();
    $client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
    $client->setHost($target);

    my $response = $client->GET($method, $headers);
print Dumper ($response);
    my $data = decode_json($response->{'_res'}{'_content'});

    return $data;

}

1;


