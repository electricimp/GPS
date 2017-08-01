# GPS Device Driver

This library is a driver for GPS modules that can be interfaced with over UART. It does not support all data types received by GPS. It supports: VTG, RMC, GLL, GGA, GSV, and GSA. For information on satellite data packets, see [here](http://www.gpsinformation.org/dale/nmea.htm)

To add this library to your project, add '#require "GPS.device.lib.nut:1.0.0' to the top of your device code.

## Class Usage

### Constructor: GPS(*uart*, *fixCallback*[, *baudrate]*)

The class constructor takes two required parameters and one optional parameter. The first required parameter, *uart*, is a uart bus which need not have been previously configured. The second required parameter, *fixCallback*, is a callback that should be prepared to take two arguments: a boolean indicating whether the GPS currently has a fix, and a table containing the most recent GPS data. The third parameter, which is optional, is the *baudrate* of the GPS, which defaults to 9600 if it is not passed.

The following tables explain the fields each data type contains:

#### VTG

| Key             | Description                                            |
| --------------- | ------------------------------------------------------ |
| *type*          | The type of satellite data received                    |
| *trackt*        | True track made good (degrees)                         |
| *speedkmh*      | Speed in kilometers per hour                           |
| *checkSum*      | Check sum, used to check the validity of the data      |

#### RMC

| Key             | Description                                               |
| --------------- | --------------------------------------------------------- |
| *type*          | The type of satellite data received                       |
| *time*          | The timestamp of received data (minutes, hours, seconds)  |
| *latitude*      | The latitude received                                     |
| *longitude*     | The longitude received                                    |
| *status*        | The status of the satellite, "A" for active, "V" for void |
| *checkSum*      | Check sum, used to check the validity of the data         |

#### GLL

| Key             | Description                                               |
| --------------- | --------------------------------------------------------- |
| *type*          | The type of satellite data received                       |
| *time*          | The timestamp of received data (minutes, hours, seconds)  |
| *latitude*      | The latitude received                                     |
| *longitude*     | The longitude received                                    |
| *status*        | The status of the satellite, "A" for active, "V" for void |
| *checkSum*      | Check sum, used to check the validity of the data         |

#### GGA

| Key             | Description                                               |
| --------------- | --------------------------------------------------------- |
| *type*          | The type of satellite data received                       |
| *time*          | The timestamp of received data (minutes, hours, seconds)  |
| *latitude*      | The latitude received                                     |
| *longitude*     | The longitude received                                    |
| *status*        | The status of the satellite, "A" for active, "V" for void |
| *fixQuality*    | The quality of the satellite fix                          |
| *numSatellites* | The number of satellites being tracked                    |
| *altitude*      | Altitude, meters, above mean sea level                    |
| *checkSum*      | Check sum, used to check the validity of the data         |

#### GSV

| Key             | Description                                               |
| --------------- | --------------------------------------------------------- |
| *type*          | The type of satellite data received                       |
| *numSatellites  | The number of satellites in view                          |
| *checkSum*      | Check sum, used to check the validity of the data         |

#### GSA

| Key             | Description                                                 |
| --------------- | ----------------------------------------------------------- |
| *type*          | The type of satellite data received                         |
| *threeDFix*     | 3D fix - values include: 1 = no fix, 2 = 2D fix, 3 = 3d fix |
| *PDOP*          | Dilution of precision                                       |
| *HDOP*          | Horizontal dilution of precision                            |
| *PDOP*          | Vertical dilution of precision                              |
| *checkSum*      | Check sum, used to check the validity of the data           |

```squirrel
function myCb(fix, tb) {
	if(fix) {
		server.log(format("I have valid %s data!", tb.type));
		switch(tb.type) {
			case GPS_RMC:
				// do something with RMC
				break;
			case GPS_VTG: 
				// do something with VTG
				break;
			case GPS_GLL:
				// do something with GLL
				break;
			case GPS_GGA:
				// do something with GGA
				break;
			case GPS_GSV:
				// do something with GSV
				break;
			case GPS_GSA:
				// do something with GSA
				break;
		}
	}
}
myGPS <- GPS(hardware.uart1, myCb);
```

### getLastLocation()

The *getLastLocation()* method will return a table containing the last latitude and longitude and a table containing the time they were received.

```squirrel
local last = myGPS.getLastLocation();
server.log(format("Last lat: %f, last long: %f. Received @%d:%d:%d", last.latitude, last.longitude, last.time.hours, last.time.minutes, last.time.seconds));
```

## License

The GPS class is licensed under [MIT License](./LICENSE).