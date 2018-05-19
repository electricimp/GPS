// Manual tests for the UART driver. Note these tests will not test the uart configuration, only the methods used to collect and parse data.


const GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI = "$GPGLL,,,,,,V,N*64\r\n";
const GPS_SENTENCE_GLL_CHECKSUM_FULL_MI  = "$GNGLL,3723.71722,N,12206.14081,W,181858.00,A,A*67\r\n";

const GPS_SENTENCE_GGA_CHECKSUM_FULL     = "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47\r\n";
const GPS_SENTENCE_GGA_CHECKSUM_EMPTY    = "$GPGGA,,,,,,0,00,99.99,,,,,,*48\r\n";
const GPS_SENTENCE_GGA_CHECKSUM_FULL_2   = "$GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4C\r\n";

const GPS_SENTENCE_VTG_CHECKSUM_FULL     = "$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48\r\n";
const GPS_SENTENCE_VTG_CHECKSUM_EMPTY_MI = "$GNVTG,,T,,M,0.140,N,0.260,K,A*3C\r\n";

// Include GPSUARTDriver
@include "GPSUARTDriver.device.lib.nut";

// class GPSUARTDriver {

//     static VERSION = "1.0.0";

//     function _statics_() {
//         const LINE_MAX          = 150;
//         const DEFAULT_BAUD_RATE = 9600;
//         const DEFAULT_WORD_SIZE = 8;
//         const DEFAULT_STOP_BITS = 1;
//         const CARRIAGE_RETURN   = 0x0D;
//         const LINE_FEED         = 0x0A;
//         const ERROR_NO_PARSER   = "No GPS parser found. Cannot parse GPS data.";
//     }

//     _gps          = null;
//     _gpsLine      = null;
//     _parseData    = null;
//     _callback     = null;

//     _collectData  = null;
//     _hasGPSParser = null;

//     _hasFix       = null;
//     _lastLat      = null;
//     _lastLong     = null;
//     _lastSentence = null;

//     constructor(uart, opts = {}) {
//         _gps          = uart;
//         _hasFix       = false;
//         _gpsLine      = "";
//         _collectData  = false;
//         _hasGPSParser = ("GPSParser" in getroottable());

//         local baudRate = ("baudRate" in opts) ? opts.baudRate : DEFAULT_BAUD_RATE;
//         local wordSize = ("wordSize" in opts) ? opts.wordSize : DEFAULT_WORD_SIZE;
//         local stopBits = ("stopBits" in opts) ? opts.stopBits : DEFAULT_STOP_BITS;
//         local parity = ("parity" in opts) ? opts.parity : PARITY_NONE;
//         if ("gspDataReady" in opts) _callback = opts.gspDataReady;
//         if (_hasGPSParser) {
//             _parseData = ("parseData" in opts) ? opts.parseData : true;
//         } else {
//             _parseData = false;
//         }

//         // GPS is configured by the constructor so that we can register the rxdata callback
//         _gps.configure(baudRate, wordSize, parity, stopBits, NO_CTSRTS, _uartHandler.bindenv(this));
//     }

//     // Returns true if last GPS data received has an active fix
//     function hasFix() {
//         if (!_hasGPSParser) return ERROR_NO_PARSER;
//         return _hasFix;
//     }

//     // Returns last received latitude
//     function getLatitude() {
//         if (!_hasGPSParser) return ERROR_NO_PARSER;
//         return _lastLat;
//     }

//     // Returns last received longitude
//     function getLongitude() {
//         if (!_hasGPSParser) return ERROR_NO_PARSER;
//         return _lastLong;
//     }

//     // Returns last received GPS sentence
//     function getGPSSentence() {
//         return _lastSentence;
//     }

//     // UART callback reads data one byte at a time
//     // and if byte is valid data passes it _processByte
//     function _uartHandler() {
//         local byte;
//         while ((byte = _gps.read()) > -1) {
//             _processByte(byte);
//         }
//     }

//     // Take one required parameter: "b" a byte. Builds a
//     // _gpsLine with data, when complete gps sentence has
//     // been collected passes it to _processSentence
//     function _processByte(b) {
//         if (b == '$') {
//             // Start a new _gpsLine
//             if (_gpsLine.len() > 0) _gpsLine = "";
//             _gpsLine += b.tochar();

//             // Toggle flag to append data to _gpsLine
//             _collectData = true;
//         } else if (_gpsLine.len() > LINE_MAX) {
//             // Sentence is too long, data must be corrupted
//             // Reset _gpsLine and wait for next start char.
//             _gpsLine = "";
//             _collectData = false;
//         } else if (_collectData) {
//             // Append charater to _gpsLine
//             _gpsLine += b.tochar();

//             // If we just appended the last char in GPS sentence
//             // process sentence
//             if (b == LINE_FEED) {
//                 // Store GPS sentence
//                 _lastSentence = _gpsLine;
//                 // Reset gps_line
//                 _gpsLine = "";
//                 // Toggle flag to stop adding data to _gpsLine
//                 _collectData = false;
//                 // Process latest GPS sentence
//                 _processSentence(_lastSentence);
//             }
//         }
//     }

//     // Take one required parameter: "gpsData" a gps sentence.
//     // If parsed library is included then parses data and updates
//     // _lastLat, _lastLong, and _hasFix. Passed either sentence or
//     // parsed data to dataReady callback if there is one.
//     function _processSentence(gpsData) {
//          // Set callback param defaults
//         local hasLocation = null;

