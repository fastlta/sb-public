#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use MIME::Base64;
use FAST::ApiPublic;
# use FAST::SBApiHelper;

my $ip = '172.100.51.175';


my $object = FAST::ApiPublic->new();

$object->SetHost({
        host => $ip,
    });

# print Dumper ($object->{target});

$object->SetCredentials({
        user        => 'admin',
        password    => 'adminadmin',
    });


$object->SetHeaders();



# my $serials     = $object->GetBrickSerials();
# my $uuids       = $object->GetBrickUuids();

my $libs        = $object->GetLibraries();
my $vols        = $object->GetVolumes();

print Dumper $vols;
# my $lib_uuids   = $object->GetLibrary_UUIDS();

# print Dumper ($object->GetBrickUUID_BySerial({serial => 'B10A0365'}));
# print Dumper  ($uuids);
# print Dumper ($serials);

print Dumper  ($libs);
# print Dumper  ($vols);
# print Dumper  ($lib_uuids);

# print Dumper ($object->GetLibrary_UUIDS());


# print Dumper ($object);


