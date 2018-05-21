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

// GPS Sentence Identifier
const GPS_PARSER_VTG = "VTG";
const GPS_PARSER_RMC = "RMC";
const GPS_PARSER_GLL = "GLL";
const GPS_PARSER_GGA = "GGA";
const GPS_PARSER_GSV = "GSV";
const GPS_PARSER_GSA = "GSA";

// GPS Parser errors
const GPS_PARSER_UNEXPECTED_FIELDS_ERROR = "Unexpected number of fields found.";
const GPS_PARSER_INVALID_SENTENCE_ERROR  = "Check sum not valid.";
const GPS_PARSER_UNSUPPORTED_TYPE        = "Sentence Id not supported.";
const GPS_PARSER_LL_PARSING_ERROR        = "Error parsing Latitude/Longitude field.";

// GPSParser:
// All data is transmitted in the form of sentences. Only printable ASCII characters
// are allowed, plus CR (carriage return) and LF (line feed). Each sentence starts
// with a "$" sign and ends with CRLF. There are three basic kinds of sentences:
// talker sentences, proprietary sentences and query sentences.
// The first two letters following the „$” are the talker identifier. The next three
// characters (sss) are the sentence identifier, followed by a number of data fields
// separated by commas, followed by an optional checksum, and terminated by carriage
// return/line feed. The data fields are uniquely defined for each sentence type.
class GPSParser {

    static VERSION = "1.0.0";

    // Takes raw GPS sentence, Returns an array of data fields.
    // First field will be a string $ + talker identifier + sentence identifier.
    // If sentence included a check sum the last field will be the check sum
    // formatted as a hex string.
    // All other fields are either data formatted as a sting or an empty string
    // if the value was blank
    // Reference: http://www.gpsinformation.org/dale/nmea.htm
    function getFields(sentence) {
        local field = "";
        local fields = [];
        local sentenceData = _trimSentence(sentence);

        // Capture all fields, even if field is an empty string
        foreach (char in sentenceData) {
            if (char == ',' || char == '*') {
                fields.push(field);
                field = "";
            } else {
                field += char.tochar();
            }
        }
        if (field.len() > 0) {
            fields.push(field);
        }

        // Return array of fields
        return fields;
    }

    // Takes raw GPS sentence, Returns boolean
    function hasCheckSum(sentence) {
        return (sentence.find("*") != null);
    }

    // Takes raw GPS sentence, Returns boolean if check sum in payload matches
    // the calculated check sum.
    // Note: This function will return true if payload doesn't contain check sum
    function isValid(sentence) {
        local idx = sentence.find("*");
        if (idx != null) {
            local checkSum = sentence.slice(idx + 1);
            checkSum = strip(checkSum);
            return (_hexToDec(checkSum) == _calcCheckSum(sentence));
        }
        // Check sum is not in payload, so we cannot validate
        return true;
    }

