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

const GPS_SENTENCE_VTG_CHECKSUM_FULL     = "$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48\r\n";
const GPS_SENTENCE_VTG_CHECKSUM_EMPTY_MI = "$GNVTG,,T,,M,0.140,N,0.260,K,A*3C\r\n";

const GPS_SENTENCE_RMC_CHECKSUM_FULL     = "$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A\r\n";
const GPS_SENTENCE_RMC_CHECKSUM_EMPTY_MI = "$GPRMC,,V,,,,,,,,,,N*53\r\n";
const GPS_SENTENCE_RMC_CHECKSUM_MORE_MI  = "$GNRMC,181859.00,A,3723.71721,N,12206.14085,W,0.140,,090518,,,A*78\r\n";

const GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI = "$GPGLL,,,,,,V,N*64\r\n";
const GPS_SENTENCE_GLL_CHECKSUM_FULL_MI  = "$GNGLL,3723.71722,N,12206.14081,W,181858.00,A,A*67\r\n";

const GPS_SENTENCE_GGA_CHECKSUM_FULL     = "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47\r\n";
const GPS_SENTENCE_GGA_CHECKSUM_EMPTY    = "$GPGGA,,,,,,0,00,99.99,,,,,,*48\r\n";
const GPS_SENTENCE_GGA_CHECKSUM_FULL_2   = "$GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4C\r\n";

const GPS_SENTENCE_GSV_CHECKSUM_FULL     = "$GPGSV,2,1,08,01,40,083,46,02,17,308,41,12,07,344,39,14,22,228,45*75\r\n";
const GPS_SENTENCE_GSV_CHECKSUM_EMPTY    = "$GPGSV,1,1,01,22,,,18*71\r\n";
const GPS_SENTENCE_GSV_CHECKSUM_LG_M_PT1 = "$GPGSV,3,1,11,01,02,114,,05,16,266,23,07,56,075,35,08,30,051,36*77\r\n";
const GPS_SENTENCE_GSV_CHECKSUM_LG_M_PT2 = "$GPGSV,3,2,11,09,25,160,20,11,24,105,16,13,27,316,25,17,16,186,*7C\r\n";
const GPS_SENTENCE_GSV_CHECKSUM_LG_M_PT3 = "$GPGSV,3,3,11,18,06,092,27,28,71,272,17,30,71,012,37*47\r\n";
const GPS_SENTENCE_GSV_CHECKSUM_SM_M_PT1 = "$GLGSV,3,1,09,70,38,293,,71,08,336,13,73,01,274,,78,09,074,30*62\r\n";
const GPS_SENTENCE_GSV_CHECKSUM_SM_M_PT2 = "$GLGSV,3,2,09,79,41,044,32,80,42,310,26,81,38,086,37,82,23,143,21*69\r\n";
const GPS_SENTENCE_GSV_CHECKSUM_SM_M_PT3 = "$GLGSV,3,3,09,88,18,034,28*58\r\n";

const GPS_SENTENCE_GSA_CHECKSUM_EMPTY    = "$GPGSA,A,1,,,,,,,,,,,,,99.99,99.99,99.99*30\r\n";
const GPS_SENTENCE_GSA_CHECKSUM_SOME     = "$GPGSA,A,3,04,05,,09,12,,,24,,,,,2.5,1.3,2.1*39\r\n";
const GPS_SENTENCE_GSA_CHECKSUM_MORE     = "$GNGSA,A,3,30,07,08,05,11,13,18,,,,,,1.45,0.97,1.08*19\r\n";

const GPS_SENTENCE_NO_CHECKSUM           = "$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K\r\n";
const GPS_CHECKSUM_INCORRECT             = "$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*23\r\n";
const GPS_UNSUPPORTED_TYPE               = "$GPXTE,A,A,0.67,L,N*6F\r\n";

class GPSParserTests extends ImpTestCase {

    function setUp() {}

