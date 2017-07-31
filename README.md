# GPS Device Driver

This library is a driver for GPS modules that can be interfaced with over UART. It does not support all data types received by GPS.

To add this library to your project, add** '#require "GPS.device.lib.nut:1.0.0' **to the top of your device code**

## Class Usage

### Constructor: GPS(*uart*, *fixCallback*[, *baudrate]*)

The class constructor takes two required parameters and one optional parameter. The first required parameter, *uart*, is a uart bus which need not have been previously configured. The second required parameter, *fixCallback*, is a callback that should be prepared to take two arguments: a boolean indicating whether the GPS currently has a fix, and a table containing the most recent GPS data. The third parameter, which is optional, is the *baudrate* of the GPS, which defaults to 9600 if it is not passed.

```squirrel
function myCb(fix, tb) {
	if(fix) {
		server.log(format("I have valid %s data!", tb.type));
	}
}
myGPS <- GPS(hardware.uart1, myCb);
```

### getLastLatitude()

The *getLastLatitude()* method will return the last valid latitude data received.

```squirrel
local myLat = myGPS.getLastLatitude();
```

### getLastLongitude()

The *getLastLongitude()* method will return the last valid longitude data received.

```squirrel
local myLong = myGPS.getLastLongitude();
```

### getNumSatellites()

The *getNumSatellites()* method will return the last number of satellites reported.

```squirrel
local numSats = myGPS.getNumSatellites();
```

## License

The GPS class is licensed under [MIT License](./LICENSE).