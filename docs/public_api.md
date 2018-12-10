# FAST LTA AG - Silent Bricks Public REST API Description

__Version:__ API v2.  for Silent Bricks Software R 2.15 (Version 2.15.0.9)  
__Date:__ December 2018

__Terms used:__

- Silent Brick Library: The whole system
- Tape Library: A single, emulated tape library
- Tape: Emulated tape instance, equivalent to a single Silent Brick
# Silent Bricks API Description

Terms used:

- Silent Brick Library: The whole system
- Tape Library: A single, emulated tape library
- Tape: Emulated tape instance, equivalent to a single Silent Brick

## Library Operations

### Using mtx for tape library operations

For normal tape library operations like moving tapes from a library slot into a
tape drive, a standard SCSI client like `mtx` should be used.

### Using mt for tape drive operations

For operations on a tape drive, like changing compression settings or querying
the status, a standard SCSI client like `mt` should be used.

## API Basics:

### REST API

The API can be accessed using standard HTTP Commands, following the basic
principles of REST, see
<http://en.wikipedia.org/wiki/Representational_state_transfer>.

### API Fundamentals

For accessing the API the following information has to be known:

- Silent Brick Library IP or hostname.
- Username and password of a SysAdmin User of the Silent Brick Library.

### API Access

The basic API Endpoint looks like this (given a library with the IP "172.100.51.240")

    https://172.100.51.240/sb-public-api/api/v1

Please note that communication is always encrypted with SSL/TLS and happens on
port 443. By default, the endpoint certificate does not have a valid
certificate chain and must be trusted by the client. Pure HTTP communication is
not supported.

### Authentication:

