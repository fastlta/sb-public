# FAST LTA GmbH - Silent Bricks Public REST API Description

__Version:__ API Version v1 for Silent Bricks Software Version 2.53.0.3
__Date:__ August 2023

# Silent Bricks API

## Glossary

| Term | Explanation |
| - | - |
| Silent Brick Library | The whole system |
| Tape Library | A single, emulated tape library |
| Tape | Emulated tape instance, equivalent to a single Silent Brick |

## API Basics

### REST API

The API can be accessed using standard HTTP Commands, following the basic principles of REST, see <http://en.wikipedia.org/wiki/Representational_state_transfer>.

### API Fundamentals

For accessing the API the following information has to be known:

- Silent Brick Library IP or hostname.
- Username and password of a User of the Silent Brick Library.

### API Access

The basic API endpoint is:

```
https://<host-ip>/sb-public-api/api/
```

Please note that communication is always encrypted with SSL/TLS and happens on port 443. By default, the endpoint certificate does not have a valid certificate chain and must be trusted by the client.
Pure HTTP communication is not supported.

### Authentication

All calls must be authenticated using Basic HTTP authentication (see [RFC 2617](https://www.ietf.org/rfc/rfc2617.txt)). Username and password of a user of the Silent Brick Library are required.

### Request/Response encoding

The character encoding of requests must be UTF-8. The responses have to be in JSON format. This can be achieved by appending '.json' to the URL.

Note: to ensure a correct response format always append `.json` to your request URL as shown in the examples below.

### API Requests

Key/value-pairs are passed to the HTTP request. The key represents the information to be updated. The key/value-pairs can be encoded in the query string of the request URL.

```
curl -X PUT https://<host-ip>/sb-public-api/api/v1/bricks/<brick-uuid>.json?<key>=<value>
```

The parameters can also be form-data encoded in the payload of the HTTP request. See [RFC 2388](https://www.ietf.org/rfc/rfc2388.txt) for more details.

```
curl -X PUT -F "<key>=<value>" https://<host-ip>/sb-public-api/api/v1/bricks/<brick-uuid>.json
```

### Status codes

The HTTP status code of the response sent back by the server is based on the result of the API call. The following status codes are used:

- `200 (Ok)` The request was successfully processed by the server / the operation was executed / data was delivered.
- `400 (Bad Request)` Failed to execute operation on the requested resource. This usually happens if parameters are missing from the request or if the resource is in the wrong state (e.g. the volume is already offline and `set_offline` is called).
- `401 (Unauthorized)` Authentication failed.
- `403 (Forbidden)` The client tries to start a new task while a background task is active.
- `404 (Not Found)` The client requests a resource which does not exist.

In case of an error (status-code `4xx`) the response body contains a message clarifying the cause of the problem:

```
{
  "code": <the http status code>,
  "msg": "<a detailed error message>"
}
```

### SSL certificate

Because the default certificate is a self-signed certificate, we need to ignore the certificate or indicate the path of the certificate when HTTPS client are called.

Calling without a custom SSL certificate

```
curl -k -X GET https://<host-ip>/sb-public-api/api/v1/bricks.json -u admin
```

Calling with a custom SSL certificate

```
curl --cacert company.cert -X GET https://<host-ip>/sb-public-api/api/v1/bricks.json -u admin
```

## General SilentBrick System Information

### Identification

The system can be identified using this call:

```
GET /v1/identification.json
```

Response body example:

```
{
  "shortname": "G5000",
  "swversion": "2.20.0.5",
  "systemid":  "9000"
}
```

### Background task active status

Check if any of the background tasks are still active with this call:

```
GET /v1/tasks_active.json
```

Response body example:

```
{
  "tasks_active":true,
  "job_ids": [
  "b7d9343cf809cbf18c129aa6f3cf3756",
  "81341b5df9a3466edf86d47c8b04a04c",
  "0d1d76694b000f0ae5a48ab1a91cab75"
  ]
}
```

The `tasks_active` parameter can be:

| Value | Description |
|-|-|
| `true` | If any tasks are working/queued in the background |
| `false`| If the system is idle, with no tasks running in the background|

Please make sure there are no tasks active, before making changes to the Bricks, Libraries or Volumes.

### Get Job Status

With this call you can get the job status of a specific job
Request:

```
GET /v1/jobs/<job-id>.json
```

Response body example:

```
{
  "status": "completed",
  "id": "b7d9343cf809cbf18c129aa6f3cf3756"
}
```

The `Status` can be

| Value | Description |
|-|-|
| `working`   | job is currently being processed    |
| `queued`    | job is waiting to be processed      |
| `killed`    | job has been terminated             |
| `failed`    | job has failed during processing    |
| `completed` | job has been completed successfully |


The job id can be retrieved directly after a successful API call (from release version 2.33).
For those actions, which start a job in background, the API will return its job id in following format:

```
{
    "code": "200",
    "msg": "ok",
    "job_id": "b7d9343cf809cbf18c129aa6f3cf3756"
}
```

### List open issues

Lists all open service issues of the support area.

```
GET /v1/open_issues.json
```

Response body example:

```
[
  {
    "URC":"S17017",
    "siu_uuid:"207e0099-4e28-4153-b2cb-ec778c805342", 
    "Error Level":"Error",
    "Title":"Service failed",
    "Data":"Service ID: S17017",
    "Status":"Open",
    "Date Opened":"2017-09-25T14:02:21.000+00:00",
    "Date Closed":"-",
    "Ticket Number":null,
    "Technician":null
  }
  
  {
    ...."info of next siu"
  }
]
```

The response data

| Value | Description |
|-|-|
| URC | The SIU number |
| siu_uuid | The unique id used to identify the SIU |
| Error Level | The Error level of the SIU |
| Title | The FAIL title of the SIU |
| Data | Data associated with the SIU |
| Data Opened | The date and time the SIU was generated |
| Date Closed | The date and time the SIU was (if) closed|
| Ticket Number | The ticket number of the SIU (if any) |
| Technician | The details of the technician working on the ticket (if any) |

The `Error Level` can be

| Value | Description |
|-|-|
| `Error`   |  |
| `Warning` |  |
| `Info`    |  |

### Mark Resolved

To manually mark an open issue as resolved

```
PUT /v1/sius/<siu-uuid>/mark_resolved.json
```

### List the hardware info

Retrieves all the available serial numbers and other hardware information.

```
GET /v1/hardware_info.json
```

Response body example: [click](hardware_info_example.json)

The `systemtype` and the `type` can be


| Systemtype | Type | Description |
|-|-|-|
| G5000 | CONTROLLER_x | Silent Brick Controller |
| G2000 | PB | Silent Brick Drive |
| G1000 | PB_H | Silent Brick Single Drive  |
| SBDS | DS | Silent Brick DS |
| EXTSHELF | SHELF_x | Silent Brick Shelf  |


### Listing Network Info

The network info can be listed with this call:

```
GET /v1/network.json
```

Response body example:

```
{
  "hostname": "vm-controller-7c429f75",
  "domain_name": "fast-lta.intra",
  "gateway": "172.100.50.254",
  "dns_server_one": "172.100.50.254",
  "dns_server_two": "172.20.60.254",
  "nic": [
    {
      "name": "management",
      "dhcp": true,
      "ipaddr_v4": "172.100.51.240",
      "gateway_v4": "172.100.50.254",
      "subnet_mask": "255.255.254.0",
      "bonding_mode": "1 (active-backup)"
    },
    {
      "name": "data",
      "dhcp": true,
      "ipaddr_v4": "172.20.61.120",
      "gateway_v4": "172.20.60.254",
      "subnet_mask": "255.255.254.0",
      "bonding_mode": "1 (active-backup)",
      "link_auto_neg": true,
      "link_speed": 10000,
      "link_duplex": "full",
      "jumbo_frames": "off"
    }
  ],
  "routing": [
    {
      "target_addr": "172.100.51.50",
      "target_mask": "255.255.254.0",
      "gateway": "172.100.50.254"
    }
  ],
  "ipmi": {
    "ipaddr_v4": "172.20.60.50",
    "gateway_v4":"172.20.60.254",
    "netmask_v4": "255.255.254.0"
  }
}
```

The `bonding_mode` can be

| Value | Description |
|-|-|
| `0 (balance-rr)`    | This mode is also known as round-robin mode. Packets are sequentially transmitted and received through each interface one by one. This mode provides load balancing functionality. |
| `1 (active-backup)` | This mode has only one interface set to active, while all other interfaces are in the backup state. If the active interface fails, a backup interface replaces it as the only active interface in the bond. The media access control (MAC) address of the bond interface in mode 1 is visible on only one port (the network adapter), which prevents confusion for the switch. This mode provides fault tolerance. |
| `2 (balance-xor)`   | The source MAC address uses exclusive or (XOR) logic with the destination MAC address. This calculation ensures that the same slave interface is selected for each destination MAC address. This mode provides fault tolerance and load balancing. |
| `3 (broadcast)`     | When ports are configured with broadcast mode, all slave ports transmit the same packets to the destination to provide fault tolerance. This mode does not provide load balancing. |
| `4 (802.3ad)`       | 802.3ad mode is an IEEE standard also called LACP (Link Aggregation Control Protocol). LACP balances outgoing traffic across the active ports and accepts incoming traffic from any active port. |
| `5 (balance-tlb)`   | This mode ensures that the outgoing traffic distribution is set according to the load on each interface and that the current interface receives all the incoming traffic. If the assigned interface fails to receive traffic, another interface is assigned to the receiving role. It provides fault tolerance and load balancing. |


## System Operations

### Reboot the Controller

Reboots the Silent Brick Controller.

Request:

```
POST /v1/system/reboot.json
```

Example:

```
curl -X POST "https://<host-ip>/sb-public-api/api/v1/system/reboot.json"
```

### Shutdown the Controller

Shuts down the Silent Brick Controller. 

Request:

```
POST /v1/system/shutdown.json
```

Example:

```
curl -X POST "https://<host-ip>/sb-public-api/api/v1/system/shutdown.json"
```

### Restart Share Service
Restarts NFS or SMB services.
The NFS service can only be restarted if at least one NFS share exists.

Request:

```
POST v1/system/restart_share_service.json
```

List of keys:

| Key  | Description | Rules |
|-|-|-|
| `service` | The name of the share service. | Must be 'nfs' or 'smb' |

Response body example:

```
{ 
      "code": 200,
      "msg": "ok",
      "job_id": "de0352d37b3f9ba52a703a31df175d8f"
}
```

Example:

To restart the NFS services:
```
curl -X POST -F"service=nfs" https://<host-ip>/sb-public-api/api/v1/system/restart_share_service.json
```

Request the status of the job as described in [this section](#get-job-status) to know whether the 
services successfully restarted.

Additional explanation of specific values for `Status`:

| Value | Description |
|-|-|
| `failed`    | restart timeouted or failed |
| `completed` | successfully restarted |


## Basic Brick Operations

### List free Bricks

This call lists all the unassigned bricks.

Request:

```
GET /v1/bricks.json
```

Response body example:

```
{
    "bricks": [
      {
        "uuid": "645aac61-a54b-46fe-aaeb-a44b047f9565",
        "serial":"V10AFDF1",
        "type":"HDD",
        "gross_capacity":3995903488,
        "net_capacity":3990496256,
        "media_status": "ok",
        "state": "",
        "status": "online",
        "power_status": "off",
        "unassigned":"Yes",
      },
      {
        "... info for next brick"
      }
              ]
}
```

The `media_status` is determined based on the usable disk count

| Value | Notes |
|-|-|
| `ok` |  Required disks available |
| `degraded`     | Usable disk count is less than required |
| `degraded read only`   |   |
| `low redundancy`  |  |
| `defective`      |  |

The `status` can be

| Value | Notes |
|-|-|
| `online` |   |
| `transport`| Pending brick validation after reinsert/redetect |
| `unlocked` | Brick eject requested |
| `ejected` | Brick is ejected  |
| `error`  |  |


### List all Bricks

Returns all bricks in the system (assigned and unassigned).

Request:

```
GET /v1/bricks.json?all
```

Response body example:

```
{
    "bricks": [
      {
        "uuid": "da14bdcb-966b-425f-8088-62740760e756",
        "serial":"V10AFDE9",
        "type":"HDD",
        "gross_capacity":3995903488,
        "net_capacity":3990496256,
        "media_status": "ok",
        "state": "Available",
        "status": "online",
      "unassigned":"No",
        "partitions": [
          {
            "uuid":"8dd53317-ef74-4869-a2f0-5e162d2d5c0b",
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
        "media_status": "ok",
        "state": "Available in Slot 1",
        "status": "online",
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
        "media_status": "ok",
        "state": "Empty",
        "status": "online",
      "unassigned":"No",
        "partitions": [
          {
            "uuid":"8dd53317-ef74-4869-a2f0-5e162d2d5c0b",
            "span_index":0,
            "net_size":3835691008,
            "net_used":454656,
            "audit_location":454656
          }
        ]
      },
      {
        "... info for next brick"
      }
   ]
}
```

The `type` can be

| Value | Description |
|-|-|
| `HDD` |  Silent Brick |
| `SSD`     | Silent Brick Flash |
| `WORM`   | Silent Brick Worm  |
| `DSHDD`  | Silent Brick DS |
| `DSWORM`      | Silent Brick DS Worm |

The `state` can be

| Value | Description | Notes |
|-|-|-|
| `""` |  Un assigned brick |  |
| `Available`     | Partitioned Brick |  |
| `Empty`   | Unpartitioned Brick  |  |
| `Loaded in Drive`  | Loaded Brick | Also includes the drive name |
| `Available in slot`  | Partitioned Brick | Also includes the slot info for tapes |
| `Empty in slot`  | Unpartitioned Brick | Also includes the slot info for tapes |
| `Exported in slot`  | Brick in export slot | Also includes the export slot info for tapes |
| `Loading Failed` | Loading the tape failed |  |
| `Unloading Failed` | unloading the tape failed |  |


### List all Brick Disks

Returns all brick disks in the system (ok and faulty).

Request:

```
GET /v1/bricks/disks.json
```

Response body example:

```
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
        "disks": [
          {
            "pos": 0,
            "power_status": "on",
            "status": "ok",
            "size": 3000000000,
            "temp": 32.0,
            "model": "B9AD5C5247F48295",
            "firmware": "D60F7030",
            "serial": "6330502A8ED",
            "wwn": "77110f667e2f06fb"
          },
          {
            "... info for next disk"
          }
        ]
      },
      {
        "... info for next brick"
      }
    ]
}

```

### List faulty Brick Disks

Returns only faulty brick disks and the associated brick.

Request:

```
GET /v1/bricks/disks.json?notok
```

Response body example:

```
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
        "disks": [
          {
            "pos": 0,
            "power_status": "on",
            "status": "inconsistent",
            "size": 3000000000,
            "temp": 32.0,
            "model": "B9AD5C5247F48295",
            "firmware": "D60F7030",
            "serial": "6330502A8ED",
            "wwn": "77110f667e2f06fb"
          },
          {
            "... info for next disk"
          }
        ]
      },
      {
        "... info for next brick"
      }
    ]
}

```

### Edit Brick information

Updates a Brick's description and status.

```
PUT /v1/bricks/<brick-uuid>.json
```

List of keys:

| Key | Description |
|-|-|
| `description` | The description for the brick |
| `display_mode` |  The description display mode (see below) |
| `qr` | Updates the string encoded in the QR code displayed in front of the brick. <br/>If the `value` starts with a `=` the complete string will be replaced. <br/>Otherwise the string is prepended to the QR code. |
| `find_me` | To toggle on/off the beacon |

The `qr` parameter sets the QR Code displayed in the front of the Silent Brick.

The `display_mode` parameter can have the following values:

| Value | Setting |
|-|-|
| `0` |  QR Display   - Description + Container ID |
| `1` |  QR Display   - Description Only |
| `2` | Text Display - Top & Left Aligned |
| `3` | Text Display - Top & Center |
| `4` | Text Display - Top & Right  Aligned |
| `5` | Text Display - Middle & Center |


The `find_me` parameter can have the following values:

| Value | Setting |
|-|-|
| `0` | beacon switched on |
| `1` |  beacon switched off |

where `beacon` is the LED in the front of the Silent Brick.

Please note that description can be updated either with (`description` and `display_mode`) or only `qr`. The three keys can't be used together.

Examples:

- To display the description as text in the top and centre of the brick e-paper

```
curl -X PUT -F "description=Brick001" -F"display_mode=3" https://<host-ip>/sb-public-api/api/v1/bricks/<brick-uuid>.json
```
- To display the container ID along with the description as QR

```
curl -X PUT -F "qr=BrickContainer 001" https://<host-ip>/sb-public-api/api/v1/bricks/<brick-uuid>.json
```

### Unassign Bricks

Removes one or more Bricks from their associated library or volume. A brick can only be removed from volume/libraries if it doesn't contain any partitions (i.e. it wasn't used yet).

```
PUT /v1/bricks/unassign.json
```

List of keys:

| Key | Description |
|-|-|
| `brick_uuids` | An _array_ containing the UUIDs of the bricks to be unassigned. |

Example:

- To unassign bricks with UUIDs `brick_uuid_1` and `brick_uuid_2` from the library

```
curl -X PUT -F "brick_uuids[]=brick_uuid_1" -F"brick_uuids[]=brick_uuid_2" https://<host-ip>/sb-public-api/api/v1/bricks/unassign.json
```

## Controller Operations

### Enable/disable the QR logo overlay

Enables or disables the QR logo overlay.

```
PUT /v1/controller.json
```

List of keys:

| Key | Description |
|-|-|
| `qr_logo` | Enables resp. disables the QR logo overlay. A value of `true`, `t`,   `yes`, `y` or `1` enables the overlay. Any other value disables the logo. |

## Library Operations

### Using mtx for tape library operations

For normal tape library operations like moving tapes from a library slot into a tape drive, a standard SCSI client like `mtx` should be used.

### Using mt for tape drive operations

For operations on a tape drive, like changing compression settings or querying the status, a standard SCSI client like `mt` should be used.

## VTL Operations

### List library emulations

Lists all available library types that can be used when creating a new library.

Request:

```
GET /v1/libraries/library_emulations.json
```

Response body example:

```
{
     "library_types": [
      {
        "vendor_identification": "ADIC",
        "product_identification": "Scalar 1000",
        "default_revision_level": "500A"
      },
       {
         "... info for next library type"
       }
     ]
}
```

### List tape drive emulations

Lists all available tape drive types.

Request:

```
GET /v1/libraries/tape_drive_emulations.json
```

Response body example:

```
{
  "tape_drive_types": [
    {
      "vendor_identification": "IBM",
      "product_identification": "ULTRIUM-TD3",
      "default_revision_level": "54K1"
    },
    {
     "... info for next tape drive type"
    }
  ]
}
```

### Create a library

Creates a library. Only one type of tape drive is allowed per Library.

```
POST /v1/libraries.json
```

A `key` can be:

| Key | Description | Comments |
|-|-|-|
| `library_name`        | The name of the library | Must be provided to create the library |
| `library_description` | The description for the library | Optional key |
| `library_type`        | The type of the library to be created | Optional key, Default: LBL |
| `library_vendor`      | The library vendor | Optional key, Default: FAST-LTA |
| `library_product`     | The library product | Optional key, Default: SBL 2000 |
| `custom_library_revision` | The custom revision of the library | Optional key |
| `barcode_start`  <br/>  `barcode_end` | The start pattern for tape barcode <br/> The end pattern for tape barcode <br/> | Set the barcode range to use for new media.|

To add tape drives to the library, additional keys should be used

| Key | Description | Comments |
|-|-|-|
| `tape_drive_prefix` | The (prefix-)name of the tape drive(s) | Should be provided if a tape drive needs to be added to the library.|
| `tape_drive_vendor` | The tape drive vendor | Optional key (Default: IBM)|
| `tape_drive_product` | The tape drive product| Optional key (Default: ULT3580-TD5) |
| `tape_drive_count` | The count of tape drives| Optional key (Default: 1) |

Bricks can be assigned and formatted with the same call.

| Key | Description | Comments |
|-|-|-|
| `brick_uuids` | The uuids of the bricks as an array | If brick_uuids are not given an empty library is created. See [Add Bricks to a library](#Add-Bricks-to-a-library) for type restrictions. |
| `tape_name_prefix` | The (prefix-)name of the tapes | Should be provided to format the assigned bricks. A tape drive should be assigned to format the bricks. |


Criteria for barcodes:

* A-Z and 0-9 are allowed characters.
* A length of 6 characters is recommended (maximum 32).
* The first three characters of the start and end specifiers must match (e.g. 'TTT000' and 'TTTZZZ').
* If the range end specifier ends with '999' (e.g. 'XXX000' to 'XXX999') the generated barcodes will consist of numbers only.|

Response body example:

```
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
```

Examples:

- To create a library with the default settings ( _LBL_ `library_type`, _FAST-LTA_ `library_vendor`, _SBL 2000_ `library product` with _1_ `tape_drive_count` of `tape_drive_vendor` _IBM_ and the `tape_drive_product` _ULT3580-TD5_ )

```
curl -X POST -F"library_name=Lib01" -F"library_description=Test library sb-public-api" -F"tape_drive_prefix=Drive-" https://<host-ip>/sb-public-api/api/v1/libraries.json
```

- To create a library of type _ADIC Scalar 1000_  with _2_ tape drives of type _HP Ultrium 5-SCSI_. Bricks can be assigned and formatted with the same call.

```
curl -X POST -F"library_name=Lib02" -F"library_vendor=ADIC" -F"library_product=Scalar 1000"  -F"tape_drive_prefix=Drive-" -F"tape_drive_count=2" -F"tape_drive_vendor=HP" -F"tape_drive_product=Ultrium 5-SCSI" -F"brick_uuids[]=<brick_uuid>" -F"brick_uuids[]=<brick_uuid>" -F"tape_name_prefix=Tape-" https://<host-ip>/sb-public-api/api/v1/libraries.json
```

### Update library information

Updates the description and settings of a library.

```
PUT /v1/libraries/<library-uuid>.json
```

A `key` can be:

| Key | Description |
|-|-|
| `library_name`        | The name of the library |
| `library_description` | The description for the library |
| `library_vendor`      | The library vendor (Default: FAST-LTA) |
| `library_product`     | The library product (Default: SBL 2000) |
| `custom_library_revision` | The custom revision of the library |
| `barcode_start`  <br/>  `barcode_end` | The start pattern for tape barcode <br/> The end pattern for tape barcode <br/> Set the barcode range to use for new media.
| `storage_slots`  | The number of storage slots to set |
| `export_slots` | The number of export slots to set |

See [Create a Library](#Create-a-library) for details on the barcodes.

### Add tape drives to a library

Creates new tape drives within a library. Only one type of tape drive is allowed per library.

```
PUT /v1/libraries/<library-uuid>/assign_drives.json
```

List of keys:

| Key | Description |
|-|-|
| `tape_drive_prefix`        | The (prefix-)name of the tape drive(s) |
|`tape_drive_vendor`      | The tape drive vendor (Default: IBM) |
|`tape_drive_product`     | The tape drive product (Default: ULT3580-TD5) |
|`tape_drive_count`         |  The count of tape drives (Default: 1) |

### Add Bricks to a library

Assigns bricks to a library.

```
PUT /v1/libraries/<library-uuid>/assign_bricks.json
```

List of keys:

| Key | Description |
|-|-|
| `brick_uuids` | The uuids of the bricks as an array |
| `tape_name_prefix` | The (prefix-)name of the tapes. Also the key to format the bricks, if not provided the bricks will only be assigned and not formatted. |
| `tape_count`       | The number of tapes to be created. All bricks are formatted if not provided. If the `tape_name_prefix ` key is not provided this key is not considered. |

#### Restrictions

- You can only add _Silent Brick_, _Silent Brick Flash_ and _Silent Brick DS_ bricks
  to a library.

You are allowed to mix bricks of all supported brick types.

### Format Bricks in a library

Formats unformatted bricks that are already assigned to the library.

```
PUT /v1/libraries/<library-uuid>/format.json
```

List of keys:

| Key | Description |
|-|-|
| `brick_uuids` | The uuids of the bricks as an array |
| `tape_name_prefix` | The (prefix-)name of the tapes. Also the key to format the bricks, if not provided the bricks will only be assigned and not formatted. |

### Erase tapes in a library

Erases tapes that are part of a library. The erased Bricks remain assigned to the library.

```
PUT /v1/libraries/<library-uuid>/erase.json
```

List of keys:

| Key | Description |
|-|-|
| `tape_uuids` | The uuids of the tapes to erase as an array |

### List tape libraries and drives

Lists all available tape libraries and their corresponding drives.

Request:

```
GET /v1/libraries.json
```

Response body example:

```
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
       "... info for next library"
     }
    ]
}
```

### List tapes in a library

Lists all tapes within a library.

Request:

```
GET /v1/libraries/<library-uuid>/tapes.json
```

Response body example:

```
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
          "... info for next tape"
      }
    ]
 }
```

The `status` can be

| Value | Description |
|-|-|
| `online` | The tape is ready and online |
| `unlocked` | The tape is unlocked for eject |
| `ejected` | The tape is ejected |
| `transport` | The tape is in transport mode |
| `error` | The tape is in an error state |

The current audit position is found in the value `audit_location`. Because the current default is _Audit after Write_, the value `net_used` is always equal to the value `audit_location`. All data is therefore generally audited at least once. Independently of this, each brick will be audited again once per month or 1/30 per day.

### Updating tapes

Updates tape information.

```
PUT /v1/libraries/<library-uuid>/tapes/<tape-uuid>.json
```

List of keys:

| Key | Description |
|-|-|
| `qr` | Updates the string encoded in the QR code displayed in front of the brick. When the `value` starts with a `=`, then the complete string is replaced.Otherwise the string is prepended to the QR code |


### Unlocking/Locking tapes for eject

Unlock/Lock a tape for eject (i.e.) the tape can be ejected with the touch of the front sensor. A tape that is loaded into a drive can NOT be unlocked and the call will generate an error.

```
PUT /v1/libraries/<library-uuid>/tapes/<tape-uuid>/unlock.json
```

```
PUT /v1/libraries/<library-uuid>/tapes/<tape-uuid>/lock.json
```

### Delete library

Deletes a library. Please make sure all the bricks are removed from the library before attempting to delete it.

Request:

```
DELETE /v1/libraries/<library_uuid>.json
```

## Volume Operations

### List volumes

Lists volumes of all available volume types (SNAS ERC, SNAS 2P, SNAS 3P).

Note: If the current user has ComplianceAdmin, the results will also include the available Sub Volumes for Privilege Delete.
The results of these Sub Volumes will have limited information only for Privilege Delete operation. For more details please see the chapter [Privilege Delete Operations](#Privilege-Delete-Operations).

Request:

```
GET /api/v1/volumes.json
```

Response body example:

```
{
  "volumes": [
    {
      "name": "Vol01",
      "description": "Test Volume One",
      "volume_type": "snas_3p",
      "nas_engine": "nas",
      "status": "online",
      "mode": "plain",
      "uuid": "26e10c4b-7823-400e-8b3a-f9e29f64ca60",
      "size": 1496927616,
      "used": 76743,
      "used_percentage" : 0.01
    },
    {
      "name": "Vol02",
      "description": "Test Volume Two",
      "volume_type": "snas_erc",
      "nas_engine": "secure_nas",
      "status": "online",
      "mode": "plain",
      "uuid": "f35dc74e-0ce9-440b-b9ac-0ec7603ebaf5",
      "size": 1995903488,
      "used": 35079,
      "used_percentage" : 0.0
    },
    {
      "name": "Sub01",
      "uuid": "1d9cec60-6ad6-4169-93d9-33513155320d",
      "description": "Test Subvolume One",
      "nas_engine": "sub",
      "mode": "plain",
      "used": 0,
      "config": {
        "privDelMode": "enterprise"
      },
      "status": "online",
      "volume_type": "sub_volume",
      "brick_archive_uuid": "30b22160-8077-11ed-a400-39b9de331148"
    }
    {
      "... info for next volume"
    }
  ]
}
```

The `volume_type` can be

| Value | Description |
|-|-|
| `snas_2p` |  SNAS with protection level of 2 |
| `snas_3p` |  SNAS with protection level of 3 |
| `snas_erc`|  SNAS ERC |
| `sub_volume`|  Brick Archive, sub volume |

The `status` can be

| Value | Description |
|-|-|
| `incomplete` | The volume is incomplete, at least one partition is missing |
| `online`     | The volume is ready and online |
| `readonly`   | The volume is online but read-only |
| `offline`    | The volume is offline and cannot be used |
| `transport`  | An operation is currently running |
| `error`      | The volume is in an error state |

### List partitions within volumes

All volumes (except Sub Volumes) consist of at least one Brick, which is called _partition_ in this context. The partitions of a volume can be listed using the following call:

```
GET /v1/volumes/<volume-uuid>/partitions.json
```

Response body example:

```
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
        "... info for next partition"
      }
    ]
}
```

The `status` can be

| Value | Description |
|-|-|
| `online`    | The partition is ready and online |
| `unlocked`  | The partition is unlocked for eject |
| `ejected`   | The partition is ejected |
| `transport` | The partition is in transport mode |
| `error`     | The partition is in an error state |

The current audit position is found in the value `audit_location`. Because the current default is _Audit after Write_, the value `net_used` is always equal to the value `audit_location`. All data is therefore generally audited at least once. Independently of this, each brick will be audited again once per month or 1/30 per day.

### Get volume state

Gets the status of the specified volume.

Request:

```
GET /v1/volumes/<volume-uuid>/state.json
```

Response body example:

```
{
   "state": "online"
}
```

The `state` can be

| Value | Description |
|-|-|
| `incomplete` | The volume is incomplete, at least one partition is missing |
| `online`     | The volume is ready and online |
| `readonly`   | The volume is online but read-only |
| `offline`    | The volume is offline and cannot be used |
| `transport`  | An operation is currently running |
| `error`      | The volume is in an error state |

### Create a volume

Creates a volume (except Sub Volumes). Volumes cannot be used without assigning bricks.

```
POST /v1/volumes.json
```

List of keys:

| Key | Description | Rules |
|-|-|-|
| `name` |  The name of the volume |  It must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_'  allowed to follow. Whitespace not allowed |
| `description` | The description for the volume | Max 255 Characters |
| `volume_type` | The type of the volume to be created |-|
| `brick_uuids` | The uuids of the bricks as an array. If brick_uuids are not given an empty volume is created. See [Add Bricks to a volume](#Add-Bricks-to-a-volume) for type restrictions. |-|

Available `volume_type` values

| Value | Description |
|-|-|
| `snas_2p` | For a SNAS Dual Parity ( Protection level 2 )  |
| `snas_3p` | For a SNAS Triple Parity  ( Protection level 3 )  (Default) |
| `snas_erc`| For a SNAS ERC volume |

SNAS Volume specific options

| Value | Description |
|-|-|
| `compression`       | To enable/disable compression for the volume ( Default: true )    |
| `case_sensitive`  | To enable/disable case sensitive for the volume ( Default: true ) |
| `optimize`  | To enable/disable optimization for large files ( Default: false ) |

SNAS ERC Volume specific options

| Value | Description |
|-|-|
| `encrypt`     | To encrypt the volume. Set this key to encrypt the volume |
| `passphrase`  | The passphrase for the encryption |

Any other keys are ignored

Response body example:

```
{
  "name": "SNAS2P",
  "description": "Test Volume",
  "volume_type": "snas_2p",
  "mode": "plain",
  "status": "incomplete",
  "uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
  "size": 0,
  "used": 0,
  "used_percentage" : 0
}
```

Note: The `nas_engine` key from the response is deprecated, although still available.

Examples:

- To create an empty volume with default settings ( volume of type _snas_3p_ with _compression_ and _case_sentitive_ values enabled and optimize option disabled )

```
curl -X POST -F"name=Volume01" -F"description=Test volume sb-public-api" https://<host-ip>/sb-public-api/api/v1/volumes.json
```

- To create an empty volume with optimize option enabled ( volume of type _snas_3p_ with _compression_ and _case_sentitive_ values enabled )

```
curl -X POST -F"name=Volume03" -F"description=Test volume sb-public-api" -F"optimize=1" https://<host-ip>/sb-public-api/api/v1/volumes.json
```

- To create an encrypted _snas_erc_ volume and assign _2_ bricks to it

```
curl -X POST -F"name=Volume02" -F"description=Test erc volume sb-public-api" -F"volume_type=snas_erc" -F"encrypt=true" -F"passphrase=<secret-passphrase>" -F"brick_uuids[]=<brick_uuid>" -F"brick_uuids[]=<brick_uuid" https://<host-ip>/sb-public-api/api/v1/volumes.json
```

### Update a volume

Updates a volume's name or description.

```
PUT /v1/volumes/<volume-uuid>.json
```

List of keys:

| Key | Description | Rules |
|-|-|-|
| `name` |  The name of the volume |  It must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_'  allowed to follow. Whitespace not allowed |
| `description` | The description for the volume | Max 255 Characters |

### Update passphrase for a SNAS ERC Volume

Updates the passphrase for an already encrypted SNAS ERC volume.

```
PUT /v1/volumes/<volume-uuid>/update_passphrase.json
```

List of keys:

| Key | Description |
|-|-|
| `passphrase`     | The current passphrase of the volume |
| `new_passphrase` | The new passphrase for the volume |

### Add Bricks to a volume

Assigns the specified Bricks to a volume.

```
PUT /v1/volumes/<volume-uuid>/assign_bricks.json
```

List of keys:

| Key | Description |
|-|-|
| `brick_uuids` | The uuids of the bricks as an array |

#### Restrictions for _SNAS ERC_ volumes

- You can only add _Silent Brick_, _Silent Brick Flash_ and _Silent Brick DS_ bricks.

#### Restrictions for _SNAS 2P_ volumes

- You can only add _Silent Brick_ and _Silent Brick Flash_ bricks.
- You cannot assign more than 9 bricks.
- You cannot mix bricks of different brick types.

#### Restrictions for _SNAS 3P_ volumes

- You can only add _Silent Brick_, _Silent Brick Flash_ and _Silent Brick DS_ bricks.
- You cannot assign more than 9 bricks of type _Silent Brick_ and _Silent Brick Flash_.
- You cannot add more than 4 _Silent Brick DS_ bricks.
- You cannot mix bricks of different brick types.

### Set volumes online or offline

To set a volume online/offline. A volume must be set offline in order to eject the corresponding bricks. This means that the shares and data are not accessible in the meantime. Setting an encrypted volume online will fail if the passphrase is not passed to the endpoint.

Request:

```
PUT /v1/volumes/<volume-uuid>/set_online.json
```

```
PUT /v1/volumes/<volume-uuid>/set_offline.json
```

List of keys:

| Key | Description |
|-|-|
| `passphrase`     | The current passphrase of the volume |

### Unlock/Lock partition for eject

Unlocks a Brick so it can be ejected by touching its front sensor. If the Brick is not unlocked first then the touch sensor will not work.
Only bricks of volumes that are *offline* can be unlocked. Trying to unlock a brick that is part of an *online* volume will generate an error.

Request:

```
PUT /v1/volumes/<volume-uuid>/partitions/<partition-uuid>/unlock.json
```

```
PUT /v1/volumes/<volume-uuid>/partitions/<partition-uuid>/lock.json
```

### Import a volume (SNAS ERC only)

Starts the import of an SNAS ERC volume. Importing an encrypted volume will fail if the passphrase is not passed to the endpoint.

```
PUT /v1/volumes/<volume-uuid>/import.json
```

### Erase a volume (SNAS 2P or SNAS 3P only)

Starts the erase of all data of an SNAS 2P/3P volume. Before starting the operation make sure that,  

- All the bricks of the volume are accessible
- All the associated snapshot volumes are deleted
- The volume is offline.

```
DELETE /v1/volumes/<volume-uuid>/erase.json
```

### Delete a volume

Deletes a volume.

- The volume must be offline.
- All the associated snapshot volumes must be deleted.

If the volume is encrypted then the passphrase to decrypt must be specified, otherwise the operation will fail.

Request:

```
DELETE /v1/volumes/<volume-uuid>.json
```

List of keys:

| Key | Description |
|-|-|
| `remove`     | To remove the volume and its related partitions from the DB |
| `passphrase` | The passphrase to delete an encrypted volume |

## Share Operations

### List shares

Lists all shares.

Request:

```
GET /v1/shares.json
```

Response body example:

```
{
  "shares":[
    {
      "uuid": "645aac61-a54b-46fe-aaeb-a44b047f9565",
      "volume":"7e40a866-3490-459a-a17c-c5e8d850d0d0",
      "name":"Test",
      "path":"/",
      "fstype":"smb",
    "options":"browseable,casesens,public",
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
      "uuid": "5312f112-b480-4c9a-8154-5c41d9ecf915",
      "volume_uuid": "e6af3ff8-78e3-46a5-b1a1-d0211960c1a5",
      "name": "sss01",
      "path": "/sss01",
      "fstype": "sss",
      "options": "browseable",
      "access_key": "abc123",
      "port": 9000,
      "s3_domain": "<dns-name>"
      "share_clients": [],
      "s3_buckets": [
        {
          "key": "bucket01/",
          "in_use": true,
          "url": "<url>",
          "type": "folder",
          "size": 0,
          "status": "success"
        }
      ]
     },
    {
     "... info for next share"
    }
  ]
}
```

### Add a share

Adds a share to an *online* volume. NFS and SMB shares can be added to any *online* volume. S3 share can only be added to _SNAS 2P_ or _SNAS 3P_ volumes. 

Request:

```
PUT /v1/volumes/<volume-uuid>/share.json
```

List of keys:

| Key | Description | Rules |
|-|-|-|
| `name`   | The name of the share. Not for the _nfs_ fstype |  It must begin with 'a-z','A-Z' or '0-9' only. Characters ' - ' or ' _ '  allowed to follow. Whitespace not allowed |
| `path`   | The share path. Not for the _sss_ fstype | |
| `fstype` | The file system type | see below for allowed values |

Available `fstype` values

| Value | Description |
|-|-|
| `smb` | For a SMB share |
| `nfs` | For a NFS share |
| `sss` | For an S3 share |

SMB share type specific keys:

| Value | Description |
|-|-|
| `smb_user`   | Restrict access to local SMB user (Format: username) |
| `smb_client` | Restrict access to AD user (Format: domain/username) or AD Group (Format: @domain/name)|

Flags specific for the SMB share type:

| Value | Description | Default Setting |
|-|-|-|
| `smb_public`          | public access flag                        | true  |
| `smb_read_only`       | read-only flag                            | false |
| `smb_browseable`      | browseable flag                           | true  |
| `smb_ntfs_acls`       | ntfs-acls flag                            | true  |
| `smb_case_sensitive`  | case sensitive flag                       | volume dependent |
| `smb_admin`           | If set to true, an admin user is created. | false |

Note: `smb_case_sensitive` flag: For an `snas_erc` Volume: Depends on user input ( Default: true )
                                 For an `snas_2p/snas_3p` Volume: If `case_sensitive` flag for the volume is set to false, Set to false ( User Input Ignored )
                                                                  If `case_sensitive` flag for the volume is set to true, Depends on user input ( Default: true )


NFS share type specific keys:

| Value | Description |
|-|-|
| `nfs_client` | NFS share client |

Flags specific for the NFS share type:

| Value | Description | Default Setting |
|-|-|-|
| `nfs_enforce_nfs3`  | enforce nfs3 flag                           | false |

Available `nfs_client` Options

| Option | Format |
|-|-|
| Share to all IP Addresses ( Default ) | |
| Share to a single IPv4 Address | xxx:xxx:xxx:xxx |
| Share to a single IPv6 Address | String  |
| Share to a subnetwork | xxx:xxx:xxx:xxx / xxx |

Options specific to NFS share clients:

| Value | Description | Default Setting |
|-|-|-|
| `nfs_rw`        | write access on the NFS share                                 | true  |
| `nfs_sync`        | synchronize IO on the NFS share (may be bad for performance!) | false |
| `nfs_insecure`        | allow access from insecure ports on the NFS share             | false |
| `nfs_subtree_check`   | subtree checking NFS share                                    | false |
| `nfs_root_squash`     | root squashing on the NFS share                               | true  |


S3 share type specific keys:

| Key | Description | Rules |
|-|-|-|
| `access_key` | S3 Username | Must contain only characters 'a-z','A-Z' or '0-9' and be between 5 and 20 characters long. Whitespace not allowed. |
| `secret_key` | S3 Password | Must contain only characters 'a-z','A-Z','0-9','+' or '/' and be between 8 and 40 characters long. Whitespace not allowed. |
| `port` | TCP Port on which to provide the S3 service |  |
| `s3_domain` | Service point DNS name  |  |
| `objectlocking` | S3 object locking feature  | set to true to enable the feature. Default:false |

Note: Object locking feature can only be set during creation

Response body example:

```
{
  "uuid": "4f421fba-6d44-4bea-a56c-c63652a04c34",
  "volume_uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
  "name": "SNAS2P-NFS01",
  "path": "/SNAS2P-NFS01",
  "fstype": "nfs",
  "nfsid": 2,
  "options": "",
  "nfs_path": /shares/Test,
  "share_clients": [{"name": "*","uuid": "bb5c656b-3d06-4cc7-9263-2a6bf6314083","options": "rw,no_root_squash"}]
}
```

Examples:

- To create an _smb_ fstype share with default flags and restricting access to a local SMB user

```
curl -X  PUT -F"name=Share01" -F"path=/Share01" -F"fstype=smb" -F"smb_user=smb01" https://<host-ip>/sb-public-api/api/v1/volumes/<volume-uuid>/share.json
```

- To create an _nfs_ fstype share with read only flag

```
curl -X  PUT -F"path=/Share02" -F"fstype=nfs" -F"nfs_client=<client-ipv4-address>" -F"nfs_rw=false" https://<host-ip>/sb-public-api/api/v1/volumes/<volume-uuid>/share.json
```

- To create an _sss_ fstype share 

```
curl -X  PUT -F"name=Share03" -F"access_key=s3share01" -F"fstype=sss" -F"secret_key=<password>" -F"port=9000" -F"s3_domain=<dns-name>" https://<host-ip>/sb-public-api/api/v1/volumes/<volume-uuid>/share.json
```


### Update a share

Removes share clients from a share or adds a new one.

Request:

```
PUT /v1/shares/<share-uuid>/update.json
```

List of keys:

| Key | Description |
|-|-|
| `remove` |  Set to true to remove the already existing share clients from the share. Not valid for S3 share type (Default: false) |

SMB share type specific keys:

| Value | Description |
|-|-|
| `smb_user`   | Restrict access to local SMB user (Format: username) |
| `smb_client` | Restrict access to AD user (Format: domain/username) or AD Group (Format: @domain/name)|

Flags specific for the SMB share type:

| Value | Description | Default Setting |
|-|-|-|
| `smb_admin` | If set to true, an admin user is created. | false |

NFS share type specific keys:

| Value | Description |
|-|-|
| `nfs_client` | NFS share client |

Flags specific for the NFS share type:

| Value | Description | Default Setting |
|-|-|-|
| `nfs_enforce_nfs3`  | enforce nfs3 flag                 | false |

Available `nfs_client` Options

- Share to all IP Addresses ( Default )
- Share to a single IPv4 Address
- Share to a single IPv6 Address
- Share to a subnetwork

Options specific to NFS share clients:

| Value | Description | Default Setting |
|-|-|-|
| `nfs_rw`          | write access on the NFS share                                 | true  |
| `nfs_sync`        | synchronize IO on the NFS share (may be bad for performance!) | false |
| `nfs_insecure`        | allow access from insecure ports on the NFS share             | false |
| `nfs_subtree_check`   | subtree checking NFS share                                    | false |
| `nfs_root_squash`     | root squashing on the NFS share                               | true  |


S3 share type specific keys:

| Key | Description | Rules |
|-|-|-|
| `access_key` | S3 Username | Must contain only characters 'a-z','A-Z' or '0-9' and be between 5 and 20 characters long. Whitespace not allowed. |
| `secret_key` | S3 Password | Must contain only characters 'a-z','A-Z','0-9','+' or '/' and be between 8 and 40 characters long. Whitespace not allowed. |
| `port` | TCP Port on which to provide the S3 service |  |
| `s3_domain` | Service point DNS name  |  |

### Delete a share

Deletes a share.

Request:

```
DELETE /v1/shares/<share-uuid>.json
```

### S3 Bucket Operations

#### List Buckets

Lists all buckets for a particular _sss_ share.

Request:

```
GET /v1/shares/<share-uuid>/s3_buckets.json
```

Response body example:

```
{
  "s3_buckets": [
    {
      "key": "bucket01/",
      "in_use": false,
      "url": "<url>",
      "type": "folder",
      "size": 0,
      "status": "success"
      "object_locking": "not_enabled"
      "veeam_integrated: "no"
    }
    {
     "... info for next bucket"
    }
  ]
}
```


#### Add a Bucket

Buckets can be added only to an _sss_ file system type share. 

Request:

```
POST /v1/shares/<share-uuid>/s3_buckets.json
```

List of keys:

| Key | Description | Rules |
|-|-|-|
| `bucket`   | The name of the bucket.| It must begin with 'a-z' or '0-9' only. Character ' - ' is allowed to follow. Must end with 'a-z' or '0-9' only.Whitespace not allowed. Minimum length is 3 |
| `locked_bucket` | Creates a bucket with object locking  | set to true to enable the feature. Default:false |
| `veeam_integrated` | Creates a bucket with veeam SOSAPI enabled   | set to true to enable the feature. Default:false |

Note: Bucket with object locking can only be created if the share has object locking enabled! 

Response body example:

```
{
  "code": 200,
  "msg": "ok",
  "job_id": "de0352d37b3f9ba52a703a31df175d8f"
}
```

Example:

```
curl -X  POST -F"bucket=s3-bucket" https://<host-ip>/sb-public-api/api/v1/shares/<share-uuid>/s3_buckets.json
```


#### Delete a Bucket

Only empty buckets can be deleted.  

Request:

```
DELETE /v1/shares/<share-uuid>/s3_buckets.json
```

List of keys:

| Key | Description | 
|-|-|
| `bucket`   | The name of the bucket. |


## Replication Operations

### List replications

Lists all replications.

Request:

```
GET /v1/replications.json
```

Response body example:

```
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
        "used": 112208,
        "used_percentage" : 0.01
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
        "used": 35205,
        "used_percentage" : 0.0
      }
    }
  ]
}
```

### List replications for a particular volume

Lists only the replications belonging to a specific volume.

Request:

```
GET /v1/volumes/<volume-uuid>/list_replications.json
```

Response body example:

```
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
```

### Create replication

Creates a local replication for a volume.

Request:

```
PUT /v1/volumes/<volume-uuid>/replication.json
```

List of keys:

| Key | Description | Rules |
|-|-|-|
| `name` |  The name of the replication |  It must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_'  allowed to follow. Whitespace not allowed |
| `description` | The description for the replication | Max 255 Characters |
| `brick_uuids` | The uuids of the bricks to be added to the replication as an array  |-|

Depending on the type of the `source_volume`, additional keys are allowed:

SNAS Volume specific options:

| Value | Description |
|-|-|
| `compression` | To enable/disable compression for the replication volume (Default: depends on the source volume) |
| `protection_level` | SNAS protection level (2 or 3) (Default: depends on the source volume) |
| `optimize`  | To enable/disable optimization for large files ( Default: false ) |

SNAS ERC Volume specific options:

| Value | Description |
|-|-|
| `encrypt` | To encrypt the replication volume |
| `passphrase` | The passphrase for the encryption |

### Pause/Resume replication

Pauses or resumes a replication.

Request:

```
PUT /v1/replications/<replication-uuid>/pause.json
```

```
PUT /v1/replications/<replication-uuid>/resume.json
```

### Convert replication

Converts a replication volume to a standard volume. If the replication target is encrypted then the passphrase has to be supplied to the call. The convert operation is a long running task. See [Task Active Status](#Background-task-active-status) or [Job Status](#Get-Job-Status) to check the status of the task .

```
PUT /v1/replications/<replication-uuid>/convert.json
```

List of keys:

| Key | Description |
|-|-|
| `passphrase`     | The current passphrase of the replication volume |

### Get replication status

Retrieves the status and progress of a particular replication.

Request:

```
GET /v1/replications/<replication-uuid>/state.json
```

Response body example:

```
{
  "state": "running",
  "progress": 100
}
```

The `state` can be

| Value | Description |
|-|-|
| `stopped` | The replication has stopped |
| `running` | The replication is ready and online |
| `failed`  | The replication has failed |

### Update replication volume

See [Update a Volume](#Update-a-Volume) for details. Note that the volume UUID has to be used instead of the replication UUID.

### Update passphrase (SNAS ERC)

See [Update Passphrase](#Update-passphrase-for-a-SNAS-ERC-Volume). Use the target volume's UUID in the call.

### Set Replication volumes online and offline

See [Set Volume Online/Offline](#Set-volumes-online-or-offline). Use the target volume's UUID in the call.

### Delete replication volume

See [Delete a volume](#Delete-a-volume). Use the target volume's UUID in the call.

## Snapshot Operations

### List all available snapshots

Lists all snapshots available on the controller.

Request:

```
GET /v1/snapshots.json
```

Response body example:

```
  {
    "snapshots": [
       {
         "name": "SNAS2P-SNAP01",
         "description": null,
         "label": "20180725_152029",
         "timestamp": "2012-12-09 08:50:03",
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
         "timestamp": "2012-12-09 08:50:03",
         "uuid": "85f27112-33e8-41e2-bd6c-cb9cfe7e1585",
         "volume_uuid": "f5c9b996-03b5-4775-aac1-3abbf6a8a9aa",
         "index_hwm": null,
         "data_hwm": null,
         "used": 286720
       }
    ]
  }
```

### List snapshots for a volume

Lists all snapshots for a particular volume.

Request:

```
GET /v1/volumes/<volume-uuid>/list_snapshots.json
```

Response body example:

```
  {
    "snapshots": [
       {
         "name": "SNAS2P-SNAP01",
         "description": null,
         "label": "20180725_152029",
         "timestamp": "2012-12-09 08:50:03",
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
         "timestamp": "2012-12-09 08:50:03",
         "uuid": "562d4f03-7170-4145-8215-4cac217124b7",
         "volume_uuid": "653bf326-a834-47ef-bab9-99ab8e5bcf9f",
         "index_hwm": null,
         "data_hwm": null,
         "used": 286720
       }
    ]
  }
```

### Create snapshot

Creates a snapshot of a specific volume. Snapshots of empty volumes can't be created.

Request:

```
PUT /v1/volumes/<source-volume-uuid>/snapshot.json
```

List of keys:

| Key | Description | Rules |
|-|-|-|
| `name` | The name for the snapshot | Must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_' allowed to follow. Whitespaces are not allowed |
| `description` | The description for the snapshot | Max 255 Characters |
| `as_volume`   | To provide snapshot as volume (Default: false) |-|

Response body example:

```
  {
    "name": "SNAS2P-SNAP02",
    "description": "Test",
    "label": "20180719_144408",
    "timestamp": "2012-12-09 08:50:03",
    "uuid": "397e27fc-b242-445e-930d-922f4decb3c0",
    "volume_uuid": "bd056f33-cf07-49eb-a66e-a457f3bd2179",
    "index_hwm": null,
    "data_hwm": null,
    "used": 131072
  }
```

### Snapshot as Volume

Mount a snapshot as an accessible volume.

Request:

```
PUT /v1/volumes/<volume-uuid>/snapshot_as_volume.json
```

List of keys:

| Key | Description |
|-|-|
| `snapshot_uuid` | The uuid of the snapshot to be mounted |

Response body example:

```
  {
    "name": "SNAS2P-SNAP02",
    "description": "Test",
    "label": "20180719_144408",
    "timestamp": "2012-12-09 08:50:03",
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
    "used": 0,
    "used_percentage": 0.0
    }
  }
```

Examples:

- To mount a snapshot(_snap1-uuid_) of volume(_vol1-uuid_)

```
curl -X  PUT -F"snapshot_uuid=<snap1-uuid>" https://<host-ip>/sb-public-api/api/v1/volumes/<vol1-uuid>/snapshot_as_volume.json
```

### Delete snapshot volume

See [Delete a volume](#Delete-a-volume). Use the snapshot volume's UUID in the call.

### Delete a snapshot

Deletes a snapshot. All mounted volumes of this snapshot have to be deleted first.

Request:

```
DELETE /v1/snapshots/<snapshot-uuid>.json
```

## Clone Operations

### Create a clone

Creates a clone of a non-empty volume. The clone will have a copy of the data of the volume at the moment where the cloning process is started.

Request:

```
PUT /v1/volumes/<source-volume-uuid>/clone_from_now.json
```

List of keys:

| Key | Description | Rules |
|-|-|-|
| `name` | The name for the clone | Must begin with 'a-z','A-Z' or '0-9' only. Characters '-' or '_' allowed to follow. Whitespaces are not allowed |
| `description` | The description for the clone | Max 255 Characters |
| `brick_uuids` | The uuids of the bricks to be added to the clone as an array |
| `action_on_finish` | The action to perform when the clone is done. | Must be one of: "none", "set_offline" or "eject_bricks"

Possible values for `action_on_finish`:

| Value | Action |
|-|-|
| `none` | (Used by default) Do nothing after cloning is done.
| `set_offline` | Set the cloned volume offline.
| `eject_bricks` | Set the cloned volume offline and eject all bricks assigned to that volume.

Depending on the type of the `source_volume`, additional keys are allowed.

SNAS Volume specific options:

| Value | Description |
|-|-|
| `compression` | To enable/disable compression for the clone volume (Default: depends on the source volume) |
| `protection_level` | SNAS protection level (2 or 3) (Default: depends on the source volume) |
| `optimize`  | To enable/disable optimization for large files ( Default: false ) |

SNAS ERC Volume specific options:

| Value | Description |
|-|-|
| `encrypt` | To encrypt the clone volume |
| `passphrase` | The passphrase for the encryption |

## Compliant Archive Operations

### List Compliant Archives

Lists all available Compliant Archives.

Request:

```
GET /v1/brick_archives.json
```

Response body example:

```
{
  "brick_archives": [
    {
      "brick_archive_uuid": "9a8e4326-8a80-11e8-9ecd-ccf0d678e953",
      "revision": 1,
      "name": "Arch01",
      "description": "Test Brick Archive",
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
          "current_stage": true,
          "stage_volume": {
            "name": "stage-9a8e4326-8a80-11e8-9ecd-ccf0d678e953-8f882e7f17a7ca2f",
            "description": "",
            "volume_type": "snas_3p",
            "mode": "plain",
            "status": "online",
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
        "status": "online",
        "uuid": "5ba7f0b1-cc95-4ab6-9c26-c0bb00d1ca16",
        "size": 1995903488,
        "used": 206074
      }
    },
    {
      "... info for next archive"
    }
  ]
}
```

### Show Specific Compliant Archive

Retrieves the information (including Sub Volumes) for a particular Compliant Archive.

Request:

```
GET /v1/brick_archives/<brick-archive-uuid>.json
```

Response body example:

```
  {
    "brick_archive_uuid": "9a8e4326-8a80-11e8-9ecd-ccf0d678e953",
    "revision": 1,
    "name": "Arch01",
    "description": "Test Brick Archive",
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
        "current_stage": true,
        "stage_volume": {
            "name": "stage-9a8e4326-8a80-11e8-9ecd-ccf0d678e953-8f882e7f17a7ca2f",
            "description": "",
            "volume_type": "snas_3p",
            "mode": "plain",
            "status": "online",
            "uuid": "8832e635-406f-4787-ac25-a656dd2a1ef3",
            "size": 2993855232,
            "used": 412432,
            "brick_uuids": [
                    "cbce8c55-9b28-4d92-a99c-689f88c0351a",
                    "b176b695-7027-4ebf-925a-7fb1691c3f81" ]
        }
    }
    ],
    "archive_volume": {
    "name": "archive-9a8e4326-8a80-11e8-9ecd-ccf0d678e953",
    "description": "",
    "volume_type": "snas_erc",
    "mode": "plain",
    "status": "online",
    "uuid": "5ba7f0b1-cc95-4ab6-9c26-c0bb00d1ca16",
    "size": 1995903488,
    "used": 206074,
    "brick_uuids": [
              "b8ba2eb5-33ac-48c2-a8a0-29429e6dbe93",
              "6d74d1f7-880a-45bf-b17f-1392c9083106" ]
    },
    "sub_volumes": [
    {
      "name": "Arch01-SubVol01",
      "description": "Test SubVol",
      "volume_type": "sub_volume",
      "mode": "plain",
      "status": "online",
      "uuid": "b91c5741-8373-4977-abc9-aafc8df278d6",
      "used": 0,
      "sub_devices": [
          {
                "sub_device_uuid": "9c2fa302-ad0d-4ef4-bf41-989f477da6bd",
                "status": "ok",
                "net_used": 0,
                "inode_count": 0,
                "file_count": 0,
                "directory_count": 0,
                "symlink_count": 0,
                "pending_file_count": 0,
                "triggered_file_count": 0,
                "file_version_count": 0
            }
          ]
      }
   ]
   }
```

### Set Compliant Archive online or offline

To set a Compliant Archive online/offline. 
A Compliant Archive must be set offline in order to eject the corresponding bricks. 
This means that the shares and data are not accessible in the meantime. 
Setting an encrypted Compliant Archive online will fail if the passphrase is not passed to the endpoint.

Request:

```
PUT /v1/brick_archives/<brick-archive-uuid>/set_online.json
```

```
PUT /v1/brick_archives/<brick-archive-uuid>/set_offline.json
```

List of keys:

| Key | Description |
|---|---|
| `passphrase`     | The current passphrase of the Compliant Archive |


## Sub Volume Operations

Using the `uuid` of a sub volume, the name and description can be updated just like a standard volume. But all other volume operations are not allowed for a sub volume.

### List Sub Volume Cache Policies

List cache policies of all Sub Volumes of the current user.

```
GET /v1/volumes/caches.json
```

Response body example:

```
{
    "caches": [
        {
            "sub_volume_uuid": "b91c5741-8373-4977-abc9-aafc8df278d6",
            "sub_volume_name": "sample volume",
            "rule": true,
            "eviction_period": 30,
            "enabled": true
        },
    
        ...
    ]
}
```

### Show Sub Volume Cache Policy

Show the cache policy for one Sub Volume

```
GET /v1/volumes/<sub-volume-uuid>/cache.json
```

Response body example:

```
{
    "sub_volume_name": "sample volume",
    "rule": true,
    "eviction_period": 30,
    "enabled": true
}
```

### Create or Update Sub Volume Cache Policies

Create or update the same cache policies for one or more Sub Volumes.

```
POST /v1/volumes/caches/bulk_create_or_update.json
```

List of keys:

| Key | Description |
|---|---|
| `volume_ids` | Array, a list of Sub Volume IDs |
| `rule` | JSON formatted string, the matching rules for the caching policy, see following description, default: ""|
| `eviction_period` | Integer, the max period in days allowed to keep the cache, clipped at the maximum of 10 years, default: 0|
| `enabled` | Boolean, to enable the cache and cleanup rule, default: false|

Rules:

Cache Rules are persisted using JSON formatted strings.

Supported logic predicates: true, false, "and", "or", "not"

Supported ingest object predicates: "size", "name"

Rule examples:

* all files

    `true`
    
* all files smaller 2MB 

   `{ "size": [0, 2000] } or { "size": 2000 }`
    
* all files not between 1MB and 2MB in size

    `{ "not": {"size": [1000, 2000]} }`

* all files smaller 2MB or all ".png" files

    `{ "or": [{"size": [0, 2000]}, {"name": ["*.png"]} ]}`

* all non-".png" files smaller 2MB

    `{ "and": [{"size": [0, 2000]}, {"not": {"name": ["*.png"]}} ]}`

* all xrays between 50 and 100MB

    `{ "and": [{"size": [50000, 100000]}, {"name": ["*xray*"]} ]}`

* all ".jpg"/".jpeg" files smaller 2MB or all ".pdf"

    `{ "or": [{ "and": [{"size": [0, 2000]}, {"name": ["*.jpg","*.jpeg"]} ]}, {"name": ["*.pdf"]} ]}`


Response for a successful operation:

```
{
    "code": 200,
    "msg": "ok"
}
```

Response for a failed operation:

```
If volume_ids is blank:

{
    "code": 400,
    "msg": "volume ids missing"
}

If volume_ids has a non-existing volume_id:

{
    "code": 404,
    "msg": "no such volume"
}

If the stage volume that does not utilize an SSD drive:

{
    "code": 400,
    "msg": "Archive caching is not possible. The stage brick must be a SSD brick."
}

If all rule, eviction_period and enabled there parameters are left empty:

{
    "code": 400,
    "msg": "Missing parameter for API call."
}

If rule is invalid, e.g. "{}" :

{
    "code": 400,
    'msg": "Invalid cache policy rule."
}

If enabled is invalid, e.g. enabled set true when the rule is empty:

{
    "code": 400,
    'msg": "Invalid value for cache policy enabled field."
}

```

Examples of "error details" for "i18n_sub_volume_cache_bad_rule":

"Unexpected 'name' predicate", "Invalid encoding for 'name' predicate", "Expecting hash", "Invalid json format", 
"'and' predicate expects array with exact 2 members", "'and' predicate not allowed on a layer > 2" ... 

### Validate Sub Volume Cache Policy

Validate given cache policy for a Sub Volume.

```
GET /v1/volumes/<sub-volume-uuid>/cache/validate.json
```

List of keys:

| Key | Description |
|---|---|
| `rule` | formatted string (Mandatory), the matching rules for the caching policy |
| `eviction_period` | Integer, the max period in days allowed to keep the cache, max 10 years|
| `enabled` | Boolean, to enable the cache and cleanup policy |

Response is same as for #bulk_create_or_update, see before.

## Privilege Delete Operations

### List Sub Volumes

See [Listing Volumes](#list-volumes) for instructions on how to list the Sub Volumes.

If the user account has only the ComplianceAdmin role for the Compliant Archive of the Sub Volume then the response will be a stripped down JSON array of the volumes.

Response body example:

```
 {
    "volumes" : [
    {
       "name" : "vt2",
       "brick_archive_uuid" : "b752c88c-6672-11e9-8fc1-b213ea58c339",
       "uuid" : "24e89a4b-3f11-447b-b046-6c860b939086",
       "config" : {
            "privDelMode" : "enterprise",
       }
    },
    {
       "name" : "vt2-compliance",
       "brick_archive_uuid" : "b752c88c-6672-11e9-8fc1-b213ea58c339",
       "sub_volume_uuid" : "ba189522-275b-4c78-8d2e-3e019145881d",
       "config" : {
            "privDelMode" : "compliance",
        }
     }
  ]
}
```

If the user has mixed roles (e.g. it's also a Compliant Archive Admin), all volumes to which the user has access will be returned with details for each volume according to the corresponding access permissions.

Response body example:

```
    {
     "volumes" : [
        {
           "name" : "vt2",
           "brick_archive_uuid" : "b752c88c-6672-11e9-8fc1-b213ea58c339",
           "uuid" : "24e89a4b-3f11-447b-b046-6c860b939086",
           "config" : {
                "privDelMode" : "enterprise",
           }
        },
        {
           "name" : "vt2-compliance",
           "brick_archive_uuid" : "b752c88c-6672-11e9-8fc1-b213ea58c339",
           "sub_volume_uuid" : "ba189522-275b-4c78-8d2e-3e019145881d",
           "config" : {
                "privDelMode" : "compliance",
           }
        },
        {
            "name": "vt5",
            "uuid": "991aaf69-6c2c-415a-bcea-e7b751f06085",
            "brick_archive_uuid": "b752c88c-6672-11e9-8fc1-b213ea58c339",
            "description": "",
            "nas_engine": "sub",
            "mode": "plain",
            "used": 389362,
            "config": {
                "privDelMode": "enterprise"
            },
            "status": "ok",
            "volume_type": "sub_volume"
        },
     ]
    }
```

The `privDelMode` can be

| Value | Description |
|-|-|
|`enterprise`  | Enterprise mode |
|`compliance`  | Compliance mode |

### Delete a file

Uses a privileged delete to delete the file before its retention. Only available to API users that have the ComplianceAdmin role.

```
POST /v1/volumes/<sub_volume_uuid>/privdel.json
```

where `sub_volume_uuid`is the Sub Volume's UUID. Can be retrieved by listing the Sub Volumes (see above).

List of keys:

| Key | Description |
|-|-|
|`path`| The file path relative to the root path of the specific volume (**not** necessarily the share root!)|

For instance, if the volume is accessed through a share on the directory `/invoices` and the file to delete within that share is `/2018/12/invoice1.doc`, then the `path` parameter should be `/invoices/2018/12/invoice1.doc`.

Response for a successful operation:

```
    {
        "code": 200,
        "msg": "ok"
    }
```

Responses for failed attempts:

```
    {
        "code": 400,
        "msg": "The request is malformed."
    }

    {
        "code": 400,
        "msg": "The Sub Volume is not in enterprise mode."
    }

    {
        "code": 400,
        "msg": "The delete operation is currently unavailable, please try later."
    }

    {
        "code": 403,
        "msg": "The file is not under retention."
    }

    {
        "code": 403,
        "msg": "File can not be deleted, because the Compliance Archive is not running. Please set it online."
    }

    {
        "code": 403,
        "msg": "File can not be deleted, because the Compliance Archive is read-only."
    }

    {
        "code": 403,
        "msg": "The given file path is not allowed."
    }


    {
        "code": 404,
        "msg": "The file is not found in the given sub volume."
    }

    {
        "code": 404,
        "msg": "The Sub Volume is not found."
    }

    {
        "code": 500,
        "msg": "Internal server error."
    }     
```

## SMB Users

### List SMB users

Lists all local SMB users.

```
GET /v1/users.json
```

Response body example:

```
    {
        "users": [
         {
            "id": 980190976,
            "name": "smb01",
            "description": ""
         },
         {
            "... info for the next user"
         }
      ]
    }
```

### Create SMB user

Creates a local SMB user.

```
POST /v1/users/smb_user.json
```

List of keys:

| Key | Description | Rules |
|-|-|-|
| `name` | The name of the user | Must begin with '\_', 'a-z' or '0-9' only. Characters '-' or '_' or '.' are allowed to follow. Whitespaces are not allowed. Max length allowed is 64 characters|
| `description` | The description for the user | Max length allowed is 64 characters |
| `password` | The password for the user | - |

Response body example:

```
{
  "id": 980190976,
  "name": "smb01",
  "description": "Test User One"
}
```

### Update SMB user

Updates a local SMB user.

```
PUT /v1/users/<user-id>.json
```

List of keys:

| Key | Description |
|-|-|
| `description` |  The description for the user |
| `password` |  The password for the user |

Response body example:

```
{
  "id": 980190976,
  "name": "smb01",
  "description": "Test SMB User One"
}
```

### Delete SMB user

Delete a local SMB user.

```
DELETE /v1/users/<user-id>.json
```

## Host Connections

### List Host Connections

Lists all available host connections

```
GET /v1/host_connections.json
```

Response body example:

```
  {
     "host_connections": [
       {
         "host_connection_uuid": "849e285e-d11e-4d68-b72f-411395dc50f6",
         "name": "Test1",
         "description": "",
         "remote_mgmt_address": "172.100.51.91",
         "remote_data_address": "172.20.61.51",
         "remote_data_nat_address": "172.20.20.1"
         "remote_data_nat_port": 122,
         "own_role": "endpoint",
         "behind_nat": false,
         "deleted": false,
         "ssh_status": "not_connected",
         "api_status": "not_connected",
         "blue_bar_status": "not_connected",
         "floating_ip": {
          "floating_data_address": "172.20.61.51",
          "strategy_string": "fail4one",
          "enabled": true,
          "initiator_status_string": "unknown",
          "endpoint_status_string": "active"
            }
         },
         {
            "... info for the next host connection"
         }
      ]
    }
```

### Show specific Host Connection

Retrieves the information for a particular host connection

Request:

```
GET /v1/host_connections/<host-connection-uuid>.json
```

```
  {
         "host_connection_uuid": "849e285e-d11e-4d68-b72f-411395dc50f6",
         "name": "Test1",
         "description": "",
         "remote_mgmt_address": "172.100.51.91",
         "remote_data_address": "172.20.61.51",
         "remote_data_nat_address": "172.20.20.1"
         "remote_data_nat_port": 122,
         "own_role": "endpoint",
         "behind_nat": false,
         "deleted": false,
         "ssh_status": "not_connected",
         "api_status": "not_connected",
         "blue_bar_status": "not_connected",
         "floating_ip": {
          "floating_data_address": "172.20.61.51",
          "strategy_string": "fail4one",
          "enabled": true,
          "initiator_status_string": "unknown",
          "endpoint_status_string": "active"
            }
         },
    }
```

## Floating IPs

### List Floating Ips

Lists all available floating ips

```
GET /v1/floating_ips.json
```

```
{
  "floating_ips": [
    {
      "host_connection_uuid": "849e285e-d11e-4d68-b72f-411395dc50f6",
      "floating_data_address": "172.20.61.51",
      "strategy_string": "fail4one",
      "enabled": true,
      "initiator_status_string": "unknown",
      "endpoint_status_string": "active"
    },
    {
        "... info for the next floating ip"
    }  
  ]
}
```
### List floating ip for a host connection

Lists the floating ip of a particular host connection

Request:

```
GET /v1/host_connections/<host-connection-uuid>/floating_ips.json
```

```
    {
      "host_connection_uuid": "849e285e-d11e-4d68-b72f-411395dc50f6",
      "floating_data_address": "172.20.61.51",
      "strategy_string": "fail4one",
      "enabled": true,
      "initiator_status_string": "unknown",
      "endpoint_status_string": "active"
   }
```

The `strategy_string` can be

| Value | Description |
| - | - |
| `fail4one` | Release the floating IP if one replicated Compliant Archive is unavailable. |
| `fail4net` | Release the floating IP if network resources fail. |

The `initiator_status_string` and the `endpoint_status_string` describes the status of the floating IP
at the initiator resp. endpoint of the connection and can be one of:

| Value | Description |
| - | - |
| `active`         | The floating IP is currently at the given side. |
| `passive`        | The floating IP is currently at the given side. |
| `aquire_failed`  | Failed to aquire the floating IP. |
| `release_failed` | Failed to release the floating IP. |
| `unknown`        | The current status is currently unknown. |
| `invalid`        | The current floating IP status is invalid. |

## Notes

Note: All other product and company names should be considered trademarks of their respective owners. ©