    function testGetFields() {
        local a = GPSParser.getFields(GPS_SENTENCE_RMC_CHECKSUM_EMPTY_MI);
        local b = GPSParser.getFields(GPS_SENTENCE_RMC_CHECKSUM_MORE_MI);
        local c = GPSParser.getFields(GPS_SENTENCE_NO_CHECKSUM);

        // Array is returned for data with check sum
        info("Check sentences with and without check sums return correct data type.");
        assertTrue(typeof a == "array", "Payload with check sum. Expected data type not returned.");
        // Array is returned for data without check sum
        assertTrue(typeof c == "array", "Payload without check sum. Expected data type not returned.");

        // Check that empty fields are being included
        info("Check empty fields are included when parsed.");
        assertEqual(a.len(), b.len(), "Length of different RMC msgs did not match");
        assertEqual("", a[5], "Empty string expected in array, but not found.");

        // Check that first field is the talker and sentence id
        info("Check for talker and sentence id's.");
        assertTrue(a[0].len() == 5, "Id field not the expected length.");
        assertEqual("GP", a[0].slice(0,2), "Talker ID did not match input.");
        assertEqual("RMC", a[0].slice(2), "Sentence ID did not match input");

        // Check that last field is the checksum
        info("Check checksum included in returned array.")
        assertEqual("78", b.top(), "Check sum matches input.");
    }

    function testHasCheckSum() {
        info("Payload with no check sum check.");
        assertTrue(!GPSParser.hasCheckSum(GPS_SENTENCE_NO_CHECKSUM), "Paylaod with no check sum returned true.");
        info("Payload with check sum check.")
        assertTrue(GPSParser.hasCheckSum(GPS_SENTENCE_GSA_CHECKSUM_EMPTY), "Payload with check sum returned false.");
    }

    function testIsValid() {
        // Data with no check sum returns true
        info("Payload with no check sum returns true.");
        assertTrue(GPSParser.isValid(GPS_SENTENCE_NO_CHECKSUM), "Payload with no check sum returned false");
        // Data with valid check sum returns true
        info("Payload with valid check sum returns true.");
        assertTrue(GPSParser.isValid(GPS_SENTENCE_GSV_CHECKSUM_LG_M_PT2), "Payload with valid check sum returned false");
        // Invalid data returns false
        info("Payload with incorrect check sum returns false.");
        assertTrue(!GPSParser.isValid(GPS_CHECKSUM_INCORRECT), "Payload with invalid no check sum returned true");
    }

    function testParseLatitude() {
        local rmc = GPSParser.getFields(GPS_SENTENCE_RMC_CHECKSUM_MORE_MI);
        // rmc [3][4] 3723.71721,N
        local lat = GPSParser.parseLatitude(rmc[3], rmc[4]);
        assertEqual("37.395287", lat, "Expected value: 37.395287");
    }

    function testParseLongitude() {
        local rmc = GPSParser.getFields(GPS_SENTENCE_RMC_CHECKSUM_MORE_MI);
        // rmc [5][6] 12206.14085,W
        local lat = GPSParser.parseLongitude(rmc[5], rmc[6]);
        assertEqual("-122.102348", lat, "Expected value: -122.102348");
    }

