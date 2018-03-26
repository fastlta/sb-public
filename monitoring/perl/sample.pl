#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use MIME::Base64;
use FAST::ApiPublic;


my $ip = '172.100.51.175';
my $user = 'admin';
my $pass = 'adminadmin';

my $object = FAST::ApiPublic->new({
                                    host => $ip,
                                    user => $user,
                                    password => $pass,
                                });
# print Dumper ($object);



$object->SetHost({
        host => '172.100.51.68',
    });

$object->SetCredentials({
        user        => 'admin',
        password    => 'adminadmin',
    });


# $object->SetHeaders();

my $vols        = $object->GetVolumes();
print Dumper ($vols);

my $libs        = $object->GetLibraries();
print Dumper $libs;

my $uuid = '2a4de596-d9b8-4659-bcac-6836af838374';
# print Dumper($uuid);

# my $offline      = $object->SetVolumeOfflineByUUID( {volume_uuid => $uuid} );
# print Dumper $offline;

# my $online      = $object->SetVolumeOnlineByUUID( {volume_uuid => $uuid} );
# print Dumper $online;