All calls must be authenticated using Basic HTTP authentication
(see [RFC 2617](https://www.ietf.org/rfc/rfc2617.txt)).
Username and password of a SysAdmin User of the Silent Brick Library are required.

### Request/Response encoding

Requests should be encoded with UTF-8, the response will be in JSON format.
This can be achieved by setting the content type like this:

    Content-type: application/json; charset=utf-8

or by using '.json' in the URL

### Status codes

The HTTP status code of the response sent back by the server encodes the result
of the API call. The following status codes are used by all API endpoints:

- `200 (Ok)` The request was successfully processed by the server, the
  operation was executed, data were delivered.
- `400 (Bad Request)` Failed to execute operation on the requested resource.
- `401 (Unauthorized)` Authentication failed.
- `403 (Forbidden)` The client tries to start a new task while a background task is active.
- `404 (Not Found)` The client requests a resource which does not exist.

In case of an error (status-code `4xx`) the response body encodes a message
like this:

    {
      "code": <the http status code>
      "msg": "<a detailed error message>"
    }

## Note

To ensure a correct response format always append `.json` to your request URL as shown in the
examples below.

## API Calls

## General Brick Operations

### Listing Free Bricks

With this call you can list all the free or unassigned bricks.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/bricks.json

Response body example:

    {
        "bricks": [
          {
            "uuid": "645aac61-a54b-46fe-aaeb-a44b047f9565",
            "serial":"V10AFDF1",
            "type":"HDD",
            "gross_capacity":3995903488,
            "net_capacity":3990496256,
            "status":"online",
            "unassigned":"Yes",
          },
          {
            ... info for next brick
          }
                  ]
    }

### Listing All Bricks

To display all bricks in the system(assigned and unassigned)

Request:

    GET -F https://172.100.51.240/sb-public-api/api/v1/bricks.json?all

Response body example:

    {
        "bricks": [
          {
            "uuid": "da14bdcb-966b-425f-8088-62740760e756",
            "serial":"V10AFDE9",
            "type":"HDD",
            "gross_capacity":3995903488,
            "net_capacity":3990496256,
            "status":"online",
          "unassigned":"No",
            "v_devs": [
              {
                "uuid":"8dd53317-ef74-4869-a2f0-5e162d2d5c0b",,
                "span_index":0,
                "net_size":3835691008,
                "net_used":454656,
                "audit_location":454656
              }
            ]
          },
          {
            "uuid": "7fcbf628-1575-4555-8da3-8757132dfb09",
            "serial":"V10AFDEE",
            "type":"HDD",
            "gross_capacity":3995903488,
            "net_capacity":3990496256,
            "status":"online",
          "unassigned":"No",
            "tapes": [
              {
                "uuid":"52c99404-00b1-46d6-adf8-f710d6bfe1bc",
                "name":"Brick-0001",
                "label":"100001L5",
                "net_size":3835691008,
                "net_used":454656,
                "audit_location":454656
              }
            ]
          },
          {
            "uuid": "c0707153-2ee3-4cd3-9f70-224d0604ec7a",
            "serial":"V10AFDEC",
            "type":"HDD",
            "gross_capacity":3995903488,
            "net_capacity":3990496256,
            "status":"online",
          "unassigned":"No",
            "partitions": [
              {
                "uuid":"8dd53317-ef74-4869-a2f0-5e162d2d5c0b",,
                "span_index":0,
                "net_size":3835691008,
                "net_used":454656,
                "audit_location":454656
              }
            ]
          },
          {
            ... info for next brick
          }
       ]
    }

### Updating Bricks

Given the brick uuid a brick can be updated
with this call:

    PUT https://172.100.51.240/sb-public-api/api/v1/bricks/<brick-uuid>.json

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT https://172.100.51.240/sb-public-api/api/v1/bricks/<brick-uuid>.json?<key>=<value>

The update-information can also be form-data encoded in the payload of the HTTP
request. See [RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/bricks/<brick-uuid>.json

A `key` can be:

- `description`  The description for the brick
- `display_mode` The description display mode

    - `0`  QR Display   - Description + Container ID
    - `1`  QR Display   - Description Only
    - `2`  Text Display - Top & Left Aligned
    - `3`  Text Display - Top & Center
    - `4`  Text Display - Top & Right  Aligned
    - `5`  Text Display - Middle & Center

- `qr`  Updates the string encoded in the QR code displayed in front of the
        brick. When the `value` starts with a `=`, then the complete string is
        replaced. Otherwise the string is prepended to the QR code.

- `find_me`      To toggle on/off the beacon

    - `0`  To switch off
    - `1`  To switch on   

Any other keys are ignored.

Please note that description can be updated either with (`description` and `display_mode`) or only `qr`. The three keys should not be used together

### Unassign Bricks

Given the brick uuid, the brick can be unassigned from its associated library or volume. A brick can only be unassigned from volume/libraries if they don't contain any partitions.
with this call:

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/bricks/unassign.json

A `key` can be:

- `brick_uuids`  The brick_uuids to be unassigned as an array

## VTL Operations

### List Library Emulations

With this call you can list all available library types to create a new library.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/libraries/library_emulations.json

Response body example:

  {
        "library_types": [
        {
          "vendor_identification": "ADIC",
          "product_identification": "Scalar 1000",
          "default_revision_level": "500A"
        },
          {
            ... info for next library type
          }
        ]
  }

### List Tape Drive Emulations

With this call you can list all available tape drive types.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/libraries/tape_drive_emulations.json

Response body example:

  {
      "tape_drive_types": [
        {
          "vendor_identification": "IBM",
          "product_identification": "ULTRIUM-TD3",
          "default_revision_level": "54K1"
        },
        {
         ... info for next tape drive type
        }
      ]
    }

### Create Library

Creates a library. Only one type of tape drive is allowed per Library.

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X POST -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/libraries.json

A `key` can be:

- `library_name`            The name of the library
- `library_description`     The description for the library
- `library_type`            The type of the library to be created( Default: LBL )
- `library_vendor`          The library vendor( Default: FAST-LTA )
- `library_product`         The library product( Default: SBL 2000 )   
- `custom_library_revision` The custom revision of the library

Please enter the barcode range to use for new media. A-Z and 0-9 are allowed characters.
A length of 6 characters is recommended (maximum 32). The first three characters of the
start and end specifiers must match (e.g. 'TTT000' and 'TTTZZZ'). If the range end specifier
ends with '999' (e.g. 'XXX000' to 'XXX999') the generated barcodes will consist of numbers only.

- `barcode_start`           The start pattern for tape barcode
- `barcode_end`             The end pattern for tape barcode

- `tape_drive_prefix`       The (prefix-)name of the tape drive(s)
- `tape_drive_vendor`       The tape drive vendor( Default: IBM )
- `tape_drive_product`      The tape drive product( Default: ULT3580-TD5 )
- `tape_drive_count`        The count of tape drives( Default: 1 )

- `tape_name_prefix`        The (prefix-)name of the tapes
- `tape_count`              The number of tapes to be created.All the available bricks will be formatted if empty
- `brick_uuids`             The uuids of the bricks as an array. If brick_uuids are not given an empty library is created.

Response body example:

     {
        "name": "Lib01",
        "description": "Test library sb-public-api",
        "uuid": "14c6daa8-2be9-4f1c-bca9-62a4cd49073f",
        "num_storage_slots": 47,
        "num_export_slots": 47,
        "vendor_identification": "FAST-LTA",
        "product_identification": "SBL 2000",
        "product_revision_level": "100A",
        "num_drives": 1,
        "drives": [
          {
            "drive_index": 10,
            "emulation_revision_level": "",
            "loaded_tape_uuid": null,
            "name": "Drive-0001",
            "tape_drive_uuid": "becbb7d7-579c-4487-bd65-400ee3e9ecfe",
            "description": "IBM TS1050",
            "vendor_identification": "IBM",
            "product_identification": "ULT3580-TD5",
            "product_revision_level": "B170"
          }
        ]
      }

### Update Library

Given the library-uuid a library can be updated

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>.json

A `key` can be:

- `library_name`            The name of the library
- `library_description`     The description for the library
- `library_vendor`          The library vendor
- `library_product`         The library product
- `custom_library_revision` The custom revision of the library

Please enter the barcode range to use for new media. A-Z and 0-9 are allowed characters.
A length of 6 characters is recommended (maximum 32). The first three characters of the
start and end specifiers must match (e.g. 'TTT000' and 'TTTZZZ'). If the range end specifier
ends with '999' (e.g. 'XXX000' to 'XXX999') the generated barcodes will consist of numbers only.

- `barcode_start`           The start pattern for tape barcode
- `barcode_end`             The end pattern for tape barcode
- `storage_slots`           The number of storage slots required
- `export_slots`            The number of export slots required

Any other keys are ignored

### Add Drives To Library

Given the library uuid drives can be assigned to the library. Only one type of tape drive is allowed per Library.

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/assign_drives.json

A `key` can be:

- `tape_drive_prefix`       The (prefix-)name of the tape drive(s)
- `tape_drive_vendor`       The tape drive vendor( Default: IBM )
- `tape_drive_product`      The tape drive product( Default: ULT3580-TD5 )
- `tape_drive_count`        The count of tape drives( Default: 1 )

### Add Bricks To Library

Given the library uuid bricks can be assigned to the library.

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/assign_bricks.json

A `key` can be:

- `brick_uuids`             The uuids of the bricks as an array.

Keys to format the bricks.

- `tape_name_prefix`        The (prefix-)name of the tapes.
- `tape_count`              The number of tapes to be created. All bricks are formatted if not provided.

### Format Bricks in the Library

Given the library uuid, the unformatted bricks already assigned to the library can be formatted.

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/format.json

A `key` can be:

- `brick_uuids`           The uuids of the bricks to format as an array.
- `tape_name_prefix`      The (prefix-)name of the tapes.

### Erase Tapes in the library

Given the library uuid, the library tapes can be erased. They will not be un-assigned from the library after a successful erase.

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/erase.json

A `key` can be:

- `tape_uuids`           The uuids of the tapes to erase as an array.

### Listing tape libraries and drives

With this call you can list all available tape libraries and their corresponding drives.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/libraries.json

Response body example:

    {
      "libraries": [
             {
               "name": "L1",
               "description": "",
               "uuid": "da14bdcb-966b-425f-8088-62740760e756",
               "num_storage_slots": 47,
               "num_export_slots": 47,
               "vendor_identification": "FAST-LTA",
               "product_identification": "SBL 2000",
               "product_revision_level": "100A",
               "num_drives": 2,
               "drives": [
                 {
                   "drive_index": 2,
                   "emulation_revision_level": "",
                   "loaded_tape_uuid": null,
                   "name": "HP-Ultrium 5-SCSI-0002",
                   "tape_drive_uuid": "be13ce9d-6b31-4f99-963e-7ed581689061",
                   "description": "HP Ultrium 3000",
                   "vendor_identification": "HP",
                   "product_identification": "Ultrium 5-SCSI",
                   "product_revision_level": "Z23D"
                 },
                 {
                   "drive_index": 1,
                   "emulation_revision_level": "",
                   "loaded_tape_uuid": "2c111621-216a-4252-a854-0e2a6cf5a824",
                   "name": "HP-Ultrium 5-SCSI-0001",
                   "tape_drive_uuid": "d3df1092-4f0d-4037-b8bf-c3ff42ee6af3",
                   "description": "HP Ultrium 3000",
                   "vendor_identification": "HP",
                   "product_identification": "Ultrium 5-SCSI",
                   "product_revision_level": "Z23D"
                 }
               ]
             },
             {
               ... info for next library
             }
        ]
      }

### Listing tapes inside a library.

Given a library uuid, the corresponding tapes can be listed with this call.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/tapes.json

Response body example:

     {
         "tapes":[
           {
             "uuid": "47be86ca-422a-4e36-a35e-2af19ccb8175",
             "name": "Brick-0003",
             "label": "100003L5",
             "net_size": 990496768,
             "net_used": 0,
             "audit_location": 0,
             "status": "online"
           },
           {
              ... info for next tape
           }
        ]
     }

The `status` can be

- `online` The tape is ready and online.
- `unlocked` The tape is unlocked for eject.
- `ejected` The tape is ejected.
- `transport` The tape is in transport mode.
- `error` The tape is in an error state.

The current audit position is found in the value `audit_location`. Because the
current default is _Audit after Write_, the value `net_used` is always equal
to the value `audit_location`. All data is therefore generally audited at least
once. Independently of this, each brick will be audited again once per month or
1/30 per day.

### Updating tapes

Given the library uuid and the tape uuid properties of a tape can be updated
with this call:

    PUT https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/tapes/<tape-uuid>.json

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/tapes/<tape-uuid>.json?<key>=<value>

The update-information can also be form-data encoded in the payload of the HTTP
request. See [RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/tapes/<tape-uuid>.json


A `key` can be:

- `qr` Updates the string encoded in the QR code displayed in front of the
  brick. When the `value` starts with a `=`, then the complete string is
  replaced. Otherwise the string is prepended to the QR code.

Any other keys are ignored.

### Unlocking/Locking tapes for eject

Unlock a tape for eject (i.e.) the tape can be ejected with the touch of the
front sensor. A tape that is loaded into a drive can NOT be unlocked and the
call will generate an error.

Given the library uuid and the tape uuid a tape can be unlocked with this call:

    PUT https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/tapes/<tape-uuid>/unlock.json

To lock a tape again so that the touch sensor is disabled, call:

    PUT https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/tapes/<tape-uuid>/lock.json

### Delete library

Given the library uuid, an empty library can be deleted. Please make sure all the bricks are removed from the library before attempting to delete it.

Request:

    DELETE https://172.100.51.240/sb-public-api/api/v1/libraries/<library_uuid>.json

## SNAS Operations

## Volume Operations

### Listing volumes

With this call you can list all available volumes(SNAS ERC, SNAS 2P, SNAS 3P).

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/volumes.json

Response body example:

    {
      "volumes": [
        {
          "name": "Vol01",
          "description": "Test Volume One",
          "volume_type": "snas_3p",
          "status": "online",
          "mode": "plain",
          "uuid": "26e10c4b-7823-400e-8b3a-f9e29f64ca60",
          "size": 1496927616,
          "used": 76743
        },
        {
          "name": "Vol02",
          "description": "Test Volume Two",
          "volume_type": "snas_erc",
          "status": "online",
          "mode": "plain",
          "uuid": "f35dc74e-0ce9-440b-b9ac-0ec7603ebaf5",
          "size": 1995903488,
          "used": 35079
        },
        {
          ... info for next volume
        }
      ]
    }

The `volume_type` can be

- `snas_2p`  SNAS with protection level of 2
- `snas_3p`  SNAS with protection level of 3
- `snas_erc` SNAS ERC

The `status` can be

- `incomplete` The volume is incomplete, at least one partition is missing.
- `online` The volume is ready and online.
- `readonly` The volume is online but read-only.
- `offline` The volume is offline and cannot be used.
- `transport` An operation is currently running.
- `error` The volume is in an error state.

### Listing partitions inside all available volume types

A volume consists of at least one Brick, which is called _partition_ in this context.
Given a volume uuid, the corresponding partitions can be listed with this call.

    GET https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/partitions.json

Response body example:

    {
        "partitions": [
          {
            "uuid": "47be86ca-422a-4e36-a35e-2af19ccb8175",
            "span_index": 0,
            "net_size": 990496768,
            "net_used": 0,
            "audit_location": 0,
            "status": "online"
          },
          {
            ... info for next partition
          }
        ]
    }

The `status` can be

- `online` The partition is ready and online.
- `unlocked` The partition is unlocked for eject.
- `ejected` The partition is ejected.
- `transport` The partition is in transport mode.
- `error` The partition is in an error state.

The current audit position is found in the value `audit_location`. Because the
current default is _Audit after Write_, the value `net_used` is always equal
to the value `audit_location`. All data is therefore generally audited at least
once. Independently of this, each brick will be audited again once per month or
1/30 per day.

### Get Volume State

Given the volume uuid, the volume state is listed

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/state.json

Response body example:

    {
     "state": "online"
  }

The `state` can be

- `incomplete` The volume is incomplete, at least one partition is missing.
- `online` The volume is ready and online.
- `readonly` The volume is online but read-only.
- `offline` The volume is offline and cannot be used.
- `transport` An operation is currently running.
- `error` The volume is in an error state.

### Create Volume

Creates a volume.Volumes cannot be used without assigning bricks.

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X POST -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes.json

A `key` can be:

- `name`  The name of the volume.  ( Must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_' allowed to follow. Whitespace not allowed)
- `description`  The description for the volume
- `volume_type`  The type of the volume to be created

    - `snas_2p`  For a SNAS Dual Parity    ( Protection level 2 )
    - `snas_3p`  For a SNAS Triple Parity  ( Protection level 3 )  (default)
    - `snas_erc` For a SNAS ERC volume

- `brick_uuids`  The uuids of the bricks as an array. If brick_uuids are not given an empty volume is created.  

SNAS Volume specific options

- `compression` To enable/disable compression for the volume ( Default: true )
- `case_sensitive` To enable/disable case sensitive for the volume ( Default: true )

SNAS ERC Volume specific options

- `encrypt` To encrypt the volume
- `passphrase`  The passphrase for the encryption.

Any other keys are ignored

Response body example:

    {
    "name": "SNAS2P",
    "description": "Test Volume",
    "volume_type": "snas_2p",
    "mode": "plain",
    "status": "incomplete",
    "uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
    "size": 0,
    "used": 0
  }

The `nas_engine` key from the response is deprecated although still available.

### Update Volume

Given the volume-uuid a volume name/description can be updated

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>.json

A `key` can be:

- `name`  The new name for the volume  ( Must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_' allowed to follow. Whitespace not allowed)
- `description`  The new description for the volume

Any other keys are ignored

### Update Passphrase for a SNAS ERC Volume

The passphrase for an already encrypted SNAS ERC volume can be updated

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/update_passphrase.json

A `key` can be:

- `passphrase`  The current passphrase of the volume
- `new_passphrase`  The new passphrase for the volume

Any other keys are ignored

### Add Bricks To Volume

Given the brick uuids as an array,assigns them to the given volume

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/assign_bricks.json

A `key` can be:

- `brick_uuids`  The uuids of the bricks as an array

Any other keys are ignored

### Set  volumes online and offline

A volume must be set offline in order to eject the corresponding bricks.
This means that the shares and data are not accessible in the meantime.

Request:

    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/set_online.json
    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/set_offline.json

Setting an encrypted volume online will fail, if the passphrase is not passed to the endpoint.
The passphrase should be form-data encoded in the payload of the HTTP request. See
[RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

    curl -X PUT -F "passphrase=<passphrase>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/set_online.json

### Unlocking/Locking  partition for eject

Unlock a brick/partition for eject, the brick can be ejected with the touch of the front sensor.
Only bricks of volumes that are OFFLINE (i.e. no shares online anymore) can be unlocked.
Trying to unlock a brick that is part of a ONLINE volume will generate an error.
Unlocking and locking is similar to VTL libraries.Given the volume uuid and the partition uuid a brick can be unlocked and
locked again so that the touch sensor is disabled.

Request:

    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/partitions/<partition-uuid>/unlock.json
    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/partitions/<partition-uuid>/lock.json

### Import volumes

Given the volume uuid, a volume can be imported into the system

    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/import.json

Importing an encrypted volume will fail, if the passphrase is not passed to the endpoint.
The passphrase should be form-data encoded in the payload of the HTTP request. See
[RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

    curl -X PUT -F "passphrase=<passphrase>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/import.json

### Delete Volume

Given the volume uuid, an offline volume can be deleted. Before attempting to delete the volume please make sure of the following,

- The volume is set offline.
- All the associated snapshots are deleted.

Deleting an encrypted volume will fail, if the passphrase is not passed to the endpoint.
The passphrase should be form-data encoded in the payload of the HTTP request. See
[RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

Request:

    curl -X DELETE -F "key=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>.json

 A `key` can be:

- `remove`  To remove the volume and its related partitions from the DB.
- `passphrase`  The passphrase to delete an encrypted volume.

## Share Operations

### Listing shares

With this call you can list all available shares.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/shares.json

Response body example:

    {
        "shares":[
          {
            "uuid": "645aac61-a54b-46fe-aaeb-a44b047f9565",
            "volume":"7e40a866-3490-459a-a17c-c5e8d850d0d0",
            "name":"Test",
            "path":"/",
            "fstype":"smb",
            "nfsid":4,
          "options":"browseable,casesens,public",
          "nfs_path":null,
          "share_clients":[]
          },
          {
            "uuid":"5941d228-e2ab-4093-9b8f-b06a5a399a1b",
            "volume":"7e40a866-3490-459a-a17c-c5e8d850d0d0",
            "name":"",
            "path":"/",
            "fstype":"nfs",
            "nfsid":3,
            "options":"",
            "nfs_path":"/shares/Test",
            "share_clients":[{"name":"*","uuid":"c320e59a-cd42-45aa-8dac-85586689045c","options":"rw,no_root_squash"}],      
          },
          {
           ... info for next share
          }
        ]
    }

### Add Shares

Given the volume uuid, a share can be added to any online volume

Request:

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/share.json

A `key` can be:

- `name`  The name for the share  ( Must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_' allowed to follow. Whitespace not allowed)
- `path`  The share path
- `fstype`

    - `smb` For a SMB share
    - `nfs` For a NFS share

SMB share type specific keys.

- `smb_user`            Restrict access to local SMB user ( Format: username )
- `smb_client`          Restrict access to AD user ( Format: Domain/username )

Flags specific for the SMB share type.Set to true/false.

- `smb_public`          public access flag(Default: true)
- `smb_read_only`       read-only flag(Default: false)
- `smb_browseable`      browseable flag(Default: true)
- `smb_ntfs_acls`       ntfs-acls flag(Default: true)
- `smb_case_sensitive`  case sensitive flag (Default: true)

NFS share type specific keys.

- `nfs_client`    NFS share client (Default: '*')

Options specific to the nfs share.Set to true/false.

- `nfs_rw`          write access on the NFS share(Default: true)
- `nfs_sync`          synchronize IO on the NFS share(Default: false)
- `nfs_insecure`        access from insecure ports on the NFS share(Default: false)
- `nfs_subtree_check`   subtree checking NFS share(Default: false)
- `nfs_root_squash`     root squashing on the NFS share(Default: true)

Any other keys are ignored

Response body example:

    {
    "uuid": "4f421fba-6d44-4bea-a56c-c63652a04c34",
    "volume_uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
    "name": "SNAS2P-NFS01",
    "path": "/SNAS2P-NFS01",
    "fstype": "nfs",
    "nfsid": 2,
    "options": "",
    "nfs_path": null,
    "share_clients": [{"name": "*","uuid": "bb5c656b-3d06-4cc7-9263-2a6bf6314083","options": "rw,no_root_squash"}]
  }

### Update Shares

Given the share uuid, a share client can be added to the share

Request:

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/shares/<share-uuid>/update.json

A `key` can be:

- `remove`  Set to true to remove the current share clients from the share ( Default: False )

SMB share type specific keys.

- `smb_user`            Restrict access to local SMB user ( Format: username )
- `smb_client`          Restrict access to AD user ( Format: Domain/username )

NFS share type specific keys.

- `nfs_client`    NFS share client (Default: '*')

Options specific to the nfs share client.Set to true/false.

- `nfs_rw`          write access on the NFS share(Default: true)
- `nfs_sync`          synchronize IO on the NFS share(Default: false)
- `nfs_insecure`        access from insecure ports on the NFS share(Default: false)
- `nfs_subtree_check`   subtree checking NFS share(Default: false)
- `nfs_root_squash`     root squashing on the NFS share(Default: true)

Any other keys are ignored

### Delete Shares

Given the share uuid, a share client can be deleted

Request:

    curl -X DELETE https://172.100.51.240/sb-public-api/api/v1/shares/<share-uuid>.json

## Replication Operations

### List Replications

With this call you can list all available replications.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/replications.json

Response body example:

    {
        "replications": [
        {
          "replication_uuid": "e14db50b-1f67-47c3-b487-7d278f33d32d",
          "source_volume_uuid": "bd056f33-cf07-49eb-a66e-a457f3bd2179",
          "target_volume_uuid": "5e9b45c0-09dd-4016-b544-bc3268ebdfa5",
          "sync_type": "async",
          "status": "running",
          "progress": 100,
          "source_data_high_watermark": 212992,
          "target_volume": {
              "name": "SNAS2P-REP01",
              "description": "Test Replication Created Using The PublicApi",
              "volume_type": "snas_2p",
              "mode": "replication",
              "status": "online",
              "uuid": "5e9b45c0-09dd-4016-b544-bc3268ebdfa5",
              "size": 829919573,
              "used": 112208
            }
      },
      {
          "replication_uuid": "8880e427-b2df-4fc0-b6d2-7b5694c08b11",
          "source_volume_uuid": "8e4b7aa4-0db7-48d8-8b76-dadc78562ae1",
          "target_volume_uuid": "65ab57cb-cc5e-452d-893d-a6b957db443b",
          "sync_type": "async",
          "status": "paused",
          "progress": 100,
          "source_data_high_watermark": 0,
          "target_volume": {
              "name": "SNASERC-REP01",
              "description": "Test Replication Created Using The PublicApi",
              "volume_type": "snas_erc",
              "mode": "replication",
              "status": "online",
              "uuid": "65ab57cb-cc5e-452d-893d-a6b957db443b",
              "size": 995903488,
              "used": 35205
          }
      }
    ]
  }

### List Replications for a particular volume

With this call you can list all available replications of a particular volume.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/list_replications.json

Response body example:


  {
    "replications": [
       {
           "replication_uuid": "9bc87a57-c986-4593-b069-8d31ce835782",
           "source_volume_uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
           "target_volume_uuid": "fd56da28-6b99-4f04-8200-5ca7b25dfd35",
           "sync_type": "async",
           "status": "running",
           "progress": 100,
           "source_data_high_watermark": 385024
       },
       {
           "replication_uuid": "17866248-042c-48d8-879d-75484e15de0d",
           "source_volume_uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
           "target_volume_uuid": "de199919-aa1e-4972-915e-45b1a3c00814",
           "sync_type": "async",
           "status": "running",
           "progress": 100,
           "source_data_high_watermark": 454656
       }
    ]
  }

### Create Replication

Given the source volume uuid, a local replication can be created.

Request:

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/replication.json

A `key` can be:

- `name`         The name for replication target  ( Must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_' allowed to follow. Whitespace not allowed)
- `description`  The description for replication target
- `brick_uuids`  The uuids of the bricks to be added to the replication as an array

Depending on the type of the `source_volume`, additional keys are allowed

SNAS Volume specific options

- `compression` To enable/disable compression for the volume ( Default: depends on the source volume )
- `protection_level` SNAS protection level (takes values 2 or 3). ( Default: depends on the source volume )

SNAS ERC Volume specific options

- `encrypt` To encrypt the volume
- `passphrase`  The passphrase for the encryption.

### Pause/Resume Replication

Given the replication uuid, a local replication can be paused and resumed.

Request:

    PUT https://172.100.51.240/sb-public-api/api/v1/replications/<replication-uuid>/pause.json
    PUT https://172.100.51.240/sb-public-api/api/v1/replications/<replication-uuid>/resume.json

### Convert Replication

Given the replication uuid, a replication target can be converted to a plain volume. Please provide the passphrase if the replication is encrypted.  

    PUT https://172.100.51.240/sb-public-api/api/v1/replications/<replication-uuid>/convert.json

### Get Replication State

Given the replication uuid, the replication state is listed

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/replications/<replication-uuid>/state.json

Response body example:

    {
    "state": "running",
      "progress": 100
  }

### Update Replication Volume

Given the target-volume-uuid a replication volume name/description can be updated. Please note that the target-volume-uuid is to be used and not the
replication-uuid

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<target-volume-uuid>.json

A `key` can be:

- `name`  The new name for the volume  ( Must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_' allowed to follow. Whitespace not allowed)
- `description`  The new description for the volume

Any other keys are ignored

### Update Passphrase for a SNAS ERC Replication Volume

The passphrase for an already encrypted SNAS ERC replication volume can be updated

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<target-volume-uuid>/update_passphrase.json

A `key` can be:

- `passphrase`  The current passphrase of the volume
- `new_passphrase`  The new passphrase for the volume

Any other keys are ignored

### Set Replication volumes online and offline

A replication volume must be set offline in order to eject the corresponding bricks.
This means that the shares and data are not accessible in the meantime.

Request:

    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/set_online.json
    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/set_offline.json

Setting an encrypted volume online will fail, if the passphrase is not passed to the endpoint.
The passphrase should be form-data encoded in the payload of the HTTP request. See
[RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

    curl -X PUT -F "passphrase=<passphrase>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/set_online.json

### Delete Replication

Given the replication target volume uuid, the replication can be deleted just like a volume.

Request:

    DELETE https://172.100.51.240/sb-public-api/api/v1/volumes/<target-volume-uuid>.json

## Snapshot Operations

### List all available snapshots

With this call you can list all available snapshots on the controller.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/snapshots.json

Response body example:


  {
    "snapshots": [
       {
         "name": "SNAS2P-SNAP01",
         "description": null,
         "label": "20180725_152029",
         "uuid": "67731e3a-c0ba-4112-9b89-a0dcb83be12b",
         "volume_uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
         "index_hwm": null,
         "data_hwm": null,
         "used": 212992
       },
       {
         "name": "SNAS3P-SNAP02",
         "description": null,
         "label": "20180725_152560",
         "uuid": "85f27112-33e8-41e2-bd6c-cb9cfe7e1585",
         "volume_uuid": "f5c9b996-03b5-4775-aac1-3abbf6a8a9aa",
         "index_hwm": null,
         "data_hwm": null,
         "used": 286720
       }
    ]
  }

### List snapshots for a particular volume

With this call you can list all available snapshots of a particular volume.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/list_snapshots.json

Response body example:


  {
    "snapshots": [
       {
         "name": "SNAS2P-SNAP01",
         "description": null,
         "label": "20180725_152029",
         "uuid": "67731e3a-c0ba-4112-9b89-a0dcb83be12b",
         "volume_uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
         "index_hwm": null,
         "data_hwm": null,
         "used": 212992
       },
       {
         "name": "SNAS2P-SNAP02",
         "description": null,
         "label": "20180725_152302",
         "uuid": "562d4f03-7170-4145-8215-4cac217124b7",
         "volume_uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
         "index_hwm": null,
         "data_hwm": null,
         "used": 286720
       }
    ]
  }

### Create snapshot

Given the volume uuid, a snapshot of the volume can be created. 
Please make sure there is data on the volume before attempting to create a snapshot.

Request:

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<source-volume-uuid>/snapshot.json

A `key` can be:

- `name`         The name for the snapshot  ( Must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_' allowed to follow. Whitespace not allowed)
- `description`  The description
- `as_volume`    To provide snapshot as volume ( Default:False )

Any other keys are ignored

Response body example:

  {
    "name": "SNAS2P-SNAP02",
    "description": "Test",
    "label": "20180719_144408",
    "uuid": "397e27fc-b242-445e-930d-922f4decb3c0",
    "volume_uuid": "bd056f33-cf07-49eb-a66e-a457f3bd2179",
    "index_hwm": null,
    "data_hwm": null,
    "used": 131072
  }

### Snapshot as Volume

Given the volume uuid, a snapshot can be provided as a plain volume.

Request:

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<volume-uuid>/snapshot_as_volume.json

A `key` can be:

- `snapshot_uuid` The uuid of the snapshot to be converted

Any other keys are ignored

Response body example:

  {
    "name": "SNAS2P-SNAP02",
    "description": "Test",
    "label": "20180719_144408",
    "uuid": "397e27fc-b242-445e-930d-922f4decb3c0",
    "volume_uuid": "bd056f33-cf07-49eb-a66e-a457f3bd2179",
    "index_hwm": null,
    "data_hwm": null,
    "used": 131072,
    "snapshot_volume": {
    "name": "SNAS2P-SNAP02",
    "description": "Test",
    "volume_type": "snas_2p",
    "mode": "snapshot",
    "status": "incomplete",
    "uuid": "2bddcb51-363b-4272-a5d8-eb38c851a931",
    "size": 0,
    "used": 0
    }
  }

Note: Please use the snapshot_volume `uuid` to delete the snapshot volume.  

### Delete Snapshot

Given the snapshot uuid, the snapshots can be deleted. If the snapshot has an associated volume, please delete that first before attempting to remove the snapshot.

Request:

    DELETE https://172.100.51.240/sb-public-api/api/v1/snapshots/<snapshot-uuid>.json

## Clone Operations
### Create Clone

Given the volume uuid, a volume can be cloned. Please make sure there is data on the 
volume before attempting to clone it.

Request:

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/volumes/<source-volume-uuid>/clone_from_now.json

A `key` can be:

- `name`         The name for replication target  ( Must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_' allowed to follow. Whitespace not allowed)
- `description`  The description for clone
- `brick_uuids`  The uuids of the bricks to be added to the clone as an array

Depending on the type of the `source_volume`, additional keys are allowed

SNAS Volume specific options

- `compression` To enable/disable compression for the volume ( Default: depends on the source volume )
- `protection_level` SNAS protection level (takes values 2 or 3). ( Default: depends on the source volume )

SNAS ERC Volume specific options

- `encrypt` To encrypt the volume
- `passphrase`  The passphrase for the encryption.

Any other keys are ignored

## Controller Operations

### Updating the controller

The controller can be updated with this call:

    PUT https://172.100.51.240/sb-public-api/api/v1/controller.json

A key/value-pair is passed to the HTTP request. The key represents the
information to be updated, which can be encoded in the query string of the
request URL.

    curl -X PUT https://172.100.51.240/sb-public-api/api/v1/controller.json?<key>=<value>

The update-information can also be form-data encoded in the payload of the HTTP
request. See [RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/controller.json


A `key` can be:

- `qr_logo` Enables resp. disables the QR logo overlay. A value of `true`, `t`,
  `yes`, `y` or `1` enables the overlay. Any other value disables the logo.

Any other keys are ignored.

## Brick Archive Operations

### Listing Brick Archives
With this call you can list all available brick archives.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/brick_archives.json

Response body example:

    {
      "brick_archives": [
      {
        "brick_archive_uuid": "9a8e4326-8a80-11e8-9ecd-ccf0d678e953",
        "revision": 1,
        "name": "Arch01",
        "description": "Test Brick Archive",
        "archive_volume_uuid": "5ba7f0b1-cc95-4ab6-9c26-c0bb00d1ca16",
        "stage_volume_uuid": "8832e635-406f-4787-ac25-a656dd2a1ef3",
        "status": "running",
        "rfa_status": "inactive",
        "recovery_status": "inactive",
        "type": "plain",
        "stageless": false,
        "read_only": false,
        "can_start": true,
        "can_archive_start": true,
        "can_stage_start": true,
        "rfa_possible": false,
        "stages": [
          {
            "stage_uuid": "cc3aa51a-f695-4c29-bc75-ed08b874d5ab",
            "brick_archive_uuid": "9a8e4326-8a80-11e8-9ecd-ccf0d678e953",
            "stage_volume_uuid": "8832e635-406f-4787-ac25-a656dd2a1ef3",
            "current_stage": true,
            "stage_volume": {
              "name": "stage-9a8e4326-8a80-11e8-9ecd-ccf0d678e953-8f882e7f17a7ca2f",
              "description": "",
              "volume_type": "snas_3p",
              "mode": "plain",
              "status": "incomplete",
              "uuid": "8832e635-406f-4787-ac25-a656dd2a1ef3",
              "size": 2993855232,
              "used": 412432
              }
          }
        ],
        "archive_volume": {
            "name": "archive-9a8e4326-8a80-11e8-9ecd-ccf0d678e953",
            "description": "",
            ""volume_type": "snas_erc",
            "mode": "plain",
            "status": "incomplete",
            "uuid": "5ba7f0b1-cc95-4ab6-9c26-c0bb00d1ca16",
            "size": 1995903488,
            "used": 206074
          }
      },
            {
              ... info for next archive
            }
        ]
    }

### Listing Specific Brick Archive
With this call you can list a specific brick archive including sub volumes if any.

Request:

    GET https://172.100.51.240/sb-public-api/api/v1/brick_archives/<brick-archive-uuid>.json

Response body example:

  {
    "brick_archive_uuid": "9a8e4326-8a80-11e8-9ecd-ccf0d678e953",
    "revision": 1,
    "name": "Arch01",
    "description": "Test Brick Archive",
    "archive_volume_uuid": "5ba7f0b1-cc95-4ab6-9c26-c0bb00d1ca16",
    "stage_volume_uuid": "8832e635-406f-4787-ac25-a656dd2a1ef3",
    "status": "running",
    "rfa_status": "inactive",
    "recovery_status": "inactive",
    "type": "plain",
    "stageless": false,
    "read_only": false,
    "can_start": true,
    "can_archive_start": true,
    "can_stage_start": true,
    "rfa_possible": false,
    "stages": [
    {
        "stage_uuid": "cc3aa51a-f695-4c29-bc75-ed08b874d5ab",
        "brick_archive_uuid": "9a8e4326-8a80-11e8-9ecd-ccf0d678e953",
        "stage_volume_uuid": "8832e635-406f-4787-ac25-a656dd2a1ef3",
        "current_stage": true,
        "stage_volume": {
            "name": "stage-9a8e4326-8a80-11e8-9ecd-ccf0d678e953-8f882e7f17a7ca2f",
            "description": "",
            "volume_type": "snas_3p",
            "mode": "plain",
            "status": "incomplete",
            "uuid": "8832e635-406f-4787-ac25-a656dd2a1ef3",
            "size": 2993855232,
            "used": 412432
        }
    }
    ],
    "archive_volume": {
    "name": "archive-9a8e4326-8a80-11e8-9ecd-ccf0d678e953",
    "description": "",
    "volume_type": "snas_erc",
    "mode": "plain",
    "status": "incomplete",
    "uuid": "5ba7f0b1-cc95-4ab6-9c26-c0bb00d1ca16",
    "size": 1995903488,
    "used": 206074
    },
    "sub_volumes": [
    {
      "name": "Arch01-SubVol01",
      "description": "Test SubVol",
      "volume_type": "snas_erc",
      "mode": "plain",
      "status": "incomplete",
      "uuid": "b91c5741-8373-4977-abc9-aafc8df278d6",
      "size": 0,
      "used": 0
    }
    ]
    }

## SMB User

### List SMB Users

All the local SMB users can be listed using:

    GET https://172.100.51.240/sb-public-api/api/v1/users.json

 Response body example:

    {
        "users": [
         {
            "id": 980190976,
            "name": "smb01",
            "description": ""
         },
         {
            ... info for the next user
         }
      ]
    }

### Create SMB User

Creates a local SMB user.

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X POST -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/users/smb_user.json

A `key` can be:

- `name`  The name of the volume
- `description`  The description for the volume
- `password`  The password for the user

Any other keys are ignored

Response body example:

    {
     "id": 980190976,
       "name": "smb01",
       "description": "Test User One"
  }

### Update SMB User
Updates a local SMB user.

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/users/<user-id>.json

A `key` can be:

- `description`  The description for the volume
- `password`  The password for the user

Any other keys are ignored

Response body example:

    {
     "id": 980190976,
       "name": "smb01",
       "description": "Test SMB User One"
  }

### Delete SMB User
Delete a local SMB user.

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    curl -X DELETE -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/users/<user-id>.json

## General SB Information

### Background Task Active Status

Check if any of the background tasks are still active with this call:

    GET https://172.100.51.240/sb-public-api/api/v1/tasks_active.json

 Response body example:

        {
          "tasks_active":false
        }   
The `tasks_active` can be

- `true`  If any tasks are running in the background
- `false` If the system is idle, with no tasks running in the background.

Please make sure there are no tasks active, before making changes to the Bricks,Libraries or Volumes.


### Listing Open Issues

All the open issues of the day can be listed with this call:

    GET https://172.100.51.240/sb-public-api/api/v1/open_issues.json

 Response body example:

        [
            {
                "URC":"S17017",
                "Error Level":"Error",
                "Title":"Service failed",
                "Data":"Service ID: S17017",
                "Status":"Open",
                "Date Opened":"2017-09-25T14:02:21.000+00:00",
                "Date Closed":"-",
                "Ticket Number":null,
                "Technician":null
            }
        ]

The `Error Level` can be

- `Error`
- `Warning`
- `Info`

### Listing the hardware info

All the available serial numbers and other hardware information can be listed with this call:

    GET https://172.100.51.240/sb-public-api/api/v1/hardware_info.json

 Response body example:


     {
       "system":
                {"id":"6c1cc3bb-874f-4661-8db0-ba69f4e74b73",
                "creation_data":"2017-09-25T14:06:23+02:00",
                "hardware":{"site":{"id":"1","main_board":{"manufacturer":" ","pn":" ","serial":" ","version":" "},
                            "devices":{"device":
                                        [
                                            {"shortname":"G5","type":null,"serial":"3000-9990-0640","version":"2.0.2928","components":{"mc_units":null,"psus":null,"rtcs":null,"ssds":null,"gpus":null,"nics":null}},
                                            {"shortname":"EXTSHELF","type":null,"serial":"1000-9990-0511","components":{"mc_units":null,"psus":null,"rtcs":null}},
                                            {"shortname":"EXTSHELF","type":null,"serial":"1000-9991-0533","components":{"mc_units":null,"psus":null,"rtcs":null}},
                                            {"shortname":"EXTSHELF","type":null,"serial":"1000-9992-0500","components":{"mc_units":null,"psus":null,"rtcs":null}}
                                        ]}}},
                "software":{"used":"35 KB",
                            "bricks":{"brick":
                                        [  
                                            {"shortname":"SB","type":"hdd","serial":"V10AFDEB","fw":"0.0.0","used":"35 KB","slot":"0"},
                                            {"shortname":"SB","type":"hdd","serial":"V10AFDE9","fw":"0.0.0","used":"-","slot":"0"},
                                            {"shortname":"SB","type":"hdd","serial":"V10AFDED","fw":"0.0.0","used":"-","slot":"1"},
                                            {"shortname":"SB","type":"hdd","serial":"V10AFDEA","fw":"0.0.0","used":"-","slot":"0"},
                                            {"shortname":"SB","type":"hdd","serial":"V10AFDE8","fw":"0.0.0","used":"-","slot":"0"},
                                            {"shortname":"SB","type":"hdd","serial":"V10AFDEC","fw":"0.0.0","used":"-","slot":"1"}
                                         ]}},
                "eventhistory":{"events":null}}}
     }

  
  
