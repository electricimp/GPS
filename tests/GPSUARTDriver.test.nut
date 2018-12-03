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

// Manual tests for the UART driver. Note these tests will not test the uart configuration, only the methods used to collect and parse data.

const GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI = "$GPGLL,,,,,,V,N*64\r\n";
const GPS_SENTENCE_GLL_CHECKSUM_FULL_MI  = "$GNGLL,3723.71722,N,12206.14081,W,181858.00,A,A*67\r\n";

const GPS_SENTENCE_GGA_CHECKSUM_FULL     = "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47\r\n";
const GPS_SENTENCE_GGA_CHECKSUM_EMPTY    = "$GPGGA,,,,,,0,00,99.99,,,,,,*48\r\n";
const GPS_SENTENCE_GGA_CHECKSUM_FULL_2   = "$GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4C\r\n";

const GPS_SENTENCE_VTG_CHECKSUM_FULL     = "$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48\r\n";
const GPS_SENTENCE_VTG_CHECKSUM_EMPTY_MI = "$GNVTG,,T,,M,0.140,N,0.260,K,A*3C\r\n";

// Test configuration only includes Parser
// Include GPSUARTDriver for this test
@include "GPSUARTDriver.device.lib.nut";

// Note this test is configured for imp005. These tests do not
// use the uart, so any hardware can be used.
class GPSUARTDriverTests extends ImpTestCase {

    gps  = null;
    uart = hardware.uart1; // imp005

    function setUp() {
        gps = GPSUARTDriver(uart);
        return "GPS UART driver configured."
    }

    // Feed the private function _processByte one character of a
    // at a time - simulate uart traffic.
    function uartSimulator(str) {
        foreach(ch in str) {
            gps._processByte(ch);
        }
    }

    // Resets class variables to default state
    function resetGPSVars() {
        // Configure default GPS variable state
        gps._hasFix       = false;
        gps._gpsLine      = "";
        gps._collectData  = false;
        gps._lastLat      = null;
        gps._lastLong     = null;
        gps._lastSentence = null;
    }

    function testHasFix() {
        resetGPSVars();
        info("Default state GPS has no fix.");
        assertTrue(!gps.hasFix());

        // GPS sentence with fixQuality valid
        info("Payload with valid fixQuality updates fix.");
        uartSimulator(GPS_SENTENCE_GGA_CHECKSUM_FULL);
        assertTrue(gps.hasFix());

        // GPS sentence with fixQuality invalid
        info("Payload with invalid fixQuality updates fix.");
        uartSimulator(GPS_SENTENCE_GGA_CHECKSUM_EMPTY);
        assertTrue(!gps.hasFix());
    }

    function testLocationGetters() {
        resetGPSVars();
        info("Default state GPS has no location.");
        assertEqual(null, gps.getLatitude());
        assertEqual(null, gps.getLongitude());

        // GPS sentence with location data
        info("Payload with valid location updates location variables.");
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);
        assertEqual("37.395287", gps.getLatitude());
        assertEqual("-122.102348", gps.getLongitude());

        // GPS sentence with empty location data, prev data should still be stored
        info("Payload with empty location doesn't update location variables.");
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);
        assertEqual("37.395287", gps.getLatitude());
        assertEqual("-122.102348", gps.getLongitude());

        // GPS sentence with no location data, prev data should still be stored
        info("Payload doesn't contain location doesn't update location variables.");
        uartSimulator(GPS_SENTENCE_VTG_CHECKSUM_FULL);
        assertEqual("37.395287", gps.getLatitude());
        assertEqual("-122.102348", gps.getLongitude());
    }

    function testGetGPSSentence() {
        resetGPSVars();
        info("Default state GPS has no stored last sentence.");
        assertEqual(null, gps.getGPSSentence());

        // Check that sentence updates
        info("Payload always updates last sentence.");
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);
        assertEqual(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI, gps.getGPSSentence());

        uartSimulator(GPS_SENTENCE_GGA_CHECKSUM_FULL);
        assertEqual(GPS_SENTENCE_GGA_CHECKSUM_FULL, gps.getGPSSentence());

        uartSimulator(GPS_SENTENCE_GGA_CHECKSUM_EMPTY);
        assertEqual(GPS_SENTENCE_GGA_CHECKSUM_EMPTY, gps.getGPSSentence());
    }

    function testDRCBwParser() {
        // Test callback with parser
        gps._hasGPSParser = true;

        // Parse data false
        info("Data ready callback with parser included. Parse data set to false.");
        resetGPSVars();
        gps._parseData = false;
        local exptdDataFormat = "string";
        local exptdHasLoc;

        // Set up a callback to check for expected parameters
        gps._callback = function(hasLoc, data) {
            assertEqual(exptdHasLoc, hasLoc);
            assertEqual(exptdDataFormat, typeof data);
        }.bindenv(this);

        // GPS data no location
        info("Paylaod has no location: hasLocation is false, GPS data is a string.");
        exptdHasLoc = false;
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);

        // GPS has location
        info("Paylaod has location: hasLocation is true, GPS data is a string.");
        exptdHasLoc = true;
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);

        // Parse data true
        info("Data ready callback with parser included. Parse data set to true.");
        resetGPSVars();
        gps._parseData = true;
        exptdDataFormat = "table";

        // GPS data no location
        info("Paylaod has no location: hasLocation is false, GPS data is a table.");
        exptdHasLoc = false;
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);

        // GPS has location
        info("Paylaod has location: hasLocation is true, GPS data is a table.");
        exptdHasLoc = true;
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);

        // Reset callback
        gps._callback = null;
    }

    function testDRCBwoParser() {
        // Test callback without parser
        gps._hasGPSParser = false;
        local exptdDataFormat = "string";
        local exptdHasLoc = null;

        // Set up a callback to check for expected parameters
        gps._callback = function(hasLoc, data) {
            assertEqual(exptdHasLoc, hasLoc);
            assertEqual(exptdDataFormat, typeof data);
        }.bindenv(this);

        // Parse data false
        info("Data ready callback parser not included. Parse data set to false always returns hasLoc: null, data type string.");
        resetGPSVars();
        gps._parseData = false;

        // GPS data no location
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);

        // GPS has location
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);

        // Parse data true
        info("Data ready callback parser not included. Parse data set to true always returns hasLoc: null, data type string.");
        resetGPSVars();
        gps._parseData = true;

        // GPS data no location
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);

        // GPS has location
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);

        // Reset parser flag & callback
        gps._hasGPSParser = true;
        gps._callback = null;
    }

    function testNoParserErrors() {
        local ERROR_NO_PARSER = "No GPS parser found. Cannot parse GPS data.";
        gps._hasGPSParser = false;
        resetGPSVars();

        // GPS has location
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);

        assertEqual(ERROR_NO_PARSER, gps.hasFix());
        assertEqual(ERROR_NO_PARSER, gps.getLatitude());
        assertEqual(ERROR_NO_PARSER, gps.getLongitude());
        assertEqual(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI, gps.getGPSSentence());

        // Reset parser flag
        gps._hasGPSParser = true;
    }

    function tearDown() {}

}