    // Takes raw GPS sentence, returns a table of parsed GPS data
    // Currently supported Sentence IDs are VTG, RMC, GLL, GGA, GSV and GSA
    // If data field is empty the key will not be included in the returned table
    function getGPSDataTable(sentence) {
        // Parse sentence into fields
        local fields = getFields(sentence);

        // Check that fields array has expected content
        if (fields == null || fields.len() == 0 || fields[0].len() != 5) return;

        local data  = {};
        local hasCS = hasCheckSum(sentence);

        // Extract Talker ID and Sentence ID
        data.talkerId   <- fields[0].slice(0, 2);
        data.sentenceId <- fields[0].slice(2);

        if (!isValid(sentence)) {
            data.error <- GPS_PARSER_INVALID_SENTENCE_ERROR;
            return data;
        }

        switch(data.sentenceId) {
            case GPS_PARSER_VTG:
                // Velocity made good
                // $GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48
                // $GNVTG,,T,,M,0.140,N,0.260,K,A*3C
                local dataLen = _getDataLength(hasCS, fields.len());
                // Expected length (excluding check sum): 9 or 10
                if (dataLen == 9 || dataLen == 10) {
                    if (fields[1] != "") data.tTrack     <- fields[1]; // 054.7
                    if (fields[3] != "") data.mTrack     <- fields[3]; // 034.4
                    if (fields[5] != "") data.speedKnots <- fields[5]; // 005.5
                    if (fields[7] != "") data.speedKPH   <- fields[7]; // 010.2

                    // A=autonomous, D=differential, E=Estimated, N=not valid, S=Simulator
                    if (dataLen == 10 && fields[9] != "") data.modeIndicator <- fields[9];
                } else {
                    data.error <- GPS_PARSER_UNEXPECTED_FIELDS_ERROR;
                }
                break;
            case GPS_PARSER_RMC:
                // Recommended Minimum sentence C
                // $GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A
                // $GPRMC,,V,,,,,,,,,,N*53
                // $GNRMC,181859.00,A,3723.71721,N,12206.14085,W,0.140,,090518,,,A*78
                local dataLen = _getDataLength(hasCS, fields.len());
                // Expected length (excluding check sum): 12 or 13
                if (dataLen == 12 || dataLen == 13) {
                    if (fields[1] != "") data.time       <- fields[1]; // 123519 (12:35:19 UTC)
                    if (fields[9] != "") data.date       <- fields[9]; // 230394 (23rd of March 1994)
                    if (fields[2] != "") data.status     <- fields[2]; // Status A=active or V=Void
                    if (fields[7] != "") data.speedKnots <- fields[7]; // 022.4
                    if (fields[8] != "") data.trackAngle <- fields[8]; // 084.4
                    if (fields[10] != "" && fields[11] != "") data.mVar <- format("%s %s", fields[10], fields[11]); // 003.1 W
                    if (fields[3]  != "" && fields[4]  != "") {
                        // 4807.038  N
                        local lat = parseLatitude(fields[3], fields[4]);
                        (lat == null) ? data.error <- GPS_PARSER_LL_PARSING_ERROR : data.latitude <- lat;
                    }
                    if (fields[5]  != "" && fields[6]  != "") {
                        // 01131.000 E
                        local lng = parseLongitude(fields[5], fields[6]);
                        (lng == null) ? data.error <- GPS_PARSER_LL_PARSING_ERROR : data.longitude <- lng;
                    }
                    // A=autonomous, D=differential, E=Estimated, N=not valid, S=Simulator
                    if (dataLen == 13 && fields[12] != "") data.modeIndicator <- fields[12];
                } else {
                    data.error <- GPS_PARSER_UNEXPECTED_FIELDS_ERROR;
                }
                break;
            case GPS_PARSER_GLL:
                // Geographic position, Latitude and Longitude
                // $GPGLL,4916.45,N,12311.12,W,225444,A,*1D
                // $GPGLL,,,,,,V,N*64
                // $GNGLL,3723.71722,N,12206.14081,W,181858.00,A,A*67
                local dataLen = _getDataLength(hasCS, fields.len());
                // Expected length (excluding check sum): 7 or 8
                if (dataLen == 7 || dataLen == 8) {
                    if (fields[5] != "")  data.time   <- fields[5]; // 225444 22:54:44 UTC
                    if (fields[6] != "")  data.status <- fields[6]; // Status A=active or V=Void
                    if (fields[1] != "" && fields[2] != "") {
                        // 4807.038  N
                        local lat = parseLatitude(fields[1], fields[2]);
                        (lat == null) ? data.error <- GPS_PARSER_LL_PARSING_ERROR : data.latitude <- lat;
                    }
                    if (fields[3] != "" && fields[4] != "") {
                        // 01131.000 E
                        local lng = parseLongitude(fields[3], fields[4]);
                        (lng == null) ? data.error <- GPS_PARSER_LL_PARSING_ERROR : data.longitude <- lng;
                    }
                    // A=autonomous, D=differential, E=Estimated, N=not valid, S=Simulator
                    if (dataLen == 8 && fields[7] != "") data.modeIndicator <- fields[7];
                } else {
                    data.error <- GPS_PARSER_UNEXPECTED_FIELDS_ERROR;
                }
                break;
            case GPS_PARSER_GGA:
                // Global Positioning System Fix Data
                // $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
                // $GPGGA,,,,,,0,00,99.99,,,,,,*48
                // $GNGGA,181859.00,3723.71721,N,12206.14085,W,1,12,0.97,38.0,M,-30.0,M,,*4C
                local dataLen = _getDataLength(hasCS, fields.len());
                // Expected length (excluding check sum): 15
                if (dataLen == 15) {
                    if (fields[1] != "") data.time            <- fields[1]; // 123519 (12:35:19 UTC)
                    if (fields[6] != "") data.fixQuality      <- fields[6]; // 0-8, 0 = invalid, 1 = GPS fix (SPS), 2 = DGPS fix, 3 = PPS fix, 4 = Real Time Kinematic, 5 = Float RTK, 6 = estimated (dead reckoning) (2.3 feature), 7 = Manual input mode, 8 = Simulation mode
                    if (fields[7] != "") data.numSatellites   <- fields[7]; // 08
                    if (fields[8] != "") data.HDOP            <- fields[8]; // 0.9
                    if (fields[9] != "") data.altitude        <- fields[9]; // 545.4 (in Meters)
                    if (fields[11] != "") data.geoSeparation  <- fields[11]; // 46.9 (in Meters)
                    if (fields[13] != "") data.lastDGPSUpdate <- fields[13]; // x.x (in Seconds)
                    if (fields[14] != "") data.DGPSStationID  <- fields[14]; // xxxx
                    if (fields[2] != "" && fields[3] != "") {
                        // 4807.038  N
                        local lat = parseLatitude(fields[2], fields[3]);
                        (lat == null) ? data.error <- GPS_PARSER_LL_PARSING_ERROR : data.latitude <- lat;
                    }
                    if (fields[4] != "" && fields[5] != "") {
                        // 01131.000 E
                        local lng = parseLongitude(fields[4], fields[5]);
                        (lng == null) ? data.error <- GPS_PARSER_LL_PARSING_ERROR : data.longitude <- lng;
                    }
                } else {
                    data.error <- GPS_PARSER_UNEXPECTED_FIELDS_ERROR;
                }
                break;
            case GPS_PARSER_GSV:
                // Satellites in view
                // $GPGSV,2,1,08,01,40,083,46,02,17,308,41,12,07,344,39,14,22,228,45*75
                // $GPGSV,1,1,01,22,,,18*71
                // $GPGSV,3,1,11,01,02,114,,05,16,266,23,07,56,075,35,08,30,051,36*77
                // $GPGSV,3,2,11,09,25,160,20,11,24,105,16,13,27,316,25,17,16,186,*7C
                // $GPGSV,3,3,11,18,06,092,27,28,71,272,17,30,71,012,37*47
                // $GLGSV,3,1,09,70,38,293,,71,08,336,13,73,01,274,,78,09,074,30*62
                // $GLGSV,3,2,09,79,41,044,32,80,42,310,26,81,38,086,37,82,23,143,21*69
                // $GLGSV,3,3,09,88,18,034,28*58
                local dataLen = _getDataLength(hasCS, fields.len());
                // We have at least one full message and complete satellite info
                if (dataLen > 7 && (dataLen % 4) == 0) {
                    data.numMsgs       <- fields[1];
                    data.msgNum        <- fields[2];
                    data.numSatellites <- fields[3];
                    data.satelliteInfo <- [];
                    for (local i = 1; i < dataLen / 4; i++) {
                        local info = {};
                        local startingIdx = 4 * i;
                        if (fields[startingIdx] != "")   info.satellitePRN <- fields[startingIdx];
                        if (fields[startingIdx+1] != "") info.elevation    <- fields[startingIdx+1];
                        if (fields[startingIdx+2] != "") info.azimuth      <- fields[startingIdx+2];
                        if (fields[startingIdx+3] != "") info.snr          <- fields[startingIdx+3];
                        data.satelliteInfo.push(info);
                    }
                } else {
                    data.error <- GPS_PARSER_UNEXPECTED_FIELDS_ERROR;
                }
                break;
            case GPS_PARSER_GSA:
                // GPS DOP and active satellites
                // $GPGSA,A,3,04,05,,09,12,,,24,,,,,2.5,1.3,2.1*39
                // $GPGSA,A,1,,,,,,,,,,,,,99.99,99.99,99.99*30
                // $GNGSA,A,3,30,07,08,05,11,13,18,,,,,,1.45,0.97,1.08*19
                local dataLen = _getDataLength(hasCS, fields.len());
                // Expected length (excluding check sum): 18
                if (dataLen == 18) {
                    if (fields[1] != "")  data.selMode <- fields[1];  // "A" auto, "M" manual
                    if (fields[2] != "")  data.mode    <- fields[2];  // 1 - no fix, 2 - 2D fix, 3 - 3D fix
                    if (fields[15] != "") data.PDOP    <- fields[15]; // 2.5
                    if (fields[16] != "") data.HDOP    <- fields[16]; // 1.3
                    if (fields[17] != "") data.VDOP    <- fields[17]; // 2.1
                    // Add satellite PRNs
                    data.satellitePRNs <- [];
                    for (local i = 3; i < 15; i++) {
                        if (fields[i] != "") data.satellitePRNs.push(fields[i]);
                    }
                } else {
                    data.error <- GPS_PARSER_UNEXPECTED_FIELDS_ERROR;
                }
                break;
            default:
                data.error <- GPS_PARSER_UNSUPPORTED_TYPE;
        }
        return data;
    }

