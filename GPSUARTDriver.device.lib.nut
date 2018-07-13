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

class GPSUARTDriver {

    static VERSION = "1.0.0";

    function _statics_() {
        const LINE_MAX          = 150;
        const DEFAULT_BAUD_RATE = 9600;
        const DEFAULT_WORD_SIZE = 8;
        const DEFAULT_STOP_BITS = 1;
        const CARRIAGE_RETURN   = 0x0D;
        const LINE_FEED         = 0x0A;
        const ERROR_NO_PARSER   = "No GPS parser found. Cannot parse GPS data.";
    }

    _gps          = null;
    _gpsLine      = null;
    _parseData    = null;
    _callback     = null;

    _collectData  = null;
    _hasGPSParser = null;

    _hasFix       = null;
    _lastLat      = null;
    _lastLong     = null;
    _lastSentence = null;

    constructor(uart, opts = {}) {
        _gps          = uart;
        _hasFix       = false;
        _gpsLine      = "";
        _collectData  = false;
        _hasGPSParser = ("GPSParser" in getroottable());

        local baudRate = ("baudRate" in opts) ? opts.baudRate : DEFAULT_BAUD_RATE;
        local wordSize = ("wordSize" in opts) ? opts.wordSize : DEFAULT_WORD_SIZE;
        local stopBits = ("stopBits" in opts) ? opts.stopBits : DEFAULT_STOP_BITS;
        local parity = ("parity" in opts) ? opts.parity : PARITY_NONE;
        if ("gspDataReady" in opts) _callback = opts.gspDataReady;

        if (_hasGPSParser) {
            _parseData = ("parseData" in opts) ? opts.parseData : true;
        } else {
            _parseData = false;
        }

        if ("rxFifoSize" in opts) _gps.setrxfifosize(opts.rxFifoSize);

        // GPS is configured by the constructor so that we can register the rxdata callback
        _gps.configure(baudRate, wordSize, parity, stopBits, NO_CTSRTS, _uartHandler.bindenv(this));
    }

    // Returns true if last GPS data received has an active fix
    function hasFix() {
        if (!_hasGPSParser) return ERROR_NO_PARSER;
        return _hasFix;
    }

    // Returns last received latitude
    function getLatitude() {
        if (!_hasGPSParser) return ERROR_NO_PARSER;
        return _lastLat;
    }

    // Returns last received longitude
    function getLongitude() {
        if (!_hasGPSParser) return ERROR_NO_PARSER;
        return _lastLong;
    }

    // Returns last received GPS sentence
    function getGPSSentence() {
        return _lastSentence;
    }

    // UART callback reads data one byte at a time
    // and if byte is valid data passes it _processByte
    function _uartHandler() {
        local byte;
        while ((byte = _gps.read()) > -1) {
            _processByte(byte);
        }
    }

    // Take one required parameter: "b" a byte. Builds a
    // _gpsLine with data, when complete gps sentence has
    // been collected passes it to _processSentence
    function _processByte(b) {
        if (b == '$') {
            // Start a new _gpsLine
            if (_gpsLine.len() > 0) _gpsLine = "";
            _gpsLine += b.tochar();

            // Toggle flag to append data to _gpsLine
            _collectData = true;
        } else if (_gpsLine.len() > LINE_MAX) {
            // Sentence is too long, data must be corrupted
            // Reset _gpsLine and wait for next start char.
            _gpsLine = "";
            _collectData = false;
        } else if (_collectData) {
            // Append charater to _gpsLine
            _gpsLine += b.tochar();

            // If we just appended the last char in GPS sentence
            // process sentence
            if (b == LINE_FEED) {
                // Store GPS sentence
                _lastSentence = _gpsLine;
                // Reset gps_line
                _gpsLine = "";
                // Toggle flag to stop adding data to _gpsLine
                _collectData = false;
                // Process latest GPS sentence
                _processSentence(_lastSentence);
            }
        }
    }

    // Take one required parameter: "gpsData" a gps sentence.
    // If parsed library is included then parses data and updates
    // _lastLat, _lastLong, and _hasFix. Passed either sentence or
    // parsed data to dataReady callback if there is one.
    function _processSentence(gpsData) {
         // Set callback param defaults
        local hasLocation = null;

        // If have parser, update lat, lng, fix and callback vars
        if (_hasGPSParser) {
            // Parse GPS sentence
            local parsed = GPSParser.getGPSDataTable(gpsData);
            // Update _hasFix
            _updateFix(parsed);
            // Update last stored location
            hasLocation = hasActiveLoc(parsed);
            if (hasLocation) {
                _lastLat  = parsed.latitude;
                _lastLong = parsed.longitude;
            }
            if (_parseData) gpsData = parsed;
        }

        // Call callback
        if (_callback != null) _callback(hasLocation, gpsData);
    }

    // Helper function that returns boolean if status is active and latitude and longitude
    // slots are in the "gpsData" table passed in.
    function hasActiveLoc(gpsData) {
        return (_isActive(gpsData) && "latitude" in gpsData && "longitude" in gpsData);
    }

    // Helper function that updated _hasFix based on latest GGS messages.
    function _updateFix(gpsData) {
        if (gpsData != null && gpsData.sentenceId == GPS_PARSER_GGA && "fixQuality" in gpsData) {
            _hasFix = (gpsData.fixQuality != "0");
        }
    }

    // Helper function that returns boolean if active status or fixQuality
    // indicates GPS has a active location data.
    function _isActive(gpsData) {
        return (gpsData != null && (("status" in gpsData && gpsData.status == "A") || ("fixQuality" in gpsData && gpsData.fixQuality != "0")));
    }

}