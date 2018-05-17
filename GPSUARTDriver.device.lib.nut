// MIT License
// Copyright 2017-18 Electric Imp
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

// Driver for UART GPS modules. This driver is dependant on the GPSParser class.
// This driver is focused on retrieving location data and returns data from the
// GPSParser.getGPSDataTable method. Currently only the data with sentence IDs
// VTG, RMC, GLL, GGA, GSV and GSA are supported.
class GPSUARTDriver {

    function _statics_() {
        const VERSION          = "1.0.0";
        const LINE_MAX         = 150;
        const DEFAULT_BAUDRATE = 9600;
    }

    _gps            = null;
    _gpsLine        = null;
    _callback       = null;

    _hasFix         = null;
    _lastLat        = null;
    _lastLong       = null;

    constructor(uart, baudrate = null, dataReady = null) {
        _gps     = uart;
        _hasFix  = false;
        _gpsLine = "";

        // Check optional params
        if (typeof baudrate == "function") {
            _callback = baudrate;
            baudrate = DEFAULT_BAUDRATE;
        } else if (baudrate == null) {
            baudrate = DEFAULT_BAUDRATE;
            _callback = dataReady;
        } else {
            _callback = dataReady;
        }

        // GPS is configured by the constructor so that we can register the rxdata callback
        _gps.configure(baudrate, 8, PARITY_NONE, 1, NO_CTSRTS, _gpsRxData.bindenv(this));
    }

    function hasFix() {
        return _hasFix;
    }

    function getLatitude() {
        return _lastLat;
    }

    function getLongitude() {
        return _lastLong;
    }

    // This private method is the uart callback. It continues to append characters
    // to a line until it reaches a '$', indicating the start of a new line. Once it reaches this,
    // it parses the previous line and calls callbacks (if provided), as well as setting
    // values in the class that can be accessed (e.g. lat and long)
    function _gpsRxData() {
        local ch = _gps.read();
        if (ch  == '$') {
            // Parse GPS sentence
            local fields = GPSParser.getGPSDataTable(_gpsLine);
            // A full line has been collected, Start next _gpsLine
            _gpsLine = "$";

            // Update stored _hasFix
            _hasFix = _isStatusActive(fields);
            local hasActiveLoc = (_hasFix && _hasLocation(fields));
            // Update last stored location
            if (hasActiveLoc) {
                _lastLat  = fields.latitude;
                _lastLong = fields.longitude;
            }

            // Pass Location data to callback
            if (_callback != null) _callback(hasActiveLoc, fields);
        } else if (_gpsLine.len() > LINE_MAX) {
            _gpsLine = "$";
        } else {
            _gpsLine += ch.tochar();
        }
    }

    function _hasLocation(fields) {
        return ("latitude" in fields && "longitude" in fields);
    }

    function _isStatusActive(fields) {
        return (fields != null && (("status" in fields && fields.status == "A") || ("fixQuality" in fields && fields.fixQuality != "0")));
    }

}