    function testGetGPSDataTableVTG() {
        // $GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_VTG_CHECKSUM_FULL);
        info("VTG full payload has expected slots & values.");
        assertEqual("GP", data.talkerId);
        assertEqual("VTG", data.sentenceId);
        assertEqual("054.7", data.tTrack);
        assertEqual("034.4", data.mTrack);
        assertEqual("005.5", data.speedKnots);
        assertEqual("010.2", data.speedKPH);
        assertTrue(!("modeIndicator" in data));

        // $GNVTG,,T,,M,0.140,N,0.260,K,A*3C\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_VTG_CHECKSUM_EMPTY_MI);
        info("VTG partial payload has expected slots.");
        assertEqual("GN", data.talkerId);
        assertEqual("VTG", data.sentenceId);
        assertTrue(!("tTrack" in data));
        assertTrue(!("mTrack" in data));
        assertEqual("0.140", data.speedKnots);
        assertEqual("0.260", data.speedKPH);
        assertEqual("A", data.modeIndicator);

        info("VTG expected errors tests.");
        local csInvalid = GPSParser.getGPSDataTable("$GNVTG,,T,,M,0.140,N,0.260,K,A*3\r\n");
        assertEqual(GPS_PARSER_INVALID_SENTENCE_ERROR, csInvalid.error);
        local tooShort = GPSParser.getGPSDataTable("$GNVTG,T,M,0.140,N,0.260,K,A\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooShort.error);
        local tooLong = GPSParser.getGPSDataTable("$GNVTG,,T,,,,,M,0.140,N,0.260,K,A\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooLong.error);
    }

    function testGetGPSDataTableRMC() {
        // $GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_RMC_CHECKSUM_FULL);
        info("RMC full payload has expected slots & values.");
        assertEqual("GP", data.talkerId);
        assertEqual("RMC", data.sentenceId);
        assertEqual("123519", data.time);
        assertEqual("A", data.status);
        assertEqual("48.117298", data.latitude);
        assertEqual("11.516666", data.longitude);
        assertEqual("022.4", data.speedKnots);
        assertEqual("084.4", data.trackAngle);
        assertEqual("230394", data.date);
        assertEqual("003.1 W", data.mVar);
        assertTrue(!("modeIndicator" in data));

        // $GPRMC,,V,,,,,,,,,,N*53\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_RMC_CHECKSUM_EMPTY_MI);
        info("RMC empty payload has expected slots.");
        assertEqual("GP", data.talkerId);
        assertEqual("RMC", data.sentenceId);
        assertEqual("V", data.status);
        assertEqual("N", data.modeIndicator);
        assertTrue(!("time" in data));
        assertTrue(!("date" in data));
        assertTrue(!("speedKnots" in data));
        assertTrue(!("trackAngle" in data));
        assertTrue(!("latitude" in data));
        assertTrue(!("longitude" in data));
        assertTrue(!("mVar" in data));

        // $GNRMC,181859.00,A,3723.71721,N,12206.14085,W,0.140,,090518,,,A*78\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_RMC_CHECKSUM_MORE_MI);
        info("RMC partial payload has expected slots.");
        assertEqual("GN", data.talkerId);
        assertEqual("RMC", data.sentenceId);
        assertEqual("181859.00", data.time);
        assertEqual("A", data.status);
        assertEqual("37.395287", data.latitude);
        assertEqual("-122.102348", data.longitude);
        assertEqual("0.140", data.speedKnots);
        assertTrue(!("trackAngle" in data));
        assertEqual("090518", data.date);
        assertTrue(!("mVar" in data));
        assertEqual("A", data.modeIndicator);

        info("RMC expected errors tests.");
        local csInvalid = GPSParser.getGPSDataTable("$GNRMC,181859,A,3723.71721,N,12206.14085,W,0.140,,090518,,,A*78\r\n");
        assertEqual(GPS_PARSER_INVALID_SENTENCE_ERROR, csInvalid.error);
        local tooShort = GPSParser.getGPSDataTable("$GNRMC,181859.00,A,3723.71721,N,12206.14085,W,0.140,,090518,A\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooShort.error);
        local tooLong = GPSParser.getGPSDataTable("$GPRMC,,V,,,,,,,,,,,,,,N\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooLong.error);
    }

    function testGetGPSDataTableGLL() {
        // $GNGLL,3723.71722,N,12206.14081,W,181858.00,A,A*67\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);
        info("GLL full payload has expected slots & values.");
        assertEqual("GN", data.talkerId);
        assertEqual("GLL", data.sentenceId);
        assertEqual("37.395287", data.latitude);
        assertEqual("-122.102348", data.longitude);
        assertEqual("181858.00", data.time);
        assertEqual("A", data.status);
        assertEqual("A", data.modeIndicator);

        // $GPGLL,,,,,,V,N*64\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);
        info("GLL empty payload has expected slots.");
        assertEqual("GP", data.talkerId);
        assertEqual("GLL", data.sentenceId);
        assertTrue(!("latitude" in data));
        assertTrue(!("longitude" in data));
        assertTrue(!("time" in data));
        assertEqual("V", data.status);
        assertEqual("N", data.modeIndicator);

        info("GLL expected errors tests.");
        local csInvalid = GPSParser.getGPSDataTable("$GPGLL,,,,,,V,N*62\r\n");
        assertEqual(GPS_PARSER_INVALID_SENTENCE_ERROR, csInvalid.error);
        local tooShort = GPSParser.getGPSDataTable("$GPGLL,,,V,N\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooShort.error);
        local tooLong = GPSParser.getGPSDataTable("$GPGLL,,,,,,,,,,V,N\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooLong.error);
        local latErr = GPSParser.getGPSDataTable("$GNGLL,LATT,N,12206.14081,W,181858.00,A,A\r\n");
        assertEqual(GPS_PARSER_LL_PARSING_ERROR, latErr.error);
        local lngErr = GPSParser.getGPSDataTable("$GNGLL,3723.71722,N,LONG,W,181858.00,A,A\r\n");
        assertEqual(GPS_PARSER_LL_PARSING_ERROR, lngErr.error);
    }

    function testGetGPSDataTableGGA() {
        // $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GGA_CHECKSUM_FULL);
        info("GGA full payload has expected slots & values.");
        assertEqual("GP", data.talkerId);
        assertEqual("GGA", data.sentenceId);
        assertEqual("123519", data.time);
        assertEqual("48.117298", data.latitude);
        assertEqual("11.516666", data.longitude);
        assertEqual("1", data.fixQuality);
        assertEqual("08", data.numSatellites);
        assertEqual("0.9", data.HDOP);
        assertEqual("545.4", data.altitude);
        assertEqual("46.9", data.geoSeparation);
        assertTrue(!("lastDGPSUpdate" in data));
        assertTrue(!("DGPSStationID" in data));

        // $GPGGA,,,,,,0,00,99.99,,,,,,*48\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GGA_CHECKSUM_EMPTY);
        info("GGA empty payload has expected slots.");
        assertEqual("GP", data.talkerId);
        assertEqual("GGA", data.sentenceId);
        assertTrue(!("time" in data));
        assertTrue(!("latitude" in data));
        assertTrue(!("longitude" in data));
        assertEqual("0", data.fixQuality);
        assertEqual("00", data.numSatellites);
        assertEqual("99.99", data.HDOP);
        assertTrue(!("altitude" in data));
        assertTrue(!("geoSeparation" in data));
        assertTrue(!("lastDGPSUpdate" in data));
        assertTrue(!("DGPSStationID" in data));

        // $GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4C\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GGA_CHECKSUM_FULL_2);
        info("GGA full payload has expected slots & values.");
        assertEqual("GN", data.talkerId);
        assertEqual("GGA", data.sentenceId);
        assertEqual("181859.00", data.time);
        assertEqual("37.395287", data.latitude);
        assertEqual("-122.102348", data.longitude);
        assertEqual("1", data.fixQuality);
        assertEqual("12", data.numSatellites);
        assertEqual("0.97", data.HDOP);
        assertEqual("38.0", data.altitude);
        assertEqual("-30.0", data.geoSeparation);
        assertTrue(!("lastDGPSUpdate" in data));
        assertTrue(!("DGPSStationID" in data));

        info("GGA expected errors tests.");
        local csInvalid = GPSParser.getGPSDataTable("$GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4D\r\n");
        assertEqual(GPS_PARSER_INVALID_SENTENCE_ERROR, csInvalid.error);
        local tooShort = GPSParser.getGPSDataTable("$GPGGA,,,,,0,00,99.99,,,,,,\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooShort.error);
        local tooLong = GPSParser.getGPSDataTable("$GPGLL,,,,,,,,,,,,,V,N\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooLong.error);
    }

    function testGetGPSDataTableGSV() {
        // $GPGSV,2,1,08,01,40,083,46,02,17,308,41,12,07,344,39,14,22,228,45*75\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSV_CHECKSUM_FULL);
        info("GSV full payload has expected slots & values.");
        assertEqual("GP", data.talkerId);
        assertEqual("GSV", data.sentenceId);
        assertEqual("2", data.numMsgs);
        assertEqual("1", data.msgNum);
        assertEqual("08", data.numSatellites);
        local satInfo = data.satelliteInfo;
        assertEqual("array", typeof satInfo);
        assertEqual(4, satInfo.len());
        assertEqual("01", satInfo[0].satellitePRN);
        assertEqual("40", satInfo[0].elevation);
        assertEqual("083", satInfo[0].azimuth);
        assertEqual("46", satInfo[0].snr);
        assertEqual("02", satInfo[1].satellitePRN);
        assertEqual("17", satInfo[1].elevation);
        assertEqual("308", satInfo[1].azimuth);
        assertEqual("41", satInfo[1].snr);
        assertEqual("12", satInfo[2].satellitePRN);
        assertEqual("07", satInfo[2].elevation);
        assertEqual("344", satInfo[2].azimuth);
        assertEqual("39", satInfo[2].snr);
        assertEqual("14", satInfo[3].satellitePRN);
        assertEqual("22", satInfo[3].elevation);
        assertEqual("228", satInfo[3].azimuth);
        assertEqual("45", satInfo[3].snr);


        // $GPGSV,1,1,01,22,,,18*71\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSV_CHECKSUM_EMPTY);
        info("GSV partail payload has expected slots.");
        assertEqual("GP", data.talkerId);
        assertEqual("GSV", data.sentenceId);
        assertEqual("1", data.numMsgs);
        assertEqual("1", data.msgNum);
        assertEqual("01", data.numSatellites);
        local satInfo = data.satelliteInfo;
        assertEqual("array", typeof satInfo);
        assertEqual(1, satInfo.len());
        assertEqual("22", satInfo[0].satellitePRN);
        assertTrue(!("elevation" in satInfo[0]));
        assertTrue(!("azimuth" in satInfo[0]));
        assertEqual("18", satInfo[0].snr);

        info("GSV expected errors tests.");
        local csInvalid = GPSParser.getGPSDataTable("$GPGSV,1,1,01,22,,,18*72\r\n");
        assertEqual(GPS_PARSER_INVALID_SENTENCE_ERROR, csInvalid.error);
        local tooShort = GPSParser.getGPSDataTable("$GPGSV,1,1,01,22,,18\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooShort.error);
        local tooLong = GPSParser.getGPSDataTable("$GPGSV,1,1,01,22,,,,18\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooLong.error);
    }

    function testGetGPSDataTableGSA() {
        // $GPGSA,A,3,04,05,,09,12,,,24,,,,,2.5,1.3,2.1*39\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSA_CHECKSUM_SOME);
        info("GSA partial payload scattered has expected slots & values.");
        assertEqual("GP", data.talkerId);
        assertEqual("GSA", data.sentenceId);
        assertEqual("A", data.selMode);
        assertEqual("3", data.mode);
        assertEqual("2.5", data.PDOP);
        assertEqual("1.3", data.HDOP);
        assertEqual("2.1", data.VDOP);
        assertEqual("array", typeof data.satellitePRNs);
        assertEqual(5, data.satellitePRNs.len());

        // $GPGSA,A,1,,,,,,,,,,,,,99.99,99.99,99.99*30\r\n
        info("GSA empty payload has expected slots.");
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSA_CHECKSUM_EMPTY);
        assertEqual("GP", data.talkerId);
        assertEqual("GSA", data.sentenceId);
        assertEqual("A", data.selMode);
        assertEqual("1", data.mode);
        assertEqual("99.99", data.PDOP);
        assertEqual("99.99", data.HDOP);
        assertEqual("99.99", data.VDOP);
        assertEqual("array", typeof data.satellitePRNs);
        assertEqual(0, data.satellitePRNs.len());

        // $GNGSA,A,3,30,07,08,05,11,13,18,,,,,,1.45,0.97,1.08*19\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSA_CHECKSUM_MORE);
        info("GSA partial payload condensed has expected slots & values.");
        assertEqual("GN", data.talkerId);
        assertEqual("GSA", data.sentenceId);
        assertEqual("A", data.selMode);
        assertEqual("3", data.mode);
        assertEqual("1.45", data.PDOP);
        assertEqual("0.97", data.HDOP);
        assertEqual("1.08", data.VDOP);
        assertEqual("array", typeof data.satellitePRNs);
        assertEqual(7, data.satellitePRNs.len());

        info("GSA expected errors tests.");
        local csInvalid = GPSParser.getGPSDataTable("$GNGSA,A,3,30,07,08,05,11,13,18,,,,,,1.45,0.97,1.08*10\r\n");
        assertEqual(GPS_PARSER_INVALID_SENTENCE_ERROR, csInvalid.error);
        local tooShort = GPSParser.getGPSDataTable("$GPGSA,A,1,,,,,,,,,,99.99,99.99,99.99\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooShort.error);
        local tooLong = GPSParser.getGPSDataTable("$GPGSA,A,1,,,,,,,,,,,,,,99.99,99.99,99.99\r\n");
        assertEqual(GPS_PARSER_UNEXPECTED_FIELDS_ERROR, tooLong.error);
    }

    function testUnsupportedType() {
        // "$GPXTE,A,A,0.67,L,N*6F\r\n"
        local data = GPSParser.getGPSDataTable(GPS_UNSUPPORTED_TYPE);
        assertEqual(data.error, GPS_PARSER_UNSUPPORTED_TYPE);
    }

    function tearDown() {}

}

