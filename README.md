# GPS

Electric Imp offers two GPS libraries. A driver for GPS modules that can be interfaced over UART, and a GPS parser.

[![Build Status](https://api.travis-ci.org/electricimp/GPS.svg?branch=master)](https://travis-ci.org/electricimp/GPS)

## GPSParser

This library is a parser for standard NMEA sentences used by GPS devices.

All data is transmitted in the form of sentences. Only printable ASCII characters plus CR (carriage return) and LF (line feed) are allowed in a GPS sentence. The expected sentence format starts with *$*, followed by two letters, the talker identifier, and the next three characters are the sentence identifier. Following the the identifiers are a number of data fields separated by commas, followed by an optional checksum, and terminated by carriage return and line feed. The data fields are uniquely defined for each sentence type.

For information on formats used in satellite data packets, please see [this page](http://www.gpsinformation.org/dale/nmea.htm).

**To add this library to your project, add** `#require "GPSParser.device.lib.nut:1.0.0"` **to the top of your device code.**

### Usage

GPSParser has no constructor. There is no need to create an instance. All methods listed below can be called on GPSParser directly.


#### getFields(*sentence*)

Takes a GPS sentence and returns an array of data fields. The first item in the array will always be the talker/sentence identifier. All data fields will be included even if they only contain an empty string. If the sentence included a check sum this will be the last item in the array.

```
local sentence = "$GPGGA,,,,,,0,00,99.99,,,,,,*48\r\n";
local fields = GPSParser.getFields(sentence);
foreach (idx, item in fields) {
    server.log(idx + ": " + item);
}
```

#### hasCheckSum(*sentence*)

Takes a GPS sentence and returns a boolean, `true` if the sentence contains a check sum value, `false` otherwise.

```
local sentence = "$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48\r\n";
local hasChecksum = GPSParser.hasCheckSum(sentence);
if (hasChecksum) {
    local checksum = GPSParser.getFields.top();
    server.log(format("0x%s", checksum));
}
```

#### isValid(*sentence*)

Takes a GPS sentence and returns a boolean, `true` if the check sum in the sentence matches the check sum calculated for that sentence, `false` otherwise.

```
local sentence = "$GPGLL,4916.45,N,12311.12,W,225444,A,*1D\r\n";
if (GPSParser.isValid(sentence)) {
    server.log("GPS sentence check sum is valid.");
}
```

#### getGPSDataTable(*sentence*)

Takes a GPS sentence and returns a table. This method does not support all data types received by GPS. Currently it supports VTG, RMC, GLL, GGA, GSV and GSA. The data table will always contain the keys *talkerId* and *sentenceId*, which indicate the type of GPS message. However all other keys will only be included if the GPS sentence contains data. See below for details on the possible key, value pairs for each of the supported data types.

##### VTG - Vector track an Speed over the Ground

| Key             | Data Type | Description                                                     |
| --------------- | --------- | --------------------------------------------------------------- |
| *talkerId*      | String    | Talker identifier, ie "GP", "GN"                                |
| *sentenceId*    | String    | Sentence identifier - "VTG" or class constant *GPSParser_VTG*   |
| *tTrack*        | String    | True track made good (degrees)                                  |
| *mTrack*        | String    | Magnetic track made good                                        |
| *speedKnots*    | String    | Ground speed, knots                                             |
| *speedKPH*      | String    | Ground speed, Kilometers per hour                               |
| *modeIndicator* | String    | Signal integrity, A=autonomous, D=differential, E=Estimated, N=not valid, S=Simulator |
| *error*         | String    | Error discription                                               |

##### RMC - Recommended minimum data for gps (position, velocity, time)

| Key             | Data Type | Description                                                     |
| --------------- | --------- | --------------------------------------------------------------- |
| *talkerId*      | String    | Talker identifier, ie "GP", "GN"                                |
| *sentenceId*    | String    | Sentence identifier - "RMC" or class constant *GPSParser_RMC*   |
| *time*          | String    | UTC Time fix taken at "hhmmss"                                  |
| *date*          | String    | Date fix taken at "ddmmyy"                                      |
| *speedKnots*    | String    | Speed over the ground in knots                                  |
| *trackAngle*    | String    | Track angle in degrees True                                     |
| *latitude*      | String    | The latitude received in decimal degrees                        |
| *longitude*     | String    | The longitude received in decimal degrees                       |
| *status*        | String    | The status of the satellite, A=active or V=Void                 |
| *mVar*          | String    | Magnetic Variation, degrees                                     |
| *modeIndicator* | String    | Signal integrity, A=autonomous, D=differential, E=Estimated, N=not valid, S=Simulator |
| *error*         | String    | Error discription                                               |

##### GLL - Geographic position, Latitude and Longitude

| Key             | Data Type | Description                                                     |
| --------------- | --------- | --------------------------------------------------------------- |
| *talkerId*      | String    | Talker identifier, ie "GP", "GN"                                |
| *sentenceId*    | String    | Sentence identifier - "GLL" or class constant *GPSParser_GLL*   |
| *time*          | String    | UTC Time fix taken at "hhmmss"                                  |
| *status*        | String    | The status of the satellite, A=active or V=Void                 |
| *latitude*      | String    | The latitude received in decimal degrees                        |
| *longitude*     | String    | The longitude received in decimal degrees                       |
| *modeIndicator* | String    | Signal integrity, A=autonomous, D=differential, E=Estimated, N=not valid, S=Simulator |
| *error*         | String    | Error discription                                               |

##### GGA - Global Positioning System Fix Data

| Key             | Data Type | Description                                                     |
| --------------- | --------- | --------------------------------------------------------------- |
| *talkerId*      | String    | Talker identifier, ie "GP", "GN"                                |
| *sentenceId*    | String    | Sentence identifier - "GGA" or class constant *GPSParser_GGA*   |
| *time*          | String    | UTC Time fix taken at "hhmmss"                                  |
| *latitude*      | String    | The latitude received in decimal degrees                        |
| *longitude*     | String    | The longitude received in decimal degrees                       |
| *fixQuality*    | String    | The quality of the satellite fix, 0=invalid or 1-8 fix info     |
| *numSatellites* | String    | The number of satellites being tracked                          |
| *HDOP*          | String    | Horizontal dilution of position                                 |
| *altitude*      | String    | Altitude, meters, above mean sea level                          |
| *geoSeparation* | String    | Height, meters, of geoid (mean sea level) above WGS84 ellipsoid |
| *lastDGPSUpdate*| String    | Time in seconds since last DGPS update                          |
| *DGPSStationID* | String    | DGPS station ID number                                          |
| *error*         | String    | Error discription                                               |

##### GSV - Satellites in view

| Key             | Data Type | Description                                                     |
| --------------- | --------- | --------------------------------------------------------------- |
| *talkerId*      | String    | Talker identifier, ie "GP", "GN"                                |
| *sentenceId*    | String    | Sentence identifier - "GSV" or class constant *GPSParser_GSV*   |
| *numMsgs*       | String    | Total number of messages                                        |
| *msgNum*        | String    | Message number                                                  |
| *numSatellites* | String    | Number of satellites in view                                    |
| *satelliteInfo* | Array     | Array of tables with detailed satellite info (satellitePRN, elevation, azimuth, snr) |
| *error*         | String    | Error discription                                               |

##### GSA - Overall Satellite data

| Key             | Data Type | Description                                                     |
| --------------- | --------- | --------------------------------------------------------------- |
| *talkerId*      | String    | Talker identifier, ie "GP", "GN"                                |
| *sentenceId*    | String    | Sentence identifier - "GSA" or class constant *GPSParser_GSA*   |
| *selMode*       | String    | Selection mode A=Auto, M=Manual                                 |
| *mode*          | String    | Mode,  1=no fix, 2=2D fix, 3=3D fix                             |
| *satellitePRNs* | Array     | PRNs (Ids) of satellites used for fix                           |
| *PDOP*          | String    | Dilution of precision                                           |
| *HDOP*          | String    | Horizontal dilution of precision                                |
| *VDOP*          | String    | Vertical dilution of precision                                  |
| *error*         | String    | Error discription                                               |


```
local sentence = "$GPGLL,4916.45,N,12311.12,W,225444,A,*1D\r\n";
local gpsData = GPSParser.getGPSDataTable(sentence);
if gpsData.sentenceId == GPSParser_GLL) {
    server.log("GLL msg received.");
    if (gpsData.status == "A" && "latitude" in gpsData && "longitude" in gpsData) {
        server.log(format("Latitude %s, Longitude %s", gpsData.latitude, gpsData.longitude));
    } else {
        server.log("Location data not available.");
    }
}
```


#### parseLatitude(*latDegMin, direction*)

Takes the 2 latitude fields from the GPS sentence, the numeric degree decimal minutes string and the direction letter, and returns a string containing the latitude in decimal degrees.

#### parseLongitude(*lngDegMin, direction*)

Takes the 2 longitude fields from the GPS sentence, the numeric degree decimal minutes string and the direction letter, and returns a string containing the longitude in decimal degrees.

```
local sentence = "$GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4C\r\n";
local fields = GPSParser.getFields(sentence);
local type = fields[0].slice(2);
if (type == GPSParser_GGA) {
    // Get Latitude
    if (fields[2]  != "" && fields[3]  != "") {
        local lat = parseLatitude(fields[2], fields[3]);
        server.log("Latitude: " + lat);
    }
    // Get Longitude
    if (fields[4]  != "" && fields[5]  != "") {
        local lng = parseLongitude(fields[4], fields[5]);
        server.log("Longitude: " + lng);
    }
}
```


## GPSUARTDriver

This library is a driver class for GPS modules that can be interfaced over UART. It has been tested on UBlox NEO-M8N and UBlox LEA-6S modules. The driver must be used with the GPSParser library, and only supports VTG, RMC, GLL, GGA, GSV and GSA formats.

**To use this library in your project, add**
`#require "GPSParser.device.lib.nut:1.0.0"`
`#require "GPSUARTDriver.device.lib.nut:1.0.0"`
**to the top of your device code.**

### Class Usage

#### Constructor: GPSParser(*uart[, baudrate][, dataReadyCallback]*)

The constructor takes one required parameter and two optional parameters. The first parameter (required), *uart*, is an imp UART bus which will be configured by the constructor. The second parameter (optional), *baudrate*, is the baud rate the UART will be configured with. If no value is passed in *baudrate* will default to 9600. The third paramter (optional), *dataReadyCallback*, is a function that will be called whenever new GPS data is received.

The *dataReadyCallback* callback takes two required paramters: a boolean *hasActiveLocation* indicating whether the GPS currently has a fix and location data, and a table *gpsData* containing the most recent GPS data. See *GPSParser.getGPSDataTable* method description above for details on the *gpsData* table.

### Class Methods

#### hasFix()

Returns a boolean `true` if the GPS moduled has enough data to get a fix on the devices location, `false` otherwirse.

#### getLatitude()

Returns a string with the last known latitude value in decimal degrees. If no latitude has been found this method will return `null`.

#### getLongitude()

Returns a string with the last known longitude value in decimal degrees. If no longitude has been found this method will return `null`.

##### Example

```squirrel
#require "GPSParser.device.lib.nut:1.0.0"
#require "GPSUARTDriver.device.lib.nut:1.0.0"

class LocationLogger {
    gps = null;

    constructor() {
        gps = GPSUARTDriver(hardware.uart1, gpsHandler.bindenv(this));
    }

    function gpsHandler(hasLoc, data) {
            if (hasLoc) {
                server.log(format("Latitude: %s, Longitude: %s", gps.getLatitude(), gps.getLongitude()));
                server.log(gps.getLatitude());
                server.log(gps.getLongitude());
            } else if (!gps.hasFix() && "numSatellites" in data) {
                server.log("Satellites: " + data.numSatellites);
            }
        }
}

LocationLogger();
```

## License

The GPSParser and GPSUARTDriver libraries are licensed under [MIT License](./LICENSE).