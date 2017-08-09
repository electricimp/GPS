// MIT License
// Copyright 2017 Electric Imp
// SPDX-License-Identifier: MIT
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

class GPSWrapper {

    myPromiseCb = null;
    myGPS = null;

    constructor() {
        local instance = this;
        myPromiseCb = function(resolve, reject) {
            instance.myGPS = GPS(hardware.uart1, function(fix, tb) {
                if(fix) {
                    if("latitude" in tb) {
                        local methodTb = instance.myGPS.getLastLocation();
                        if((methodTb.latitude == tb.latitude) && (methodTb.longitude == tb.longitude) &&
                           (methodTb.time.seconds == tb.time.seconds) && (methodTb.time.minutes == tb.time.minutes) &&
                           (methodTb.time.hours == tb.time.hours)) {
                            resolve("callback and method produced tables match");
                        } else {
                            reject("callback and method produced tables do not match");
                        }
                    }
                }
            }.bindenv(this));
        }.bindenv(this);
    }
}

class MyTestCase extends ImpTestCase {

    // for CA, USA
    static MIN_LONGITUDE = -124;
    static MAX_LONGITUDE = -114;

    static MIN_LATITUDE = 32;
    static MAX_LATITUDE = 42;

    static MAX_SECOND_DIFFERENCE = 10;

    static FIX_TIMEOUT = 10;

    function getGPS(cb) {
        return GPS(hardware.uart1, cb);
    }

    function testCoordinates() {
        return Promise(function(resolve, reject) {
            local myGPS = getGPS(function(fix, tb) {
                if (fix) {
                    if("latitude" in tb) { // don't need to check longitude b/c it will necessarily be there if latitude is there
                        if ((tb.latitude <= MAX_LATITUDE) &&
                            (tb.latitude >= MIN_LATITUDE) && (tb.longitude < MAX_LONGITUDE) &&
                            (tb.longitude >= MIN_LONGITUDE)) {
                            resolve("correct coordinates");
                        } else {
                            reject(format("incorrect coordinates: lat=%f, long=%f", tb.latitude, tb.longitude));
                        }
                    }
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    function testSatellites() {
        return Promise(function(resolve, reject) {
            local myGPS = getGPS(function(fix, tb) {
                if (fix) {
                    if("numSatellites" in tb) {
                        if (tb.numSatellites > 0) {
                            resolve("fix with non-zero satellites");
                        } else {
                            reject("fix but no satellites");
                        }
                    }
                }
            }.bindenv(this));
        }.bindenv(this));
    }
    
    function testTime() {
        return Promise(function(resolve, reject) {
            local myGPS = getGPS(function(fix, tb) {
                if(fix) {
                    if("time" in tb) {
                        local impTime = date();
                        local impTimeSeconds = (impTime.sec) + (impTime.min * 60) + (impTime.hour * 60 * 60);
                        local satTimeSeconds = tb.time.seconds + (tb.time.minutes * 60) + (tb.time.hours * 60 * 60);
                        if(math.abs(impTimeSeconds-satTimeSeconds) <= MAX_SECOND_DIFFERENCE) {
                            resolve("correct time received from recent satellite data");
                        } else {
                            reject("incorrect time received from recent satellite data");
                        }
                    }
                }
            }.bindenv(this));
        }.bindenv(this));
    }
    
    function testGetLastLocation() {
        local wrap = GPSWrapper();
        return Promise(wrap.myPromiseCb.bindenv(this));
    }   

    function testNoFix() {
        return Promise(function(resolve, reject) {
            imp.wakeup(FIX_TIMEOUT, function() {
                resolve("could not test no fix because fix was always obtained");
            }.bindenv(this));
            local myGPS = getGPS(function(fix, tb) {
                if(!fix) {
                    // make sure there is no fix because there were no satellites
                    if("fixQuality" in tb) {
                        if(!(tb.fixQuality.tointeger())) {
                            resolve("data correctly reported no fix");
                        } else {
                            reject("data incorrectly reported no fix");
                        }
                    }
                }
            }.bindenv(this));
        }.bindenv(this));
    }

}
