// MIT License
// Copyright 2017-8 Electric Imp
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

const GPS_SENTENCE_GSA_CHECKSUM_SOME     = "$GPGSA,A,3,04,05,,09,12,,,24,,,,,2.5,1.3,2.1*39\r\n";
const GPS_SENTENCE_GSA_CHECKSUM_EMPTY    = "$GPGSA,A,1,,,,,,,,,,,,,99.99,99.99,99.99*30\r\n";
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
        assertTrue(typeof a == "array");
        // Array is returned for data without check sum
        assertTrue(typeof c == "array");

        // Check that empty fields are being included
        assertEqual(a.len(), b.len());
        assertEqual(a[5], "");

        // Check that first field is the talker and sentence id
        assertTrue(a[0].len() == 5);
        assertEqual(a[0].slice(0,2), "GP");
        assertEqual(a[0].slice(2), "RMC");

        // Check that last field is the checksum
        assertEqual(b, "78");
    }

    function testHasCheckSum() {
        assertTrue(!GPSParser.hasCheckSum(GPS_SENTENCE_NO_CHECKSUM));
        assertTrue(GPSParser.hasCheckSum(GPS_SENTENCE_GSA_CHECKSUM_EMPTY));
    }

    function testIsValid() {
        // // Data with no check sum returns true
        // assertTrue(GPSParser.isValid(GPS_SENTENCE_NO_CHECKSUM));
        // // Data with valid check sum returns true
        // assertTrue(GPSParser.isValid(GPS_SENTENCE_GSV_CHECKSUM_LG_M_PT2));
        // // Invalid data returns false
        // assertTrue(GPSParser.isValid(!GPS_CHECKSUM_INCORRECT));
    }

    function testParseLatitude() {
        local rmc = GPSParser.getFields(GPS_SENTENCE_RMC_CHECKSUM_MORE_MI);
        // rmc [3][4] 3723.71721,N
        local lat = GPSParser.parseLatitude(rmc[3], rmc[4]);
        assertEqual(lat, "37.395287");
    }

    function testParseLongitude() {
        local rmc = GPSParser.getFields(GPS_SENTENCE_RMC_CHECKSUM_MORE_MI);
        // rmc [5][6] 12206.14085,W
        local lat = GPSParser.parseLongitude(rmc[5], rmc[6]);
        assertEqual(lat, "-122.102348");
    }

    function testGetGPSDataTableVTG() {
        // $GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_VTG_CHECKSUM_FULL);
        assertEqual(data.talkerId, "GP");
        assertEqual(data.sentenceId, "VTG");
        assertEqual(data.tTrack, "054.7");
        assertEqual(data.mTrack, "034.4");
        assertEqual(data.speedKnots, "005.5");
        assertEqual(data.speedKPH, "010.2");
        assertTrue(!("modeIndicator" in data));

        // $GNVTG,,T,,M,0.140,N,0.260,K,A*3C\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_VTG_CHECKSUM_EMPTY_MI);
        assertEqual(data.talkerId, "GN");
        assertEqual(data.sentenceId, "VTG");
        assertTrue(!("tTrack" in data));
        assertTrue(!("mTrack" in data));
        assertEqual(data.speedKnots, "0.140");
        assertEqual(data.speedKPH, "0.260");
        assertEqual(data.modeIndicator, "A");

        local csInvalid = GPSParser.getGPSDataTable("$GNVTG,,T,,M,0.140,N,0.260,K,A*3\r\n");
        assertEqual(csInvalid.error, GPSParser_INVALID_SENTENCE_ERROR);
        local tooShort = GPSParser.getGPSDataTable("$GNVTG,T,M,0.140,N,0.260,K,A\r\n");
        assertEqual(tooShort.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
        local tooLong = GPSParser.getGPSDataTable("$GNVTG,,T,,,,,M,0.140,N,0.260,K,A\r\n");
        assertEqual(tooLong.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
    }

    function testGetGPSDataTableRMC() {
        // $GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_RMC_CHECKSUM_FULL);
        assertEqual(data.talkerId, "GP");
        assertEqual(data.sentenceId, "RMC");
        assertEqual(data.time, "123519");
        assertEqual(data.status, "A");
        assertEqual(data.latitude, "48.117298");
        assertEqual(data.longitude, "11.516666");
        assertEqual(data.speedKnots, "022.4");
        assertEqual(data.trackAngle, "084.4");
        assertEqual(data.date, "230394");
        assertEqual(data.mVar, "003.1 W");
        assertTrue(!("modeIndicator" in data));

        // $GPRMC,,V,,,,,,,,,,N*53\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_RMC_CHECKSUM_EMPTY_MI);
        assertEqual(data.talkerId, "GN");
        assertEqual(data.sentenceId, "RMC");
        assertEqual(status, "V");
        assertEqual(data.modeIndicator, "N");
        assertTrue(!("time" in data));
        assertTrue(!("date" in data));
        assertTrue(!("speedKnots" in data));
        assertTrue(!("trackAngle" in data));
        assertTrue(!("latitude" in data));
        assertTrue(!("longitude" in data));
        assertTrue(!("mVar" in data));

        // $GNRMC,181859.00,A,3723.71721,N,12206.14085,W,0.140,,090518,,,A*78\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_RMC_CHECKSUM_MORE_MI);
        assertEqual(data.talkerId, "GN");
        assertEqual(data.sentenceId, "RMC");
        assertEqual(data.time, "181859.00");
        assertEqual(data.status, "A");
        assertEqual(data.latitude, "37.395287");
        assertEqual(data.longitude, "-122.102348");
        assertEqual(data.speedKnots, "0.140");
        assertTrue(!("trackAngle" in data));
        assertEqual(data.date, "090518");
        assertTrue(!("mVar" in data));
        assertEqual(data.modeIndicator, "A");

        local csInvalid = GPSParser.getGPSDataTable("$GNRMC,181859,A,3723.71721,N,12206.14085,W,0.140,,090518,,,A*78\r\n");
        assertEqual(csInvalid.error, GPSParser_INVALID_SENTENCE_ERROR);
        local tooShort = GPSParser.getGPSDataTable("$GNRMC,181859.00,A,3723.71721,N,12206.14085,W,0.140,,090518,A\r\n");
        assertEqual(csInvalid.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
        local tooLong = GPSParser.getGPSDataTable("$GPRMC,,V,,,,,,,,,,,,,,N\r\n");
        assertEqual(csInvalid.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
    }

    function testGetGPSDataTableGLL() {
        // $GNGLL,3723.71722,N,12206.14081,W,181858.00,A,A*67\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GLL_CHECKSUM_FULL_MI);
        assertEqual(data.talkerId, "GN");
        assertEqual(data.sentenceId, "GLL");
        assertEqual(data.latitude, "37.395287");
        assertEqual(data.longitude, "-122.102348");
        assertEqual(data.time, "181858.00");
        assertEqual(data.status, "A");
        assertEqual(data.modeIndicator, "A");

        // $GPGLL,,,,,,V,N*64\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GLL_CHECKSUM_EMPTY_MI);
        assertEqual(data.talkerId, "GP");
        assertEqual(data.sentenceId, "GLL");
        assertTrue(!("latitude" in data));
        assertTrue(!("longitude" in data));
        assertTrue(!("time" in data));
        assertEqual(data.status, "V");
        assertEqual(data.modeIndicator, "N");

        local csInvalid = GPSParser.getGPSDataTable("$GPGLL,,,,,,V,N*62\r\n");
        assertEqual(csInvalid.error, GPSParser_INVALID_SENTENCE_ERROR);
        local tooShort = GPSParser.getGPSDataTable("$GPGLL,,,V,N\r\n");
        assertEqual(tooShort.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
        local tooLong = GPSParser.getGPSDataTable("$GPGLL,,,,,,,,,,V,N\r\n");
        assertEqual(tooLong.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
        local latErr = GPSParser.getGPSDataTable("$GNGLL,3723.71U22,N,12206.14081,W,181858.00,A,A*67\r\n");
        assertEqual(latErr.error, GPSParser_LL_PARSING_ERROR);
        local lngErr = GPSParser.getGPSDataTable("$GNGLL,3723.71722,N,122Z6.14081,W,181858.00,A,A*67\r\n");
        assertEqual(lngErr.error, GPSParser_LL_PARSING_ERROR);
    }

    function testGetGPSDataTableGGA() {
        // $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GGA_CHECKSUM_FULL);
        assertEqual(data.talkerId, "GP");
        assertEqual(data.sentenceId, "GGA");
        assertEqual(data.time, "123519");
        assertEqual(data.latitude, "48.117298");
        assertEqual(data.longitude, "11.516666");
        assertEqual(data.fixQuality, "1");
        assertEqual(data.numSatellites, "08");
        assertEqual(data.HDOP, "0.9");
        assertEqual(data.altitude, "545.4");
        assertEqual(data.geoSeparation, "46.9");
        assertTrue(!("lastDGPSUpdate" in data));
        assertTrue(!("DGPSStationID" in data));

        // $GPGGA,,,,,,0,00,99.99,,,,,,*48\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GGA_CHECKSUM_EMPTY);
        assertEqual(data.talkerId, "GP");
        assertEqual(data.sentenceId, "GGA");
        assertTrue(!("time" in data));
        assertTrue(!("latitude" in data));
        assertTrue(!("longitude" in data));
        assertEqual(data.fixQuality, "0");
        assertEqual(data.numSatellites, "00");
        assertEqual(data.HDOP, "99.99");
        assertTrue(!("altitude" in data));
        assertTrue(!("geoSeparation" in data));
        assertTrue(!("lastDGPSUpdate" in data));
        assertTrue(!("DGPSStationID" in data));

        // $GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4C\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GGA_CHECKSUM_FULL_2);
        assertEqual(data.talkerId, "GN");
        assertEqual(data.sentenceId, "GGA");
        assertEqual(data.time, "181859.00");
        assertEqual(data.latitude, "37.395287");
        assertEqual(data.longitude, "-122.102348");
        assertEqual(data.fixQuality, "1");
        assertEqual(data.numSatellites, "12");
        assertEqual(data.HDOP, "0.97");
        assertEqual(data.altitude, "38.0");
        assertEqual(data.geoSeparation, "-30.0");
        assertTrue(!("lastDGPSUpdate" in data));
        assertTrue(!("DGPSStationID" in data));

        local csInvalid = GPSParser.getGPSDataTable("$GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4D\r\n");
        assertEqual(csInvalid.error, GPSParser_INVALID_SENTENCE_ERROR);
        local tooShort = GPSParser.getGPSDataTable("$GPGGA,,,,,0,00,99.99,,,,,,\r\n");
        assertEqual(tooShort.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
        local tooLong = GPSParser.getGPSDataTable("$GPGLL,,,,,,,,,,,,,V,N\r\n");
        assertEqual(tooLong.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
    }

    function testGetGPSDataTableGSV() {
        // $GPGSV,2,1,08,01,40,083,46,02,17,308,41,12,07,344,39,14,22,228,45*75\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSV_CHECKSUM_FULL);
        assertEqual(data.talkerId, "GP");
        assertEqual(data.sentenceId, "GSV");
        assertEqual(data.numMsgs, "2");
        assertEqual(data.msgNum, "1");
        assertEqual(data.numSatellites, "08");
        local satInfo = data.satelliteInfo;
        assertEqual(typeof satInfo, "array");
        assertEqual(satInfo.len(), 4);
        assertEqual(satInfo[0].satellitePRN, "01");
        assertEqual(satInfo[0].elevation, "40");
        assertEqual(satInfo[0].azimuth, "083");
        assertEqual(satInfo[0].snr, "46");
        assertEqual(satInfo[1].satellitePRN, "02");
        assertEqual(satInfo[1].elevation, "17");
        assertEqual(satInfo[1].azimuth, "308");
        assertEqual(satInfo[1].snr, "41");
        assertEqual(satInfo[2].satellitePRN, "12");
        assertEqual(satInfo[2].elevation, "07");
        assertEqual(satInfo[2].azimuth, "344");
        assertEqual(satInfo[2].snr, "39");
        assertEqual(satInfo[3].satellitePRN, "14");
        assertEqual(satInfo[3].elevation, "22");
        assertEqual(satInfo[3].azimuth, "228");
        assertEqual(satInfo[3].snr, "45");


        // $GPGSV,1,1,01,22,,,18*71\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSV_CHECKSUM_EMPTY);
        assertEqual(data.talkerId, "GP");
        assertEqual(data.sentenceId, "GSV");
        assertEqual(data.numMsgs, "1");
        assertEqual(data.msgNum, "1");
        assertEqual(data.numSatellites, "01");
        local satInfo = data.satelliteInfo;
        assertEqual(typeof satInfo, "array");
        assertEqual(satInfo.len(), 1);
        assertEqual(satInfo[0].satellitePRN, "22");
        assertTrue(!("elevation" in satInfo[0]));
        assertTrue(!("azimuth" in satInfo[0]));
        assertEqual(satInfo[0].snr, "18");

        local csInvalid = GPSParser.getGPSDataTable("$GPGSV,1,1,01,22,,,18*72\r\n");
        assertEqual(csInvalid.error, GPSParser_INVALID_SENTENCE_ERROR);
        local tooShort = GPSParser.getGPSDataTable("$GPGSV,1,1,01,22,,18*71\r\n");
        assertEqual(tooShort.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
        local tooLong = GPSParser.getGPSDataTable("$GPGSV,1,1,01,22,,,,18*71\r\n");
        assertEqual(tooLong.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
    }

    function testGetGPSDataTableGSA() {
        // $GPGSA,A,3,04,05,,09,12,,,24,,,,,2.5,1.3,2.1*39\r\n
        local data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSA_CHECKSUM_SOME);
        assertEqual(data.talkerId, "GP");
        assertEqual(data.sentenceId, "GSA");
        assertEqual(data.selMode, "A");
        assertEqual(data.mode, "3");
        assertEqual(data.PDOP, "2.5");
        assertEqual(data.HDOP, "1.3");
        assertEqual(data.VDOP, "2.1");
        assertEqual(typeof data.satellitePRNs, "array");
        assertEqual(data.satellitePRNs.len(), 5);

        // $GPGSA,A,1,,,,,,,,,,,,,99.99,99.99,99.99*30\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSA_CHECKSUM_EMPTY);
        assertEqual(data.talkerId, "GP");
        assertEqual(data.sentenceId, "GSA");
        assertEqual(data.selMode, "A");
        assertEqual(data.mode, "1");
        assertEqual(data.PDOP, "99.99");
        assertEqual(data.HDOP, "99.99");
        assertEqual(data.VDOP, "99.99");
        assertEqual(typeof data.satellitePRNs, "array");
        assertEqual(data.satellitePRNs.len(), 0);

        // $GNGSA,A,3,30,07,08,05,11,13,18,,,,,,1.45,0.97,1.08*19\r\n
        data = GPSParser.getGPSDataTable(GPS_SENTENCE_GSA_CHECKSUM_MORE);
        assertEqual(data.talkerId, "GN");
        assertEqual(data.sentenceId, "GSA");
        assertEqual(data.selMode, "A");
        assertEqual(data.mode, "3");
        assertEqual(data.PDOP, "1.45");
        assertEqual(data.HDOP, "0.97");
        assertEqual(data.VDOP, "1.08");
        assertEqual(typeof data.satellitePRNs, "array");
        assertEqual(data.satellitePRNs.len(), 7);

        local csInvalid = GPSParser.getGPSDataTable("$GNGSA,A,3,30,07,08,05,11,13,18,,,,,,1.45,0.97,1.08*10\r\n");
        assertEqual(csInvalid.error, GPSParser_INVALID_SENTENCE_ERROR);
        local tooShort = GPSParser.getGPSDataTable("$GPGSA,A,1,,,,,,,,,,99.99,99.99,99.99*30\r\n");
        assertEqual(tooShort.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
        local tooLong = GPSParser.getGPSDataTable("$GPGSA,A,1,,,,,,,,,,,,,,99.99,99.99,99.99*30\r\n");
        assertEqual(tooLong.error, GPSParser_UNEXPECTED_FIELDS_ERROR);
    }

    function testUnsupportedType() {
        // "$GPXTE,A,A,0.67,L,N*6F\r\n"
        local data = GPSParser.getGPSDataTable(GPS_UNSUPPORTED_TYPE);
        assertEqual(data.error, GPSParser_UNSUPPORTED_TYPE);
    }

    function tearDown() {}

}

