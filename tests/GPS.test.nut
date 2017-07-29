@include "github:electricimp/GPS/GPS.device.nut@develop"

class MyTestCase extends ImpTestCase {
	// for CA, USA
	static MIN_LONGITUDE = -124;
	static MAX_LONGITUDE = -114;

	static MIN_LATITUDE = 32;
	static MAX_LATITUDE = 42;

	function getGPS(cb) {
		return GPS(hardware.uart1, cb);
	}

	function testCoordinates() {
		return Promise(function(resolve, reject) {
			local myGPS = getGPS(function(fix, tb) {
					if (fix) {
						if ((tb.latitude <= MAX_LATITUDE) &&
							(tb.latitude >= MIN_LATITUDE) && (tb.longitude < MAX_LONGITUDE) &&
							(tb.longitude >= MIN_LONGITUDE)) {
								resolve("correct coordinates");
						} else {
							reject(format("incorrect coordinates: lat=%f, long=%f", tb.latitude, tb.longitude));
						}
					}
				}.bindenv(this));
		}.bindenv(this));
	}

	function satelliteCb(fix, tb) {
		
	}

	function testSatellites() {
		return Promise(function(resolve, reject) {
				local myGPS = getGPS(function(fix, tb) {
						if(fix) {
							if (tb.numSatellites > 0) {
								resolve("fix with non-zero satellites");
							} else {
								reject("fix but no satellites");
							}
						}
					}.bindenv(this));
			}.bindenv(this));
	}
}
