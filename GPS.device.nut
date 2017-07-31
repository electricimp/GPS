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

const GPS_RMC = "GPRMC";
const GPS_GGA = "GPGGA";
const GPS_VTG = "GPVTG";
const GPS_GLL = "GPGLL";
const GPS_GSV = "GPGSV";
const GPS_GSA = "GPGSA";

class GPSFields {

    // Used to determine the validity of the data
    function calcCheckSum(sentence) {
        local check = 0;
        foreach(i in sentence) {
            if(i == '*') {
                break;
            }
            check = check ^ i;
        }
        return check;
    }
    
    // Parse GPS data into an array. This array can be indexed through the
    // following reference: http://www.gpsinformation.org/dale/nmea.htm 
    function parseFields(sentence) {
        local str = "";
        local fields = [];
        foreach(i in sentence) {
            if(i == ',' || i == '*') {
                fields.push(str);
                str = "";
            } else {
                str+=i.tochar();
            }
        }
        if(str.len() > 0) {
            fields.push(str);
        }
        return fields;
    }
    
    // Extract data into a table
    function extractData(sentence) {
        local retTable = {};
        local parsedFields = parseFields(sentence);
        if(parsedFields != null && parsedFields.len() > 0) {
            switch(parsedFields[0]) {
                // Velocity made good
                case GPS_VTG:
                    retTable.type <- GPS_VTG;
                    if(parsedFields[1] != "") {
                        retTable.trackt <- parsedFields[1];
                    }
                    if(parsedFields[7] != "") {
                        retTable.speedkmh <- parsedFields[7];
                    }
                    
                    local checkLen = parsedFields[parsedFields.len() - 1].len();
                    retTable.checkSum <- parsedFields[parsedFields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // Recommended Minimum
                case GPS_RMC:
                    retTable.type <- GPS_RMC;
                    local lat = parsedFields[3];
                    if(lat.len() <= 1) break; // no data

                    _extractTime(parsedFields[1], retTable);

                    _extractLat(lat, retTable, parsedFields[4]);

                    _extractLong(parsedFields[5], retTable, parsedFields[6]);
                    
                    retTable.status <- (parsedFields[2] == "A" ? "Active" : "Void");
                    
                    local checkLen = parsedFields[parsedFields.len() - 1].len();
                    retTable.checkSum <- parsedFields[parsedFields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // Geographic Latitude and Longitude
                case GPS_GLL:
                    retTable.type <- GPS_GLL;
                    local lat = parsedFields[1];
                    if(lat.len() <= 1) break;
                    
                    _extractLat(lat, retTable, parsedFields[2]);
                    
                    _extractLong(parsedFields[3], retTable, parsedFields[4]);

                    _extractTime(parsedFields[5], retTable);
                    
                    retTable.status <- (parsedFields[6] == "A" ? "Active" : "Void");
                    
                    local checkLen = parsedFields[parsedFields.len() - 1].len();
                    retTable.checkSum <- parsedFields[parsedFields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // Essential Fix data
                case GPS_GGA:
                    retTable.type <- GPS_GGA;
                    local lat = parsedFields[2];
                    if(lat.len() <= 1) break; // no data
                    
                    _extractTime(parsedFields[1], retTable);
                    
                    _extractLat(lat, retTable, parsedFields[3]);

                    _extractLong(parsedFields[4], retTable, parsedFields[5]);
                    
                    retTable.status <- "Active";
                    retTable.fixQuality <- parsedFields[6];
                    retTable.numSatellites <- parsedFields[7].tointeger();
                    retTable.altitude <- parsedFields[9].tofloat();
                    
                    local checkLen = parsedFields[parsedFields.len() - 1].len();
                    retTable.checkSum <- parsedFields[parsedFields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // Satellites in view
                case GPS_GSV:
                    retTable.type <- GPS_GSV;
                    retTable.numSatellites <- parsedFields[3].tointeger();
                    local checkLen = parsedFields[parsedFields.len() - 1].len();
                    retTable.checkSum <- parsedFields[parsedFields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // GPS DOP and active satellites
                case GPS_GSA:
                    retTable.type <- GPS_GSA;
                    retTable.threeDFix <- parsedFields[2];
                    local len = parsedFields.len();
                    // need to use the len b/c we don't know the number of satellite PRNs
                    retTable.PDOP <- parsedFields[len-4];
                    retTable.HDOP <- parsedFields[len-3];
                    retTable.VDOP <- parsedFields[len-2];
                    
                    local checkLen = parsedFields[parsedFields.len() - 1].len();
                    retTable.checkSum <- parsedFields[parsedFields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
            }
        }
        return retTable;
    }

    // Get the latitude from strings. Store it in tb
    function _extractLat(str, tb, direction) {
        local lat = str.slice(0, 2).tofloat() + (str.slice(2).tofloat()/60);
        if(direction == "S") lat = -lat;
        tb.latitude <- lat;
    }

    // Get the longitude from strings. Store it in tb
    function _extractLong(str, tb, direction) {
        local long = str.slice(0, 3).tofloat() + (str.slice(3).tofloat()/60);
        if(direction == "W") long = -long;
        tb.longitude <- long;
    }

    // Get the time from a string. Store it in tb
    function _extractTime(str, tb) {
        local time = str.tointeger();
                    
        tb.seconds <- time%100;
        time = time/100;
        tb.minutes <- time%100;
        time = time/100;
        tb.hours <- time; 
    }
    
}



class GPS {
    
    static VERSION = "1.0.0";

    _gpsLine = "";
    gpsCounter = 0;
    gpsRate = 30;
    _fields = null;
    _gps = null;
    _lastTable = null;
    _lastLat = 0;
    _lastLong = 0;
    _isValid = false;
    _numSatellites = 0;
    _fix = false;
    _fixCallback = null;

    static LINE_MAX = 150;
    
    constructor(uart, fixCallback, baudrate=9600) {
        _gps = uart;
        _fields = GPSFields();
        // GPS is configured by the constructor so that we can register
        // the rxdata callback
        _gps.configure(baudrate, 8, PARITY_NONE, 1, NO_CTSRTS, _gpsRxdata.bindenv(this));
        _fixCallback = fixCallback;
    }
    
    // This private method is the uart callback. It continues to append characters
    // to a line until it reaches a '$', indicating the start of a new line. Once it reaches this,
    // it parses the previous line and calls callbacks (if provided), as well as setting
    // values in the class that can be accessed (e.g. lat and long)
    function _gpsRxdata() {
        local ch = _gps.read()
        if(ch  == '$') {
            
            _lastTable = _fields.extractData(_gpsLine);
            _isValid = ("checkSum" in _lastTable && (_lastTable.checkSum ==_fields.calcCheckSum(_gpsLine)));

            _gpsLine = ""; // Reset the string after a full line has been
            // collected
            
            _setLastLatLong(_lastTable);
            _setNumSatellites(_lastTable);
            
            if(_lastTable.len() && _lastTable.type == GPS_GGA) {
                _fix = (_lastTable.fixQuality.tointeger() > 0);
            }

            _fixCallback(_fix, _lastTable);

        } else if(_gpsLine.len() > LINE_MAX) {
            _gpsLine = "";
        } else {
            _gpsLine += ch.tochar();
        }
    }

    function getLastLatitude() {
        return _lastLat;
    }
    
    function getLastLongitude() {
        return _lastLong;
    }
    
    function _setLastLatLong(tb) {
        if(tb != null && tb.len() > 1) {
            if(tb.type != GPS_VTG && tb.type != GPS_GSV && tb.type != GPS_GSA) { // VTG/GSV/GSA don't have
            // latitude/longitude data
                // Check for void data 
                if(tb.status == "Active" && _isValid) {
                    _lastLat = tb.latitude;
                    _lastLong = tb.longitude;
                }
            }
        }
    }
    
    function _setNumSatellites(tb) {
        if(tb != null && tb.len() > 1 && (tb.type == GPS_GGA || tb.type == GPS_GSV)) {
            _numSatellites = tb.numSatellites;
        }
    }
    
    function getNumSatellites() {
        return _numSatellites;
    }
}