//         // If have parser, update lat, lng, fix and callback vars
//         if (_hasGPSParser) {
//             // Parse GPS sentence
//             local parsed = GPSParser.getGPSDataTable(gpsData);
//             // Update _hasFix
//             _updateFix(parsed);
//             // Update last stored location
//             hasLocation = hasActiveLoc(parsed);
//             if (hasLocation) {
//                 _lastLat  = parsed.latitude;
//                 _lastLong = parsed.longitude;
//             }
//             if (_parseData) gpsData = parsed;
//         }

//         // Call callback
//         if (_callback != null) _callback(hasLocation, gpsData);
//     }

//     // Helper function that returns boolean if status is active and latitude and longitude
//     // slots are in the "gpsData" table passed in.
//     function hasActiveLoc(gpsData) {
//         return (_isActive(gpsData) && "latitude" in gpsData && "longitude" in gpsData);
//     }

//     // Helper function that updated _hasFix based on latest GGS messages.
//     function _updateFix(gpsData) {
//         if (gpsData != null && gpsData.sentenceId == GPS_PARSER_GGA && "fixQuality" in gpsData) {
//             _hasFix = (gpsData.fixQuality != "0");
//         }
//     }

//     // Helper function that returns boolean if active status or fixQuality
//     // indicates GPS has a active location data.
//     function _isActive(gpsData) {
//         return (gpsData != null && (("status" in gpsData && gpsData.status == "A") || ("fixQuality" in gpsData && gpsData.fixQuality != "0")));
//     }

// }

class GPSUARTDriverTests extends ImpTestCase {

    gps  = null;
    uart = hardware.uart1; // imp005

    function setUp() {
        gps = GPSUARTDriver(uart);
    }

    function uartSimulator(str) {
        foreach(ch in str) {
            gps._processByte(ch);
        }
    }

    function resetGSPVars() {
        // Configure default GPS variable state
        gps._hasFix       = false;
        gps._gpsLine      = "";
        gps._collectData  = false;
        gps._lastLat      = null;
        gps._lastLong     = null;
        gps._lastSentence = null;
    }

    function testHasFix() {
        resetGSPVars();
        assertTrue(!gps.hasFix());
        // GPS sentence with fixQuality valid
        uartSimulator(GPS_SENTENCE_GGA_CHECKSUM_FULL);
        assertTrue(gps.hasFix());
        // GPS sentence with fixQuality invalid
        uartSimulator(GPS_SENTENCE_GGA_CHECKSUM_EMPTY);
        assertTrue(!gps.hasFix());
    }

    function testLocationGetters() {
        resetGSPVars();
        assertEqual(null, gps.getLatitude());
        assertEqual(null, gps.getLongitude());

        // GPS sentence with location data
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);
        assertEqual("37.395287", gps.getLatitude());
        assertEqual("-122.102348", gps.getLongitude());

        // GPS sentence with empty location data, prev data should still be stored
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);
        assertEqual("37.395287", gps.getLatitude());
        assertEqual("-122.102348", gps.getLongitude());

        // GPS sentence with no location data, prev data should still be stored
        uartSimulator(GPS_SENTENCE_VTG_CHECKSUM_FULL);
        assertEqual("37.395287", gps.getLatitude());
        assertEqual("-122.102348", gps.getLongitude());
    }

    function testGetGPSSentence() {
        resetGSPVars();
        assertEqual(null, gps.getGPSSentence());

        // Check that sentence updates
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);
        assertEqual(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI, gps.getGPSSentence());

        uartSimulator(GPS_SENTENCE_GGA_CHECKSUM_FULL);
        assertEqual(GPS_SENTENCE_GGA_CHECKSUM_FULL, gps.getGPSSentence());

        uartSimulator(GPS_SENTENCE_GGA_CHECKSUM_EMPTY);
        assertEqual(GPS_SENTENCE_GGA_CHECKSUM_EMPTY, gps.getGPSSentence());
    }

    function testDRCB_W_Parser() {
        // Test callback with parser
        gps._hasGPSParser = true;

        // Parse data false
        resetGSPVars();
        gps._parseData = false;
        local exptdDataFormat = "string";
        local exptdHasLoc;

        gps._callback = function(hasLoc, data) {
            assertEqual(exptdHasLoc, hasLoc);
            assertEqual(exptdDataFormat, typeof data);
        }.bindenv(this);

        // GPS data no location
        exptdHasLoc = false;
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);

        // GPS has location
        exptdHasLoc = true;
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);

        // Parse data true
        resetGSPVars();
        gps._parseData = true;
        exptdDataFormat = "table";

        // GPS data no location
        exptdHasLoc = false;
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);

        // GPS has location
        exptdHasLoc = true;
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);

        // Reset callback
        gps._callback = null;
    }

    function testDRCB_WO_Parser() {
        // Test callback without parser
        gps._hasGPSParser = false;
        local exptdDataFormat = "string";
        local exptdHasLoc = null;

        gps._callback = function(hasLoc, data) {
            assertEqual(exptdHasLoc, hasLoc);
            assertEqual(exptdDataFormat, typeof data);
        }.bindenv(this);

        // Parse data false
        resetGSPVars();
        gps._parseData = false;

        // GPS data no location
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);

        // GPS has location
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);

        // Parse data true
        resetGSPVars();
        gps._parseData = true;

        // GPS data no location
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);

        // GPS has location
        uartSimulator(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);

        // Reset parser flag & callback
        gps._hasGPSParser = true;
        gps._callback = null;
    }

    function tearDown() {}

}