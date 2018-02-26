# FAST LTA AG - Silent Bricks Public REST API Description

__Version:__ API v1.  for Silent Bricks Software R 2.10 (Version 2.10.3064, Build 3064)  
__Date:__ November 2017

__Terms used:__

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

### Status codes

The HTTP status code of the response sent back by the server encodes the result
of the API call. The following status codes are used by all API endpoints:

- `200 (Ok)` The request was successfully processed by the server, the
  operation was executed, data were delivered.
- `400 (Bad Request)` Failed to execute operation on the requested resource.
- `401 (Unauthorized)` Authentication failed.
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

### Listing tape libraries and drives

With this call you can list all available tape libraries and their corresponding drives.

Request should look like this:

    GET https://172.100.51.240/sb-public-api/api/v1/libraries.json

Response body example:

    [
      {
        "description": "",
        "uuid": "da14bdcb-966b-425f-8088-62740760e756",
        "name": "L1",
        "num_drives": 2,
        "num_storage_slots": 47,
        "num_export_slots": 47,
        "vendor_identification": "FAST-LTA",
        "product_identification": "SBL 2000",
        "product_revision_level": "100A",
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

### Listing tapes inside a library.

Given a library uuid, the corresponding tapes can be listed with this call.

    GET https://172.100.51.240/sb-public-api/api/v1/libraries/da14bdcb-966b-425f-8088-62740760e756/tapes.json

Response-Body:

    [
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

    PUT https://172.100.51.240/sb-public-api/api/v1/libraries/da14bdcb-966b-425f-8088-62740760e756/tapes/2c111621-216a-4252-a854-0e2a6cf5a824

Key/value-pairs are passed to the HTTP request. The key represents the
information to be updated. The key/value-pairs can be encoded in the query
string of the request URL.

    `curl -X PUT https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/tapes/<tape-uuid>?<key>=<value>`

The update-information can also be form-data encoded in the payload of the HTTP
request. See [RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

    `curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/libraries/<library-uuid>/tapes/<tape-uuid>`


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

    PUT https://172.100.51.240/sb-public-api/api/v1/libraries/da14bdcb-966b-425f-8088-62740760e756/tapes/2c111621-216a-4252-a854-0e2a6cf5a824/unlock.json

To lock a tape again so that the touch sensor is disabled, call:

    PUT https://172.100.51.240/sb-public-api/api/v1/libraries/da14bdcb-966b-425f-8088-62740760e756/tapes/2c111621-216a-4252-a854-0e2a6cf5a824/lock.json

### Listing volumes

With this call you can list all available NAS volumes.

Request should look like this:

    GET https://172.100.51.240/sb-public-api/api/v1/volumes.json

Response body example:

    [
      {
        "name": "Vol1",
        "uuid": "62864dee-0156-45f6-aa8d-1d3cb0269359",
        "nas_engine": "secure_nas",
        "status": "online"
        "description": "Test volume 1"
      },
      {
        ... info for next volume
      }
    ]

The `nas_engine` can be

- `secure_nas` The volume is a Secure-NAS volume
- `nas` The volume is a NAS volume

The `status` can be

- `incomplete` The volume is incomplete, at least one partition is missing.
- `online` The volume is ready and online.
- `readonly` The volume is online but read-only.
- `offline` The volume is offline and cannot be used.
- `transport` An operation is currently running.
- `error` The volume is in an error state.

### Listing partitions inside a NAS volume

A volume consists of at least one Brick, which is called _partition_ in this context.
Given a volume uuid, the corresponding partitions can be listed with this call.

    GET https://172.100.51.240/sb-public-api/api/v1/volumes/62864dee-0156-45f6-aa8d-1d3cb0269359/partitions.json

Response body example:

    [
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

### Set NAS volumes online and offline

A NAS volume must be set offline in order to eject the corresponding bricks.
This means that the shares and data are not accessible in the meantime.

    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/62864dee-0156-45f6-aa8d-1d3cb0269359/set_online.json
    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/62864dee-0156-45f6-aa8d-1d3cb0269359/set_offline.json

Setting an encrypted volume online will fail, if the passphrase is not passed to the endpoint.
The passphrase should be form-data encoded in the payload of the HTTP request. See
[RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

    curl -X PUT -F "passphrase=<passphrase>" https://172.100.51.240/sb-public-api/api/v1/volumes/62864dee-0156-45f6-aa8d-1d3cb0269359/set_online.json

### Unlocking/Locking NAS partition for eject

Unlock a brick/partition for eject, the brick can be ejected with the touch of the front sensor.
Only bricks of volumes that are OFFLINE (i.e. no shares online anymore) can be unlocked.
Trying to unlock a brick that is part of a ONLINE volume will generate an error.
Unlocking and locking is similar to VTL libraries.

Given the volume uuid and the partition uuid a brick can be unlocked with this call:

    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/62864dee-0156-45f6-aa8d-1d3cb0269359/partitions/47be86ca-422a-4e36-a35e-2af19ccb8175/unlock.json

To lock a partition/brick again so that the touch sensor is disabled, call:

    PUT https://172.100.51.240/sb-public-api/api/v1/volumes/62864dee-0156-45f6-aa8d-1d3cb0269359/partitions/47be86ca-422a-4e36-a35e-2af19ccb8175/lock.json

### Updating the controller

The controller can be updated with this call:

    PUT https://172.100.51.240/sb-public-api/api/v1/controller

A key/value-pair is passed to the HTTP request. The key represents the
information to be updated, which can be encoded in the query string of the
request URL.

    curl -X PUT https://172.100.51.240/sb-public-api/api/v1/controller?<key>=<value>

The update-information can also be form-data encoded in the payload of the HTTP
request. See [RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

    curl -X PUT -F "<key>=<value>" https://172.100.51.240/sb-public-api/api/v1/controller


A `key` can be:

- `qr_logo` Enables resp. disables the QR logo overlay. A value of `true`, `t`,
  `yes`, `y` or `1` enables the overlay. Any other value disables the logo.

Any other keys are ignored.


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


# Listing the hardware info

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
         
  
  