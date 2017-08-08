# GPS Device Driver

This library is a driver for GPS modules that can be interfaced over UART. It does not support all data types received by GPS. It supports VTG, RMC, GLL, GGA, GSV and GSA. For information on these formats and other satellite data packets, please see [this page](http://www.gpsinformation.org/dale/nmea.htm)

**To add this library to your project, add** `#require "GPS.device.lib.nut:1.0.0"` **to the top of your device code.**

## Class Usage

### Constructor: GPS(*uart, fixCallback[, baudrate]*)

The class constructor takes two required parameters and one optional parameter. The first required parameter, *uart*, is an imp UART bus which need not have been previously configured.

The second required parameter, *fixCallback*, is a callback function that should take two arguments: a boolean indicating whether the GPS currently has a fix, and a table containing the most recent GPS data. The table contains the key *type*, which indicates which type of data the table contains. The table’s remaining keys will depend upon the data type, and are listed in the tables below.

The third parameter, which is optional, is the *baudrate* of the GPS, which defaults to 9600.

#### VTG

| Key             | Description                                       |
| --------------- | ------------------------------------------------- |
| *type*          | *GPS_VTG*                                         |
| *trackt*        | True track made good (degrees)                    |
| *speedkmh*      | Speed in kilometers per hour                      |
| *checkSum*      | Check sum, used to check the validity of the data |

#### RMC

| Key             | Description                                               |
| --------------- | --------------------------------------------------------- |
| *type*          | *GPS_RMC*                                                 |
| *time*          | The timestamp of received data (minutes, hours, seconds)  |
| *latitude*      | The latitude received                                     |
| *longitude*     | The longitude received                                    |
| *status*        | The status of the satellite, `"A"` for active, `"V"` for void |
| *checkSum*      | Check sum, used to check the validity of the data         |

#### GLL

| Key             | Description                                               |
| --------------- | --------------------------------------------------------- |
| *type*          | *GPS_GLL*                                                 |
| *time*          | The timestamp of received data (minutes, hours, seconds)  |
| *latitude*      | The latitude received                                     |
| *longitude*     | The longitude received                                    |
| *status*        | The status of the satellite, `"A"` for active, `"V"` for void |
| *checkSum*      | Check sum, used to check the validity of the data         |

#### GGA

| Key             | Description                                               |
| --------------- | --------------------------------------------------------- |
| *type*          | *GPS_GGA*                                                 |
| *time*          | The timestamp of received data (minutes, hours, seconds)  |
| *latitude*      | The latitude received                                     |
| *longitude*     | The longitude received                                    |
| *status*        | The status of the satellite, `"A"` for active, `"V"` for void |
| *fixQuality*    | The quality of the satellite fix                          |
| *numSatellites* | The number of satellites being tracked                    |
| *altitude*      | Altitude, meters, above mean sea level                    |
| *checkSum*      | Check sum, used to check the validity of the data         |

#### GSV

| Key             | Description                                               |
| --------------- | --------------------------------------------------------- |
| *type*          | *GPS_GSV*                                                 |
| *numSatellites* | The number of satellites in view                          |
| *checkSum*      | Check sum, used to check the validity of the data         |

#### GSA

| Key             | Description                                                 |
| --------------- | ----------------------------------------------------------- |
| *type*          | *GPS_GSA*                                                   |
| *threeDFix*     | 3D fix. Values: 1 = no fix, 2 = 2D fix, 3 = 3D fix          |
| *PDOP*          | Dilution of precision                                       |
| *HDOP*          | Horizontal dilution of precision                            |
| *PDOP*          | Vertical dilution of precision                              |
| *checkSum*      | Check sum, used to check the validity of the data           |

#### Example

```squirrel
function myCallback(gotFix, data) {
    if (gotFix) {
        server.log(format("I have valid %s data!", data.type));
        switch(data.type) {
            case GPS_RMC:
                // Do something with RMC data
                break;
            case GPS_VTG: 
                // Do something with VTG data
                break;
            case GPS_GLL:
                // Do something with GLL data
                break;
            case GPS_GGA:
                // Do something with GGA data
                break;
            case GPS_GSV:
                // Do something with GSV data
                break;
            case GPS_GSA:
                // Do something with GSA data
        }
    }
}

myGPS <- GPS(hardware.uart1, myCallback);
```

### getLastLocation()

The *getLastLocation()* method will return a table containing the last detected latitude and longitude, and a table containing the time the co-ordinates were received.

```squirrel
local last = myGPS.getLastLocation();
server.log(format("Last lat: %f, last long: %f. Received @%d:%d:%d", last.latitude, last.longitude, last.time.hours, last.time.minutes, last.time.seconds));
```

## License

The GPS library is licensed under [MIT License](./LICENSE).
