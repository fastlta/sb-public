#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use MIME::Base64;
use FAST::ApiPublic;
# use FAST::SBApiHelper;

my $ip = '172.100.51.175';
my $user = 'admin';
my $pass = 'adminadmin';

my $object = FAST::ApiPublic->new({
                                    host => $ip,
                                    user => $user,
                                    password => $pass,
                                });
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

my $vol         = $object->GetVolumeByName( {volume_name => 'Backup2DiskOffsite2'} );

print Dumper ($vol->{uuid});
# print Dumper($uuid);
# my $offline      = $object->SetVolumeOfflineByUUID( {volume_uuid => $uuid} );
# print Dumper ($vol);
# my $online      = $object->SetVolumeOnlineByUUID( {volume_uuid => $uuid} );


# print Dumper($offline);
# print Dumper($online);

# print Dumper $vols;

