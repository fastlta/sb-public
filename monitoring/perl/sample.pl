#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use MIME::Base64;
use FAST::ApiPublic;
# use FAST::SBApiHelper;

my $ip = '172.100.51.98';
my $user = 'admin';
my $pass = 'adminadmin';


    my $headers_default = {
                        Authorization => 'Basic '.encode_base64($user.':'.$pass),
                         Accept        => 'application/json',
                        }; 




my $object = FAST::ApiPublic->new($ip, $user, $pass );
# print Dumper ($object);



# $object->SetHost({
#         host => '172.100.51.98',
#     });

# $object->SetCredentials({
#         user        => 'support',
#         password    => '1qay2wsx#',
#     });


# $object->SetHeaders();



# my $serials     = $object->GetBrickSerials();
# my $uuids       = $object->GetBrickUuids();

# my $libs        = $object->GetLibraries();
# my $vols        = $object->GetVolumes();

# print Dumper $vols;

