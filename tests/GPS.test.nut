/***
MIT License
Copyright 2017 Electric Imp
SPDX-License-Identifier: MIT
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
***/

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

	function testSatellites() {
		return Promise(function(resolve, reject) {
				local myGPS = getGPS(function(fix, tb) {
						if (fix) {
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
