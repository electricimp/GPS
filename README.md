# GPS #

Electric Imp offers two GPS libraries. A driver for GPS modules that can be interfaced over UART ([GPSUARTDriver](#gpsuartdriver)), and a GPS data parser ([GPSParser](#gpsparser)).

![Build Status](https://cse-ci.electricimp.com/app/rest/builds/buildType:(id:Gps_BuildAndTest)/statusIcon)

## GPSParser ##

This library is a parser for standard NMEA sentences used by GPS devices.

All data is transmitted in the form of sentences. Only printable Ascii characters plus CR (carriage return) and LF (line feed) are allowed in a GPS sentence. The expected sentence format starts with $, which is followed by five characters. The first two characters are the talker identifier. The next three characters are the sentence identifier. Following the identifiers are a number of data fields separated by commas, then an optional checksum, and finally a carriage return and a line feed (CRLF). The data fields are uniquely defined for each sentence type.

For information on formats used in satellite data packets, please see [this page](http://www.gpsinformation.org/dale/nmea.htm).

**To add this library to your project, add** `#require "GPSParser.device.lib.nut:1.0.0"` **to the top of your device code.**

## GPSParser Usage ##

*GPSParser* has no constructor. There is no need to create an instance. All of the methods listed below should be called on *GPSParser* directly.

## GPSParser Methods ##

### hasCheckSum(*sentence*) ###

This method is used to indicate whether a GPS sentence contains a checksum value.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *sentence* | String | Yes | A GPS sentence |

#### Return Value ####

Boolean &mdash; `true` if the sentence contains a checksum, otherwise `false`.

#### Example ####

```squirrel
local sentence = "$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48\r\n";
local hasChecksum = GPSParser.hasCheckSum(sentence);
if (hasChecksum) {
  local checksum = GPSParser.getFields.top();
  server.log(format("0x%s", checksum));
}
```

### isValid(*sentence*) ###

This method is used to check whether a GPS sentence is valid &mdash; ie. its checksum, if it has one, is correct.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *sentence* | String | Yes | A GPS sentence |

#### Return Value ####

Boolean &mdash; `true` if the sentence contains a checksum and the checksum is correct, otherwise `false`.

#### Example ####

```squirrel
local sentence = "$GPGLL,4916.45,N,12311.12,W,225444,A,*1D\r\n";
server.log("GPS sentence check sum is " + (GPSParser.isValid(sentence) ? "" : "in") + "valid.");
```

### getGPSDataTable(*sentence*) ###

This method parses a GPS sentence into a table containing specific keys. It does not support all data types received by GPS. Currently it supports VTG, RMC, GLL, GGA, GSV and GSA. The data table will always contain the keys *talkerId* and *sentenceId*, which indicate the type of GPS message. However, all other keys will only be included if the GPS sentence contains data. See below for details on the possible key, value pairs for each of the supported data types.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *sentence* | String | Yes | A GPS sentence |

#### Return Value ####

Table &mdash; A table containing any of the following keys (the keys *talkerId* and *sentenceId* are always included):

#### VTG: Vector Track and Speed over Ground ####

| Key | Type | Description |
| --- | --- | --- |
| *talkerId* | String | Talker identifier, ie. `"GP"` or `"GN"` |
| *sentenceId* | String | Sentence identifier: `"VTG"` (constant *GPS_PARSER_VTG*) |
| *tTrack* | String | True track made good (degrees) |
| *mTrack* | String | Magnetic track made good |
| *speedKnots* | String | Ground speed in knots |
| *speedKPH* | String | Ground speed in kilometers per hour |
| *modeIndicator* | String | Signal integrity: `"A"` (autonomous), `"D"` (differential), `"E"` (estimated), `"N"` (not valid) or `"S"` (simulated) |
| *error* | String | Error description |

#### RMC: Recommended Minimum Data for GPS (Position, Velocity, Time) ####

| Key | Type | Description |
| --- | --- | --- |
| *talkerId* | String | Talker identifier, ie. `"GP"` or `"GN"` |
| *sentenceId* | String | Sentence identifier: `"RMC"` (constant *GPS_PARSER_RMC*) |
| *time* | String | UTC Time fix taken in the form `"hhmmss"` |
| *date* | String | Date fix taken in the form `"ddmmyy"` |
| *speedKnots* | String | Speed over the ground in knots |
| *trackAngle* | String | Track angle in degrees true |
| *latitude* | String | The latitude received in decimal degrees |
| *longitude* | String | The longitude received in decimal degrees |
| *status* | String | The status of the satellite: `"A"` (active) or `"V"` (void) |
| *mVar* | String | Magnetic variation in degrees |
| *modeIndicator* | String | Signal integrity: `"A"` (autonomous), `"D"` (differential), `"E"` (estimated), `"N"` (not valid) or `"S"` (simulated) |
| *error* | String | Error description |

#### GLL: Geographic Position, Latitude and Longitude ####

| Key | Type | Description |
| --- | --- | --- |
| *talkerId* | String | Talker identifier, ie. `"GP"` or `"GN"` |
| *sentenceId* | String | Sentence identifie: `"GLL"` (constant *GPS_PARSER_GLL*) |
| *time* | String | UTC Time fix taken in the form `"hhmmss"` |
| *status* | String | The status of the satellite: `"A"` (active) or `"V"` (void) |
| *latitude* | String | The latitude received in decimal degrees |
| *longitude* | String | The longitude received in decimal degrees |
| *modeIndicator* | String | Signal integrity: `"A"` (autonomous), `"D"` (differential), `"E"` (estimated), `"N"` (not valid) or `"S"` (simulated) |
| *error* | String | Error description |

#### GGA: Global Positioning System Fix Data ####

| Key | Type | Description |
| --- | --- | --- |
| *talkerId* | String | Talker identifier, ie. `"GP"` or `"GN"` |
| *sentenceId* | String | Sentence identifier: `"GGA"` (constant *GPS_PARSER_GGA*) |
| *time* | String | UTC Time fix taken in the form `"hhmmss"` |
| *latitude* | String | The latitude received in decimal degrees |
| *longitude* | String | The longitude received in decimal degrees |
| *fixQuality* | String | The quality of the satellite fix: `"0"` (invalid) or `"1"`-`"8"` (fix info) |
| *numSatellites* | String | The number of satellites being tracked |
| *HDOP* | String | Horizontal dilution of position |
| *altitude* | String | Altitude above mean sea level in meters |
| *geoSeparation* | String | Height of geoid (mean sea level) above WGS84 ellipsoid in meters |
| *lastDGPSUpdate*| String | Time since last DGPS update in seconds |
| *DGPSStationID* | String | DGPS station ID number |
| *error* | String | Error description |

#### GSV: Satellites in View ####

| Key | Type | Description |
| --- | --- | --- |
| *talkerId* | String | Talker identifier, ie. `"GP"` or `"GN"` |
| *sentenceId* | String | Sentence identifier: `"GSV"` (constant *GPS_PARSER_GSV*) |
| *numMsgs* | String | Total number of messages |
| *msgNum* | String | Message number |
| *numSatellites* | String | Number of satellites in view |
| *satelliteInfo* | Array | Array of tables with detailed satellite info (satellite PRN, elevation, azimuth, SNR) |
| *error* | String | Error description |

#### GSA: Overall Satellite Data ####

| Key | Type | Description |
| --- | --- | --- |
| *talkerId* | String | Talker identifier, ie. `"GP"` or `"GN"` |
| *sentenceId* | String | Sentence identifier: `"GSA"` (constant *GPS_PARSER_GSA*) |
| *selMode* | String | Selection mode: `"A"` (auto) or `"M"` (manual) |
| *mode* | String | Mode: `"1"` (no fix), `"2"` (2D fix) or `"3"` (3D fix) |
| *satellitePRNs* | Array | PRNs (IDs) of satellites used for fix |
| *PDOP* | String | Dilution of precision |
| *HDOP* | String | Horizontal dilution of precision |
| *VDOP* | String | Vertical dilution of precision |
| *error* | String | Error description |

#### Example ####

```squirrel
local sentence = "$GPGLL,4916.45,N,12311.12,W,225444,A,*1D\r\n";
local gpsData = GPSParser.getGPSDataTable(sentence);
if (gpsData.sentenceId == GPS_PARSER_GLL) {
  server.log("GLL message received.");
  if (gpsData.status == "A" && "latitude" in gpsData && "longitude" in gpsData) {
    server.log(format("Latitude %s, Longitude %s", gpsData.latitude, gpsData.longitude));
  } else {
    server.log("Location data not available.");
  }
}
```

### getFields(*sentence*) ###

This method converts a GPS sentence into an array of data fields. The first item in the array will always be the talker and sentence identifiers. The rest of the array will contain all data fields, even if they contain only an empty string. If the sentence includes a checksum this will be the last item in the array.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *sentence* | String | Yes | A GPS sentence |

#### Return Value ####

Array &mdash; the data fields contained in the sentence.

#### Example ####

```squirrel
local sentence = "$GPGGA,,,,,,0,00,99.99,,,,,,*48\r\n";
local fields = GPSParser.getFields(sentence);
foreach (idx, item in fields) {
  server.log(format("%i. %s", idx + 1, item));
}
```

### parseLatitude(*rawLatitude, direction*) ###

This method takes the two latitude fields derived from a GPS sentence (using *getFields()*) and converts them into a single latitude in decimal degrees.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *rawLatitude* | String | Yes | The raw latitude value, eg. `"3723.71721"` |
| *direction* | String | Yes | The direction indicator, eg. `"N"` |

#### Return Value ####

String &mdash; the latitude as a numeric string.

#### Example ####

See below.

### parseLongitude(*rawLongitude, direction*) ###

This method takes the two longitude fields derived from a GPS sentence (using *getFields()*) and converts them into a single longitude in decimal degrees.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *rawLatitude* | String | Yes | The raw longitude value, eg. `"12206.14085"` |
| *direction* | String | Yes | The direction indicator, eg. `"W"` |

#### Return Value ####

String &mdash; the latitude as a numeric string.

#### Example ####

```squirrel
local sentence = "$GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4C\r\n";
local fields = GPSParser.getFields(sentence);
local type = fields[0].slice(2);
if (type == GPS_PARSER_GGA) {
  // Get Latitude
  if (fields[2] != "" && fields[3] != "") {
    local lat = parseLatitude(fields[2], fields[3]);
    server.log("Latitude: " + lat);
  }
  // Get Longitude
  if (fields[4] != "" && fields[5] != "") {
    local lng = parseLongitude(fields[4], fields[5]);
    server.log("Longitude: " + lng);
  }
}
```

## GPSUARTDriver ##

This library is a driver class for GPS modules that can be interfaced over UART. It has been tested on [UBlox NEO-M8N](https://www.u-blox.com/sites/default/files/NEO-M8-FW3_DataSheet_%28UBX-15031086%29.pdf) and [UBlox LEA-6S](https://www.u-blox.com/sites/default/files/products/documents/LEA-6_DataSheet_%28UBX-14044797%29.pdf) modules.

**Note:** The class methods *hasFix()*, *getLatitude()* and *getLongitude()*, and the constructor’s *parseData* option are dependent on the [*GPSParser*](#gpsparser) library. If *GPSParser* is not detected, the class methods will return an error string, and the *parseData* option will default to `false`.

**To use this library in your project, add** `#require "GPSUARTDriver.device.lib.nut:1.2.0"` **to the top of your device code.**

## GPSUARTDriver Usage ##

### Constructor: GPSUARTDriver(*uart[, options]*) ###

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *uart* | String | Yes | An imp UART bus to which the GPS module is connected |
| *options* | String | No | A table of settings to override default behaviors *(see below)* |

Any table passed into *options* may contain any of the following keys:

| Key | Type | Default | Description |
| --- | --- | --- |--- |
| *baudRate* | Integer | 9600 | The baud rate used to configure the UART |
| *wordSize* | Integer | 8 | The word size in bits (7 or 8) used to configure the UART |
| *parity* | Integer | *PARITY_NONE* | Parity (*PARITY_NONE*, *PARITY_EVEN* or *PARITY_ODD*) used to configure the UART |
| *stopBits* | Integer | 1 | Stop bits (1 or 2) used to configure the UART |
| *gpsDataReady* | Function | `null` | Callback that is called when a new GPS sentence is received. The callback has two parameters of its own, both required: a boolean, *hasActiveLocation*, indicating whether the GPS sentence has active location data, and *gpsData*, which will be either the GPS sentence or a table with parsed GPS data. If *GPSParser* is not detected the *hasActiveLocation* parameter will be `null` |
| *parseData* | Boolean | `false` | If `false`, the unparsed GPS sentence will be passed to the *gpsDataReady* callback’s *gpsData* parameter. If `true`, and *GPSParser* is detected, the *gpsData* parameter will contain the table returned by *GPSParser.getGPSDataTable()* |
| *rxFifoSize* | Integer | The OS default (currently 80) | Sets the size (in bytes) of the input FIFO stack of the UART serial bus. |

## GPSUARTDriver Methods ##

### hasFix() ###

If *GPSParser* is detected, this method indicates whether the GPS module has sufficient data to get a fix on the device’s location.

#### Return Value ####

Boolean &mdash; `true` if the module has a fix, otherwise `false` (or an error string if *GPSParser* is not loaded).

### getLatitude() ###

If *GPSParser* is detected, this method returns a string with the last known latitude in decimal degrees.

#### Return Value ####

String &mdash; the latitude or `null`, or an error string if *GPSParser* is not loaded.

### getLongitude() ###

If *GPSParser* is detected, this method returns a string with the last known longitude in decimal degrees.

#### Return Value ####

String &mdash; the longitude or `null`, or an error string if *GPSParser* is not loaded.

### getGPSSentence() ###

This method provides the most recently received GPS sentence.

#### Return Value ####

String &mdash; the last GPS sentence, or `null` if no sentences have been received.

## Full GPSUARTDriver Example ##

```squirrel
#require "GPSParser.device.lib.nut:1.0.0"
#require "GPSUARTDriver.device.lib.nut:1.2.0"

// Create GPS variable
local gps = null;

// GPS callback
function gpsHandler(hasLocation, data) {
  // Log location or GPS sentence
  if (hasLocation) {
    server.log(format("Latitude: %s, Longitude: %s", gps.getLatitude(), gps.getLongitude()));
  } else {
    server.log(gps.getGPSSentence());
  }

  // If we don't have a fix log number of satellites in view
  if (!gps.hasFix() && "numSatellites" in data) {
    server.log(format("Number of satellites: %s", data.numSatellites));
  }
}

// GPS options
local gpsOpts = {"gpsDataReady" : gpsHandler, "parseData" : true};

// Initialize GPS UART driver
gps = GPSUARTDriver(hardware.uart1, gpsOpts);
```

## License ##

The GPSParser and GPSUARTDriver libraries are licensed under [MIT License](./LICENSE).
