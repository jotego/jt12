#include <iostream>
#include <string>
#include <cstring>
#include <cstdio>
#include "VGMParser.hpp"

using namespace std;

void JTTParser::open(const char* filename, int limit) {
    file.open(filename);
    if ( !file.good() ) cout << "Failed to open file: " << filename << '\n';
    cout << "Open " << filename << '\n';
    done=false;
    line_cnt = 0;
    chip_cfg = ym2612;
}

void JTTParser::remove_blanks( char*& str ) {
    if( str==NULL ) {
        cout << "Syntax error at line " << line_cnt << '\n';
        throw 0;
    }
    while( *str!=0 && (*str==' ' || *str=='\t') ) str++;
}

void JTTParser::parse_opdata(char *txt_arg, int cmd_base) {
    int ch, op, int_val, read=0;
    read=sscanf( txt_arg, " %X , %X , %X ", &ch, &op, &int_val );
    if( read != 3 ) {
        cout << "Syntax error at line " << line_cnt << '\n';
        throw 0;
    }
    addr = ch < 3 ? 0 : 1;
    if(ch>=3) ch-=3;

    // adjust for writting order of device
    switch(op) {
        case 0: op=0; break;
        case 1: op=2; break;
        case 2: op=1; break;
        case 3: op=3; break;
    }

    val = int_val;
    cmd = cmd_base | ((op<<2) | ch);
}

void JTTParser::parse_chdata(char *txt_arg, int cmd_base) {
    int ch, int_val, read=0;
    read=sscanf( txt_arg, " %X , %X ", &ch, &int_val );
    if( read == 1 ) {
        int_val = ch;
        ch = default_ch;
    }
    else if( read != 2 ) {
        cout << "Missing arguments at line " << line_cnt << '\n';
        throw 0;
    }
    addr = ch < 3 ? 0 : 1;
    if(ch>=3) ch-=3;

    val = int_val;
    cmd = cmd_base | ch;
}

void JTTParser::parse_adpcma_data(char *txt_arg, int cmd_base) {
    int ch, int_val, read=0;
    read=sscanf( txt_arg, " %X , %X ", &ch, &int_val );
    if( read == 1 ) {
        int_val = ch;
        ch = default_ch;
    }
    else if( read != 2 ) {
        cout << "Missing arguments at line " << line_cnt << '\n';
        throw 0;
    }
    addr = 1; // ADPCM-A always uses A1=1
    val = int_val;
    cmd = cmd_base | ch;
}

JTTParser::JTTParser(int c) : RipParser(c) {
    op_commands["dt_mul"] = 0x30;
    op_commands["tl"] = 0x40;
    op_commands["ks_ar"] = 0x50;
    op_commands["amon_dr"] = 0x60;
    op_commands["sr"] = 0x70;
    op_commands["sl_rr"] = 0x80;
    op_commands["ssg"] = 0x90;
    ch_commands["fnum_lsb"] = 0xa0;
    ch_commands["blk_fnum"] = 0xa4;
    ch_commands["fb_con"] = 0xb0;
    ch_commands["lr_ams_pms"] = 0xb4;

    adpcma_commands["aon"] = 0;
    adpcma_commands["atl"] = 1;
    adpcma_commands["alr"] = 8;
    adpcma_commands["astart_lsb"] = 0x10;
    adpcma_commands["astart_msb"] = 0x18;
    adpcma_commands["aend_lsb"] = 0x20;
    adpcma_commands["aend_msb"] = 0x28;

    global_commands["kon"] = 0x28;
    global_commands["timer"] = 0x27;
    global_commands["lfo"] = 0x22;
    default_ch = 0;
}

