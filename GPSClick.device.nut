const RMC = "GPRMC";
const GGA = "GPGGA";
const VTG = "GPVTG";
const GLL = "GPGLL"

class Fields {
    my_fields = [];
    p_sentence = null;
    p_next = null;
    num_fields = 0;

    function setSentence(sentence) {
        p_sentence = sentence;
    }
    
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
    
    function parse_fields() {
        local str = "";
        my_fields = [];
        foreach(i in p_sentence) {
            if(i == ',') {
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
    
    function printFields() {
        if(my_fields != null && my_fields.len() > 0) {
            server.log(my_fields[0]);
    }
    }
    
    function extractData() {
        local retTable = {};
        if(my_fields != null && my_fields.len() > 0) {
            switch(my_fields[0]) {
                case VTG:
                    retTable.type <- VTG;
                    if(my_fields[1] != "") {
                        retTable.trackt <- my_fields[1];
                    }
                    if(my_fields[7] != "") {
                        retTable.speedkmh <- my_fields[7];
                    }
                    
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
                    break;

                case RMC:
                    retTable.type <- RMC;
                    local lat = my_fields[3];
                    if(lat.len() <= 1) break; // no data
                    local time = my_fields[1].tointeger();
                    
                    retTable.seconds <- time%100;
                    time = time/100;
                    retTable.minutes <- time%100;
                    time = time/100;
                    retTable.hours <- time; 
                    
                    retTable.status <- (my_fields[2] == "A" ? "Active" : "Void");
                    
                    local latitude = lat.slice(0, 2).tofloat() + 
                    lat.slice(2).tofloat()/60;
                    if(my_fields[4] == "S") latitude = -latitude;
                    retTable.latitude <- latitude;
                    
                    local long = my_fields[5];
                    local longitude = long.slice(0, 3).tofloat() + 
                    long.slice(3).tofloat()/60;
                    if(my_fields[6] == "W") longitude = -longitude;
                    retTable.longitude <- longitude;
                    
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                case GLL:
                    retTable.type <- GLL;
                    local lat = my_fields[1];
                    if(lat.len() <= 1) break;
                    
                    local latitude = lat.slice(0, 2).tofloat() +
                    lat.slice(2).tofloat()/60;
                    if(my_fields[2] == "S") latitude = -latitude;
                    retTable.latitude <- latitude;
                    
                    local long = my_fields[3];
                    local longitude = long.slice(0, 3).tofloat() + 
                    long.slice(3).tofloat()/60;
                    if(my_fields[4] == "W") longitude = -longitude;
                    retTable.longitude <- longitude;
                    
                    local time = my_fields[5].tointeger();
                    retTable.seconds <- time%100;
                    time = time/100;
                    retTable.minutes <- time%100;
                    time = time/100;
                    retTable.hours <- time; 
                    
                    retTable.status <- (my_fields[6] == "A" ? "Active" : "Void");
                    
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
                case GGA:
                    retTable.type <- GGA;
                    local lat = my_fields[2];
                    if(lat.len() <= 1) break; // no data
                    local time = my_fields[1].tointeger();
                    
                    retTable.seconds <- time%100;
                    time = time/100;
                    retTable.minutes <- time%100;
                    time = time/100;
                    retTable.hours <- time; 
                    
                    local latitude = lat.slice(0, 2).tofloat() + 
                    lat.slice(2).tofloat()/60;
                    if(my_fields[3] == "S") latitude = -latitude;
                    retTable.latitude <- latitude;
                    
                    local long = my_fields[4];
                    local longitude = long.slice(0, 3).tofloat() + 
                    long.slice(3).tofloat()/60;
                    if(my_fields[5] == "W") longitude = -longitude;
                    retTable.longitude <- longitude;
                    
                    retTable.status <- "Active";
                    retTable.fixQuality <- my_fields[6];
                    retTable.numSatellites <- my_fields[7];
                    retTable.altitude <- my_fields[9].tofloat();
                    
                    local checkLen = my_fields[my_fields.len() - 1].len();
                    retTable.checkSum <- my_fields[my_fields.len()-1].slice(checkLen-4, checkLen-2);
                    break;
            }
        }
        return retTable;
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
    
    constructor(uart, cb=null) {
        _gps = uart;
        _gps.setrxfifosize(512);
        _fields = Fields();
        // GPS is configured by the constructor so that we can register
        // the rxdata callback
        _gps.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS, _gps_rxdata.bindenv(this));
        _cb = cb;
    }
    
    function _gps_rxdata() {
        local ch = _gps.read()
        if(ch  == '$') {
            _fields.setSentence(_gps_line);
            _fields.parse_fields();
            _last_table = _fields.extractData();
            _gps_line = ""; // Reset the string after a full line has been
            // collected
            if(_cb != null) {
                _cb(_last_table);
            }
            _setLastLatLong(_last_table);
            
            _isValid = ("checkSum" in _last_table && (_last_table.checkSum ==_fields.calcCheckSum(_gps_line)));
        }
        else {
            _gps_line += ch.tochar();
        }
    }
    // This function should take the table of data as an argument
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
            if(tb.type != VTG) { // VTG is the only supported packet type that 
            // doesn't contain latitude/longitude data
                // Check for void data 
                if(tb.status == "Active") {
                    _lastLat = tb.latitude;
                    _lastLong = tb.longitude;
                }
            }
        }
    }
}