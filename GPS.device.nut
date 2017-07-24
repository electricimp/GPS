const GPS_RMC = "GPRMC";
const GPS_GGA = "GPGGA";
const GPS_VTG = "GPVTG";
const GPS_GLL = "GPGLL";
const GPS_GSV = "GPGSV";
const GPS_GSA = "GPGSA";

class GPSFields {

    my_fields = [];
    p_sentence = null;

    function setSentence(sentence) {
        p_sentence = sentence;
    }
    
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
    function parseFields() {
        local str = "";
        my_fields = [];
        foreach(i in p_sentence) {
            if(i == ',' || i == '*') {
                my_fields.push(str);
                str = "";
            }
            else {
                str+=i.tochar();
            }
        }
        if(str.len() > 0) {
            my_fields.push(str);
        }
    }
    
    // Extract data into a table
    function extractData() {
        local retTable = {};
        if(my_fields != null && my_fields.len() > 0) {
            switch(my_fields[0]) {
                // Velocity made good
                case GPS_VTG:
                    retTable.type <- GPS_VTG;
                    if(my_fields[1] != "") {
                        retTable.trackt <- my_fields[1];
                    }
                    if(my_fields[7] != "") {
                        retTable.speedkmh <- my_fields[7];
                    }
                    
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // Recommended Minimum
                case GPS_RMC:
                    retTable.type <- GPS_RMC;
                    local lat = my_fields[3];
                    if(lat.len() <= 1) break; // no data

                    _extractTime(my_fields[1], retTable);

                    _extractLat(lat, retTable, my_fields[4]);

                    _extractLong(my_fields[5], retTable, my_fields[6]);
                    
                    retTable.status <- (my_fields[2] == "A" ? "Active" : "Void");
                    
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // Geographic Latitude and Longitude
                case GPS_GLL:
                    retTable.type <- GPS_GLL;
                    local lat = my_fields[1];
                    if(lat.len() <= 1) break;
                    
                    _extractLat(lat, retTable, my_fields[2]);
                    
                    _extractLong(my_fields[3], retTable, my_fields[4]);

                    _extractTime(my_fields[5], retTable);
                    
                    retTable.status <- (my_fields[6] == "A" ? "Active" : "Void");
                    
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // Essential Fix data
                case GPS_GGA:
                    retTable.type <- GPS_GGA;
                    local lat = my_fields[2];
                    if(lat.len() <= 1) break; // no data
                    
                    _extractTime(my_fields[1], retTable);
                    
                    _extractLat(lat, retTable, my_fields[3]);

                    _extractLong(my_fields[4], retTable, my_fields[5]);
                    
                    retTable.status <- "Active";
                    retTable.fixQuality <- my_fields[6];
                    retTable.numSatellites <- my_fields[7];
                    retTable.altitude <- my_fields[9].tofloat();
                    
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // Satellites in view
                case GPS_GSV:
                    retTable.type <- GPS_GSV;
                    retTable.numSatellites <- my_fields[3];
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                // GPS DOP and active satellites
                case GPS_GSA:
                    retTable.type <- GPS_GSA;
                    retTable.threeDFix <- my_fields[2];
                    local len = my_fields.len();
                    // need to use the len b/c we don't know the number of satellite PRNs
                    retTable.PDOP <- my_fields[len-4];
                    retTable.HDOP <- my_fields[len-3];
                    retTable.VDOP <- my_fields[len-2];
                    
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
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
    
    _gps_line = "";
    gps_counter = 0;
    gps_rate = 30;
    _fields = null;
    _gps = null;
    _last_table = null;
    _cb = null;
    _lastLat = 0;
    _lastLong = 0;
    _isValid = false;
    _numSatellites = 0;
    _fix = false;
    _fixCallback = null;
    _noFixCallback = null;

    static LINE_MAX = 150;
    
    constructor(uart, baudrate=9600, cb=null, fixCallback=null, noFixCallback=null) {
        _gps = uart;
        _fields = GPSFields();
        // GPS is configured by the constructor so that we can register
        // the rxdata callback
        _gps.configure(baudrate, 8, PARITY_NONE, 1, NO_CTSRTS, _gps_rxdata.bindenv(this));
        _cb = cb;
        _fixCallback = fixCallback;
        _noFixCallback = noFixCallback;
    }
    
    // This private method is the uart callback. It continues to append characters
    // to a line until it reaches a '$', indicating the start of a new line. Once it reaches this,
    // it parses the previous line and calls callbacks (if provided), as well as setting
    // values in the class that can be accessed (e.g. lat and long)
    function _gps_rxdata() {
        local ch = _gps.read()
        if(ch  == '$') {
            _fields.setSentence(_gps_line);
            _fields.parseFields();
            _last_table = _fields.extractData();
            _gps_line = ""; // Reset the string after a full line has been
            // collected
            _isValid = ("checkSum" in _last_table && (_last_table.checkSum ==_fields.calcCheckSum(_gps_line)));
            
            // This callback should be prepared to handle all supported satellite data
            // types
            if(_cb != null) {
                _cb(_last_table);
            }

            _setLastLatLong(_last_table);
            _setNumSatellites(_last_table);
            
            if(_last_table.len() && _last_table.type == GPS_GGA) {
                _fix = (_last_table.fixQuality.tointeger() > 0);
                if(_fix) {
                    // This callback should be prepared to handle a GGA table
                    _fixCallback(_last_table);
                }
                else {
                    // This callback takes no parameters, called when there is no fix
                    _noFixCallback();
                }
            }
        }
        else if(_gps_line.len() > LINE_MAX) {
            _gps_line = "";
        }
        else {
            _gps_line += ch.tochar();
        }
    }
    // This method should take the table of data as an argument
    function setCallBack(cb) {
        _cb = cb;
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