int JTTParser::parse() {
    if(done) return cmd_finish;
    while( !file.eof() && file.good() ) {
        try {
            char line[128]="";
            char *noblanks;
            do{
                file.getline(line,128);
                line_cnt++;
                noblanks = line;
                remove_blanks(noblanks);
            } while( (noblanks[0]=='#' || strlen(line)==0) && !file.eof()  );
            if( strlen(line)==0 ) { done=true; return cmd_finish; }
            char line2[128];
            strncpy( line2, line, 128 ); line2[127]=0;
            char *txt_cmd = strtok( line2, "#" );
            // cout << "TXT CMD = " << txt_cmd << "\n";
            remove_blanks(txt_cmd);

            if( txt_cmd[0]=='$' ) {
                int aux0, aux1;
                char *line=txt_cmd+1;
                if( sscanf( line, "%X,%X", &aux0, &aux1 )!= 2 ) {
                    cout << "ERROR: Incomplete line " << line_cnt << '\n';
                    return cmd_error;
                }
                addr = (aux0&0x100) ? 1 : 0;
                cmd = aux0 & 0xff;
                val = aux1 & 0xff;
                return cmd_write;
            }

            if( strcmp(txt_cmd, "finish")==0 ) {
                done=true;
                return cmd_finish;
            }
            char *txt_arg = strchr( txt_cmd, ' ');
            char cmd_base;
            if( txt_arg==NULL ) {
                cout << "ERROR: Incomplete line " << line_cnt << '\n';
                cout << "txt_cmd = " << txt_cmd << '\n';
                done=true;
                return cmd_error;
            }
            *txt_arg = 0;
            txt_arg++;

            if( strcmp(txt_cmd, "wait")==0 ) {
                int aux;
                sscanf( txt_arg, "%d", &aux );
                wait = aux;
                wait *= 24*clk_period;
                // cout << "Wait for " << wait << '\n';
                return cmd_wait;
            }
            // OP commands
            auto op_cmd = op_commands.find(txt_cmd);
            if( op_cmd != op_commands.end() ) {
                cmd_base = op_cmd->second;
                parse_opdata(txt_arg, cmd_base);
                return cmd_write;
            }
            // CH commands
            auto ch_cmd = ch_commands.find(txt_cmd);
            if( ch_cmd != ch_commands.end() ) {
                cmd_base = ch_cmd->second;
                parse_chdata(txt_arg, cmd_base);
                return cmd_write;
            }
            // ADPCM-A commands
            auto adpcma_cmd = adpcma_commands.find(txt_cmd);
            if( adpcma_cmd != adpcma_commands.end() ) {
                cmd_base = adpcma_cmd->second;
                parse_adpcma_data(txt_arg, cmd_base);
                return cmd_write;
            }
            // Global commands
            auto global_cmd = global_commands.find(txt_cmd);
            if( global_cmd != global_commands.end() ) {
                cmd = global_cmd->second;
                int aux;
                if( sscanf( txt_arg,"%X", &aux) != 1 ) {
                    cout << "ERROR: Expecting value in line " << line_cnt << '\n';
                    return cmd_error;
                }
                val = (char)aux;
                addr=0;
                return cmd_write;
            }

            cout << "ERROR: incorrect syntax at line " << line_cnt << '\n';
            cout << '\t' << line << '\n';
            done=true;
            return cmd_error;
        }
        catch( int ) { done=true; return cmd_error; }
    }
    done=true;
    return cmd_finish;
}

uint64_t VGMParser::length() {
    uint64_t l = totalwait*1e9/44100; // total number of samples in ns
    return l;
}