    // Takes the 2 latitude fields, the numeric string and direction letter,
    // Returns the latitude in decimal degrees as a string
    function parseLatitude(rawLat, dir) {
        if (rawLat.len() > 2) {
            local sign = (dir == "S") ? -1 : 1;
            local lat = _convertLLToDecDeg(rawLat.slice(0, 2), rawLat.slice(2), sign);
            return (typeof lat == "float") ? format("%f", lat) : null;
        }
        return null;
    }

    // Takes the 2 longitude fields, the numeric string and direction letter,
    // Returns the longitude in decimal degrees as a string
    function parseLongitude(rawLgn, dir) {
        if (rawLgn.len() > 3) {
            local sign = (dir == "W") ? -1 : 1;
            local lgn = _convertLLToDecDeg(rawLgn.slice(0, 3), rawLgn.slice(3), sign);
            return (typeof lgn == "float") ? format("%f", lgn) : null;
        }
        return null;
    }

    // Conversion of degrees and decimal minutes and direction to signed float
    function _convertLLToDecDeg(deg, min, sign) {
        try {
            return sign * (deg.tointeger() + (min.tofloat() / 60));
        } catch(e) {
            return e;
        }
    }

    // Takes raw GPS sentence, Returns string with the starting "$"
    // and ending carriage return/line feed removed
    function _trimSentence(sentence) {
        if (sentence.find("$") == 0) sentence = sentence.slice(1);
        return strip(sentence);
    }

    // Takes boolean if hasCheckSum and length of fields array,
    // Returns length without check sum
    function _getDataLength(hasCS, fieldsLength) {
        return (hasCS) ? fieldsLength - 1 : fieldsLength;
    }

    // Used to determine the validity of the data
    // Takes raw GPS sentence, Returns integer check sum for the sentence
    // Or null if the sentence has no check sum value
    function _calcCheckSum(sentence) {
        if (!hasCheckSum(sentence)) return;
        local check = 0;
        local index = 0;
        // Trim beginning and trailing chars from sentence if needed
        sentence = _trimSentence(sentence);
        while(index < sentence.len() && sentence[index] != '*') {
            check = check ^ (sentence[index++]);
        }
        return check;
    }

    // For converting the hex string checkSum provided by satellite
    // data to an integer
    function _hexToDec(hex) {
        local i = 0;
        foreach(c in hex) {
            local n = c - '0';
            if (n > 9) n = ((n & 0x1F) -7);
            i = (i << 4) + n;
        }
        return i;
    }

}