void VGMParser::open(const char* filename, int limit) {
    file.open(filename,ios_base::binary);
    if ( !file.good() ) cout << "Failed to open file: " << filename << '\n';
    cout << "Open " << filename << '\n';
    stream_id = cmd = val = addr = 0;
    file.seekg(0x18);
    file.read((char*)& totalwait, 4);
    totalwait &= 0xffffffff;
    // read version number
    char version[2];
    file.seekg(0x08);
    file.read( version,2 );
    // Read the chip frequency, this is located at different
    // positions depending on the chip type so it also determines
    // which chip is used in the file
    chip_cfg = unknown;
    file.seekg(0x2c); // offset to YM2612
    file.read( (char*) &ym_freq, 4 );
    if( ym_freq == 0 ) { // try YM2203
        file.seekg(0x44); // offset to YM2612
        file.read( (char*) &ym_freq, 4 );
        if( ym_freq ==0 ) { // try YM2610
            file.seekg(0x4C); // offset to YM2610
            file.read( (char*) &ym_freq, 4 );
            if( ym_freq && !(ym_freq&0x8000'0000) ) chip_cfg = ym2610;
        }
        else chip_cfg = ym2203;
    }
    else chip_cfg = ym2612;
    cout << "YM Freq = " << dec << ym_freq << " Hz\n";
    // seek out data start
    if( version[0]<0x50 && version[1]==1 ) {
        cout << "VGM version < 1.50 in this file. Data offset set at 0x40\n";
        file.seekg(0x40);
    }
    else {
        int32_t start;
        file.seekg(0x34);
        file.read( (char*)&start, 4 );
        start+=0x34;
        file.seekg(start);
    }
    done=false;
    // open translation file
    ftrans.open("last.jtt");
    cur_time=0;
    if( stream_data != NULL ) { delete stream_data; stream_data=NULL; }
    data_offset=0;
    pending_wait=0;
    // max_PSG_warning = 10;
    stream_notmplemented_info = true;
}

VGMParser::~VGMParser() {
    file.close();
    ftrans.close();
    if( stream_data != NULL ) { delete stream_data; stream_data=NULL; }
}

void VGMParser::translate_cmd() {
    char line[128];
    int _cmd = cmd; _cmd&=0xff;
    int _val = val; _val&=0xff;
    sprintf(line,"$%d%2X,%02X", addr,_cmd,_val );
    ftrans << line;
    if( cmd == 0x28 ) {
        if( val&0xf0 )
            ftrans << " # Key on";
        else
            ftrans << " # Key off";
    }
    ftrans << '\n';
}

void VGMParser::translate_wait() {
    float ws = wait;
    ws /= 44100.0; // wait in seconds
    cur_time += ws;
    const float Tsyn = 24.0*clk_period*1e-9;
    float wsyn = ws/Tsyn;
    ftrans << "wait " << (int)wsyn << " # ";
    ftrans << cur_time << " s\n";
    //ftrans << wait << " -> " << ws << " Total: " << cur_time << "s \n";
}

int VGMParser::parse() {
    if(done) return -1;
    if( pending_wait !=0 ) {
        wait = pending_wait;
        translate_wait();
        adjust_wait();
        pending_wait = 0;
        return cmd_wait; // request wait
    }
    while( !file.eof() && file.good() ) {
        unsigned char vgm_cmd;
        file.read( (char*)&vgm_cmd, 1);
        if( !file.good() ) return -1; // finish immediately
        // cout << "VGM 0x" << hex << (((int)vgm_cmd)&0xff) << '\n';
        char extra[2];
        switch( vgm_cmd ) {
            case 0x52: // A1=0
            case 0x55: // YM2203 write
            case 0x56:
            case 0x58: // YM2610
                addr = 0;
                file.read( extra, 2);
                cmd = extra[0];
                val = extra[1];
                // int _cmd = cmd;
                // _cmd &= 0xff;
                // if( _cmd < 0x20 ) {
                //  cout << "INFO: write to register (0x" << hex << _cmd << ") below 0x20\n"; }
                translate_cmd();
                return cmd_write;
            case 0xA5: // Write to dual YM2203
                file.read(extra,2); // ignore
                continue;
            case 0x53: // A1=1
            case 0x57:
            case 0x59: { // YM2610
                addr = 1;
                file.read( extra, 2);
                cmd = extra[0];
                val = extra[1];
                // int icmd = ((int)cmd)&0xff;
                // if( icmd < 0x30 ) {
                //  cout << "ADPCM command " << hex << icmd << " - " << (val&0xff) << '\n';
                // }
                translate_cmd();
                return cmd_write;
            }
            case 0x61:
                uint16_t rd_wait;
                file.read( (char*) &rd_wait, 2);
                wait = rd_wait;
                translate_wait();
                adjust_wait();
                return cmd_wait; // request wait
            case 0x62:
                wait = 735;
                translate_wait();
                adjust_wait();
                return cmd_wait; // wait one frame (NTSC)
            case 0x63:
                wait = 882; // wait one frame (PAL)
                translate_wait();
                adjust_wait();
                return cmd_wait;
            case 0x66:
                done=true;
                return -1; // finish
                // continue;
            case 0x67: // data block:
            {
                file.seekg( 1, ios_base::cur ); // skip 0x66 byte
                unsigned char type;
                file.read( (char*)&type, 1 );
                if( !(type==0 || (type >=0x80 && type<0xc0))  ) {// compressed stream
                    cout << "ERROR: Unsupported data block type " << hex << (unsigned)type << '\n';
                    return -2;}
                uint32_t length;
                file.read( (char*)&length, 4 );
                if( length == 0 ) {
                    cout << "WARNING: zero-sized data stream in input file\n";
                    continue; }
                switch( type ) {
                    case 0: { // uncompressed data
                        stream_data = new char[length];
                        file.read( stream_data, length );
                        break;
                    }
                    case 0x82:  { // 0x82 = ADPCM-A
                        uint32_t rom_size, rom_start;
                        file.read( (char*)&rom_size, 4 ); // ROM length
                        file.read( (char*)&rom_start, 4 );
                        // cout << hex << rom_size << " - " << rom_start << '\n';
                        if( length==0 ) break;
                        if( ADPCM_data == NULL ) {
                            ADPCM_data = new char[12*1024*1024]; // Max 12 Mbyte
                        }
                        if( rom_start+length-8 > 12*1024*1024 ) {
                            cout << "ERROR: ADPCM length is limited to 12 Mbyte\n";
                            throw 1;
                        }
                        char *buf = &ADPCM_data[rom_start];
                        length -= 8;
                        if( length > 0) {
                            file.read( buf, length );
                            cout << "INFO: read " << dec << length << " bytes into ADPCM ROM" << '\n';
                        }
                        break;
                    }
                    default: {
                        int skip = length;
                        cout << "INFO: skipping unsupported block type "
                            << hex << (type&0xff) <<
                            " of length " << dec << skip << '\n';
                        if( skip!= 0 ) file.seekg( skip, ios_base::cur );
                        break;
                    }
                }
            }

            // wait short commands (bad design option for VGM file designer)
            case 0x70: case 0x71: case 0x72: case 0x73:
            case 0x74: case 0x75: case 0x76: case 0x77:
            case 0x78: case 0x79: case 0x7A: case 0x7B:
            case 0x7c: case 0x7d: case 0x7e: case 0x7f:
                wait=(vgm_cmd&0xf)+1;
                translate_wait();
                adjust_wait();
                return 1;
            case 0x4F: // PSG command, ignore
            case 0x50:
                file.read(extra,1);
                cmd=extra[0];
                /* { // Decode command
                    int lsb = cmd&0xf;
                    if( cmd & 0x80 )
                        switch( (cmd>>4)&0x7 ) {
                            case 0: cout << "PSG Tone0 MSB\n"; break;
                            case 1: cout << "PSG Tone1 MSB\n"; break;
                            case 2: cout << "PSG Tone2 MSB\n"; break;
                            case 3: cout << "PSG Noise CTRL\n"; break;
                            case 4: cout << "PSG vol 0 = " << lsb <<'\n'; break;
                            case 5: cout << "PSG vol 1 = " << lsb <<'\n'; break;
                            case 6: cout << "PSG vol 2 = " << lsb <<'\n'; break;
                            case 7: cout << "PSG vol 3 = " << lsb <<'\n'; break;
                        }
                    else cout << "PSG repeat\n";
                } */
                return cmd_psg;
            // DAC writes
            case 0x80: case 0x81: case 0x82: case 0x83:
            case 0x84: case 0x85: case 0x86: case 0x87:
            case 0x88: case 0x89: case 0x8A: case 0x8B:
            case 0x8c: case 0x8d: case 0x8e: case 0x8f:
                pending_wait=(vgm_cmd&0xf); // will reply with a wait on next call
                cmd=0x2a;
                val=stream_data[data_offset++]; // buffer overrun risk here.
                translate_cmd();
                return cmd_write;
            case 0x90: // setup stream control
                {
                    char aux[4];
                    file.read( aux, 4);
                    stream_id = aux[0];
                    if( aux[1]!=2 ) {
                        cout << "Error: DAC stream different from YM2612 type\n";
                        return cmd_error;
                    }
                    int cmd0 = aux[2], val0=aux[3];
                    cout << "Stream ID " << stream_id << " write " << val0
                        << " to port " << cmd0 << '\n';
                }
                continue;
            case 0x91: // set stream data
            case 0x95: // start stream, fast call
                {
                    if( stream_notmplemented_info ) {
                        cout << "WARNING: Stream commands 0x90-0x95 are not implemented\n";
                        stream_notmplemented_info = false;
                    }
                    int32_t aux;
                    file.read( (char*) & aux, 4 );
                    continue;   // not implemented
                }
            case 0x92: // set stream frequency
                {
                    char tt;
                    int32_t aux;
                    file.read( &tt, 1 );
                    file.read( (char*) & aux, 4 );
                    continue;   // not implemented
                }
            case 0x93: // start stream
                {
                    char tt;
                    int32_t aux;
                    file.read( &tt, 1 );
                    file.read( (char*) & aux, 4 );
                    file.read( &tt, 1 );
                    file.read( (char*) & aux, 4 );
                    continue;   // not implemented
                }
            case 0x94: // stop stream
                {
                    char ss;
                    file.read( &ss, 1 );
                }
            case 0xe0:
                file.read( (char*)&data_offset, 4);
                continue;
            default:
                cout << "ERROR: Unsupported VGM command 0x" << hex << (((int)vgm_cmd)&0xff)
                    << " at offset 0x" << (int)file.tellg() << '\n';
                return -2;
        }
    }
    return -1;
}

void Gym::open(const char* filename, int limit) {
    file.open(filename,ios_base::binary);
    if ( !file.good() ) cout << "Failed to open file: " << filename << '\n';
    cout << "Open " << filename << '\n';
    cmd = val = addr = 0;
    count = 0;
    max_PSG_warning = 10;
    count_limit = limit;
    chip_cfg = ym2612;
}

int Gym::parse() {
    char c;
    do {
        if( ! file.good() ) return -1; // finish
        file.read( &c, 1);
        count++;
        // cout << "Read "  << (int)c << '\n';
        // cout << (int) c << " @ " << file.tellg() << '\n';
        if( count> count_limit && count_limit>0 ) {
            cout << "GYM command limit achieved.\n";
            return -1;
        }
        switch(c) {
            case 0:
                wait = 735; // 16.7ms
                adjust_wait();
                return 1;
            case 3: {
                file.read(&c,1);
                unsigned p = (unsigned char)c;
                if(max_PSG_warning>0) {
                    max_PSG_warning--;
                    cerr << "Attempt to write to PSG port " << p << endl;
                    if(max_PSG_warning==0) cerr << "No more PSG warnings will be shown\n";
                }
                continue;
            }
            case 1:
            case 2: {
                char buf[2];
                file.read(buf,2);
                cmd = buf[0];
                val = buf[1];
                addr = (c == 2); // if c==2 then write to top bank of JT12
                return cmd_write;
            }
            default:
                cerr << "Wrong code ( " << ((int)c) << ") in GYM file\n";
                continue;
        }
    }while(file.good());
    // cout << "Done\n";
    return -1;
}

RipParser* ParserFactory( const char *filename, int clk_period ) {
    string aux(filename);
    auto ext = aux.find_last_of('.');
    if( ext == string::npos ) {
        cout << "ERROR: The filename must end in .gym or .vgm\n";
        return NULL;
    }
    RipParser *gym;
    if( aux.substr(ext)==".gym") {
        gym = new Gym(clk_period); gym->open(filename);
        return gym;
    }
    if( aux.substr(ext)==".vgm") {
        gym = new VGMParser(clk_period); gym->open(filename);
        return gym;
    }
    if( aux.substr(ext)==".jtt") {
        gym = new JTTParser(clk_period); gym->open(filename);
        return gym;
    }
    cout << "ERROR: The filename must end in .gym or .vgm\n";
    return NULL;
}

int RipParser::period() {
    return 0;
}

int VGMParser::period() {
    // cout << "Freq = " << ym_freq << '\n';
    return ym_freq==0 ? 0 : 1000'000/(ym_freq/1000);
}