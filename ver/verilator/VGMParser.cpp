#include <iostream>
#include <iomanip>
#include <string>
#include <cstring>
#include <cstdio>
#include <cmath>
#include <sstream>
#include <fstream>
#include "VGMParser.hpp"
#include "WaveWritter.hpp"

using namespace std;

void JTTParser::open(const char* filename, int limit) {
    file.open(filename);
    if ( !file.good() ) cerr << "Failed to open file: " << filename << '\n';
    cerr << "Open " << filename << '\n';
    done=false;
    line_cnt = 0;
    // try to get the chip type from the 1st line
    char typestr[128];
    file.getline( typestr, 128 );
    if( strcmp( typestr, "ym2203")==0 ) chip_cfg=ym2203;
    else if( strcmp( typestr, "ym2612")==0 ) chip_cfg=ym2612;
    else if( strcmp( typestr, "ym2610")==0 ) chip_cfg=ym2610;
    else {
        chip_cfg = ym2612;
        file.seekg(0,ios_base::beg);
    }
}

void JTTParser::remove_blanks( char*& str ) {
    if( str==NULL ) {
        cerr << "Syntax error at line " << line_cnt << '\n';
        throw 0;
    }
    while( *str!=0 && (*str==' ' || *str=='\t') ) str++;
}

void JTTParser::parse_opdata(char *txt_arg, int cmd_base) {
    int ch, op, int_val, read=0;
    read=sscanf( txt_arg, " %X , %X , %X ", &ch, &op, &int_val );
    if( read != 3 ) {
        cerr << "Syntax error at line " << line_cnt << '\n';
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
        cerr << "Missing arguments at line " << line_cnt << '\n';
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
        cerr << "Missing arguments at line " << line_cnt << '\n';
        throw 0;
    }
    addr = 1; // ADPCM-A always uses A1=1
    val = int_val;
    cmd = cmd_base>2 ? (cmd_base | ch) : cmd_base; // commands 0-2 are global
}

void JTTParser::parse_adpcmb_data(char *txt_arg, int cmd_base) {
    int int_val, read=0;
    read=sscanf( txt_arg, " %X ", &int_val );
    if( read != 1 ) {
        cerr << "Missing arguments at line " << line_cnt << '\n';
        throw 0;
    }
    addr = 0; // ADPCM-B always uses A1=0
    val = int_val;
    cmd = cmd_base;
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

    adpcma_commands["aon"]  = 0;
    adpcma_commands["atl"] = 1;
    adpcma_commands["alr"] = 8;
    adpcma_commands["astart_lsb"] = 0x10;
    adpcma_commands["astart_msb"] = 0x18;
    adpcma_commands["aend_lsb"] = 0x20;
    adpcma_commands["aend_msb"] = 0x28;

    adpcmb_commands["bctl"] = 0x10;
    adpcmb_commands["blr"]  = 0x11;
    adpcmb_commands["bstart_lsb"] = 0x12;
    adpcmb_commands["bstart_msb"] = 0x13;
    adpcmb_commands["bend_lsb"]   = 0x14;
    adpcmb_commands["bend_msb"]   = 0x15;
    adpcmb_commands["bdelta_lsb"] = 0x19;
    adpcmb_commands["bdelta_msb"] = 0x1a;
    adpcmb_commands["btl"]        = 0x1b;
    adpcmb_commands["flag_ctl"]   = 0x1c;

    global_commands["kon"] = 0x28;
    global_commands["timer"] = 0x27;
    global_commands["lfo"] = 0x22;
    default_ch = 0;
    // prepare sine table
    adpcm_sine = new unsigned char[1024];
    short *sine = new short[2048];
    for(int k=0;k<2048;k++) {
        sine[k]=4095.0*sin( 6.283185*k*4.0/2048.0 );
    }
    YM2610_ADPCMB_Encode( sine, adpcm_sine, 2048 );
    delete []sine;
}

JTTParser::~JTTParser() {
    delete []adpcm_sine;
    adpcm_sine = 0;
}

void ADPCMbuffer::load(const char* filename) {
    ifstream fin( filename, ios_base::binary );
    if( !fin ) {
        cerr << "ERROR: Cannot open file " << filename << '\n';
        throw 1;
    }
    delete[] data;
    fin.seekg(0,ios_base::end);
    bufsize = fin.tellg();
    mask=bufsize-1;
    data = new char[bufsize];
    fin.seekg( 0, ios_base::beg );
    fin.read( data, bufsize );
    int readcnt = fin.gcount();
    cerr << "INFO: file '" << filename << "' loaded into ADPCM memory (0x"
         << hex << readcnt << " bytes) \n";
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
            // cerr << "TXT CMD = " << txt_cmd << "\n";
            remove_blanks(txt_cmd);

            if( txt_cmd[0]=='$' ) {
                int aux0, aux1;
                char *line=txt_cmd+1;
                if( sscanf( line, "%X,%X", &aux0, &aux1 )!= 2 ) {
                    cerr << "ERROR: Incomplete line " << line_cnt << '\n';
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
                cerr << "ERROR: Incomplete line " << line_cnt << '\n';
                cerr << "txt_cmd = " << txt_cmd << '\n';
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
                // cerr << "Wait for " << wait << '\n';
                return cmd_wait;
            }
            // Load ADPCM ROM files
            if( strcmp(txt_cmd, "load_adpcma")==0 ) {
                adpcm_a.load( txt_arg );
                continue; // process next command
            }
            if( strcmp(txt_cmd, "load_adpcmb")==0 ) {
                adpcm_b.load( txt_arg );
                continue; // process next command
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
            // ADPCM-B commands
            auto adpcmb_cmd = adpcmb_commands.find(txt_cmd);
            if( adpcmb_cmd != adpcmb_commands.end() ) {
                cmd_base = adpcmb_cmd->second;
                parse_adpcmb_data(txt_arg, cmd_base);
                return cmd_write;
            }
            // Global commands
            auto global_cmd = global_commands.find(txt_cmd);
            if( global_cmd != global_commands.end() ) {
                cmd = global_cmd->second;
                int aux;
                if( sscanf( txt_arg,"%X", &aux) != 1 ) {
                    cerr << "ERROR: Expecting value in line " << line_cnt << '\n';
                    return cmd_error;
                }
                val = (char)aux;
                addr=0;
                return cmd_write;
            }

            cerr << "ERROR: incorrect syntax at line " << line_cnt << '\n';
            cerr << '\t' << line << '\n';
            done=true;
            return cmd_error;
        }
        catch( int ) { done=true; return cmd_error; }
    }
    done=true;
    return cmd_finish;
}

void ADPCMbuffer::save(const char* filename) {
    if( bufsize==0 ) return;
    ofstream of(filename, ios_base::binary );
    of.write( data, bufsize );
    cerr << "INFO: ADPCM data written to " << filename << '\n';
}

uint64_t VGMParser::length() {
    uint64_t l = totalwait*1e9/44100; // total number of samples in ns
    return l;
}

void VGMParser::open(const char* filename, int limit) {
    file.open(filename,ios_base::binary);
    if ( !file.good() ) cerr << "Failed to open file: " << filename << '\n';
    cerr << "Open " << filename << '\n';
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
    cerr << "YM Freq = " << dec << ym_freq << " Hz\n";
    // seek out data start
    if( version[0]<0x50 && version[1]==1 ) {
        cerr << "VGM version < 1.50 in this file. Data offset set at 0x40\n";
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
    string aux = filename;
    auto pos = aux.find_last_of('/');
    if( pos == string::npos ) pos=0; else pos++;
    aux = aux.substr( pos ); // trim path
    aux = aux+".jtt";
    ftrans.open(aux);
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
    bool done=false;
    if( addr==1 && _cmd < 0x30 ) { // ADPCM-A
        done=true;
        switch( _cmd ) {
            case 0x0: {
                stringstream ss;
                ss << "aon " << hex << _val << " # channels "; 
                int aux = _val;
                for( int k=0; k<6; k++) {
                    if( aux&1 ) ss << k; else ss << ' ';
                    aux>>=1;
                }
                strcpy(line, ss.str().c_str() );
                break; }
            case 0x1: sprintf(line,"atl %02X", _val ); break;
            case 0x8: case 0x9: case 0xa: case 0xb: case 0xc: case 0xd:
                sprintf(line,"alr %X,%02X", _cmd& 0x7, _val ); break;
            case 0x10: case 0x11: case 0x12: case 0x13: case 0x14: case 0x15:
                sprintf(line,"astart_lsb %X,%02X", _cmd& 0x7, _val ); break;
            case 0x18: case 0x19: case 0x1a: case 0x1b: case 0x1c: case 0x1d:
                sprintf(line,"astart_msb %X,%02X", _cmd& 0x7, _val ); break;
            case 0x20: case 0x21: case 0x22: case 0x23: case 0x24: case 0x25:
                sprintf(line,"aend_lsb %X,%02X", _cmd& 0x7, _val ); break;
            case 0x28: case 0x29: case 0x2a: case 0x2b: case 0x2c: case 0x2d:
                sprintf(line,"aend_msb %X,%02X", _cmd&0x7, _val ); break;
            default: done=false;
        }
    }
    if(!done) sprintf(line,"$%d%02X,%02X", addr,_cmd,_val );
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

void VGMParser::decode_save( char *buf, int length, int rom_start, bool Adecoder ) {
    stringstream s;
    s << hex << rom_start;
    string fname( s.str() );
    length <<= 1;
    short *dest = new short[length];
    if( Adecoder ) {
        YM2610_ADPCMA_Decode( (unsigned char*) buf, dest, length );
        //YM2610_ADPCMB_Decode( (unsigned char*) buf, dest, length, true );
    }
    else {
        YM2610_ADPCMB_Decode( (unsigned char*) buf, dest, length );
    }
    WaveWritter wav( (fname+".wav").c_str(), 18500, false );
    // save array file
    ofstream of( (fname+".dec").c_str());
    for( int k=0; k<length; k++ ) {
        of << "adpcm[" << k << "]=" << dest[k] << '\n';
        int16_t v[3];
        v[0] = v[1] = dest[k]; v[2]=0;
        wav.write(v);
    }
    delete[] dest;
}

char *ADPCMbuffer::getptr(int _bufsize ) {
    if(_bufsize==0) return data;
    if( data == 0 ) {
        bufsize = _bufsize;
        data = new char [bufsize];
        mask = bufsize-1; // bufsize should be a multiple of 2!
        cerr << "INFO: ADPCM buffer created of size 0x" << hex << bufsize
            << " mask = 0x" << hex << mask << '\n';
    }
    if( bufsize != _bufsize ) {
        cerr << "ERROR: Requested ADPCM buffer of different size from the previous one.\n";
        throw 1;
    }
    return data;
}

char ADPCMbuffer::get(int offset ) {
    //offset &= mask;
    if( offset > bufsize ) {
        cerr << "WARNING: ADPCM data requested outside the buffer size\n";
        return 0;
    }
    if( data==NULL ) {
        return 0;
    }
    // int d = ADPCM_data[offset]&0xff;
    // if(offset!=0)std::cerr << "INFO: read ADPCM " << d << " at " << offset << '\n';
    return data[offset];
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
        // cerr << "VGM 0x" << hex << (((int)vgm_cmd)&0xff) << '\n';
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
                //  cerr << "INFO: write to register (0x" << hex << _cmd << ") below 0x20\n"; }
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
                //  cerr << "ADPCM command " << hex << icmd << " - " << (val&0xff) << '\n';
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
                    cerr << "ERROR: Unsupported data block type " << hex << (unsigned)type << '\n';
                    return -2;}
                uint32_t length;
                file.read( (char*)&length, 4 );
                if( length == 0 ) {
                    cerr << "WARNING: zero-sized data stream in input file\n";
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
                        // cerr << hex << rom_size << " - " << rom_start << '\n';
                        if( length==0 ) break;
                        char *buf = &adpcm_a.getptr(rom_size)[rom_start];
                        length -= 8;
                        if( length > 0) {
                            file.read( buf, length );
                            if(decode) decode_save( buf, length, rom_start, true );
                            cerr << "INFO: read " << dec << length << " bytes into ADPCM-A ROM at 0x"
                                 << hex << rom_start <<
                                 " (ADDR 0x" << hex << (rom_start>>8) <<
                                 " - 0x" << hex << ( (rom_start+length)>>8) << ") \n";
                        }
                        break;
                    }
                    case 0x83:  { // 0x83 = ADPCM-B (delta T)
                        uint32_t rom_size, rom_start;
                        file.read( (char*)&rom_size, 4 ); // ROM length
                        file.read( (char*)&rom_start, 4 );
                        // cerr << hex << rom_size << " - " << rom_start << '\n';
                        if( length==0 ) break;
                        char *buf = &adpcm_b.getptr(rom_size)[rom_start];
                        length -= 8;
                        if( length > 0) {
                            file.read( buf, length );
                            if(decode) decode_save( buf, length, rom_start, false );
                            cerr << "INFO: read " << dec << length << " bytes into ADPCM-B ROM at 0x"
                                 << hex << rom_start <<
                                 " (ADDR 0x" << hex << (rom_start>>8) <<
                                 " - 0x" << hex << ( (rom_start+length)>>8) << ") \n";
                        }
                        break;
                    }
                    default: {
                        int skip = length;
                        cerr << "INFO: skipping unsupported block type "
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
                            case 0: cerr << "PSG Tone0 MSB\n"; break;
                            case 1: cerr << "PSG Tone1 MSB\n"; break;
                            case 2: cerr << "PSG Tone2 MSB\n"; break;
                            case 3: cerr << "PSG Noise CTRL\n"; break;
                            case 4: cerr << "PSG vol 0 = " << lsb <<'\n'; break;
                            case 5: cerr << "PSG vol 1 = " << lsb <<'\n'; break;
                            case 6: cerr << "PSG vol 2 = " << lsb <<'\n'; break;
                            case 7: cerr << "PSG vol 3 = " << lsb <<'\n'; break;
                        }
                    else cerr << "PSG repeat\n";
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
                        cerr << "Error: DAC stream different from YM2612 type\n";
                        return cmd_error;
                    }
                    int cmd0 = aux[2], val0=aux[3];
                    cerr << "Stream ID " << stream_id << " write " << val0
                        << " to port " << cmd0 << '\n';
                }
                continue;
            case 0x91: // set stream data
            case 0x95: // start stream, fast call
                {
                    if( stream_notmplemented_info ) {
                        cerr << "WARNING: Stream commands 0x90-0x95 are not implemented\n";
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
                cerr << "ERROR: Unsupported VGM command 0x" << hex << (((int)vgm_cmd)&0xff)
                    << " at offset 0x" << (int)file.tellg() << '\n';
                return -2;
        }
    }
    return -1;
}

void Gym::open(const char* filename, int limit) {
    file.open(filename,ios_base::binary);
    if ( !file.good() ) cerr << "Failed to open file: " << filename << '\n';
    cerr << "Open " << filename << '\n';
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
        // cerr << "Read "  << (int)c << '\n';
        // cerr << (int) c << " @ " << file.tellg() << '\n';
        if( count> count_limit && count_limit>0 ) {
            cerr << "GYM command limit achieved.\n";
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
    // cerr << "Done\n";
    return -1;
}

RipParser* ParserFactory( const char *filename, int clk_period ) {
    string aux(filename);
    auto ext = aux.find_last_of('.');
    if( ext == string::npos ) {
        cerr << "ERROR: The filename must end in .gym or .vgm\n";
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
    cerr << "ERROR: The filename must end in .gym or .vgm\n";
    return NULL;
}

int RipParser::period() {
    return 0;
}

int VGMParser::period() {
    // cerr << "Freq = " << ym_freq << '\n';
    return ym_freq==0 ? 0 : 1000'000/(ym_freq/1000);
}

int JTTParser::period() {
    if( chip_cfg == ym2610 ) return 125;
    else return 0;
}

uint8_t JTTParser::ADPCM(int offset) {
    if( !adpcm_a.is_empty() )
        return adpcm_a.get(offset);
    else { // fill with a sine wave
        return adpcm_sine[ offset&0x3FF  ];
    }
}

uint8_t JTTParser::ADPCMB(int offset) {
    if( !adpcm_b.is_empty() ) {
        int val = adpcm_b.get(offset);
       //  cerr << "INFO: ADPCMB @0x" << hex << offset 
       //       << " = 0x" << hex << val << '\n';
        return val;
    }
    else { // fill with a sine wave
        return adpcm_sine[ offset&0x3FF  ];
    }
}

// For ADPCM-B
static int stepsizeTable[ 16 ] = {
    57, 57, 57, 57, 77,102,128,153,
    57, 57, 57, 57, 77,102,128,153
};

// For ADPCM-A
static int stepsizeTable_A[ 16 ] = {
    58, 58, 58, 58, 77, 103, 124, 150,
    58, 58, 58, 58, 77, 103, 124, 150
};

int YM2610_ADPCMB_Decode( unsigned char *src , short *dest , int len, bool Atype ) {
    int flag , shift , step;
    long adpcm;
    float xn = 0, i, zprev=0, yn, zn;
    const int stepmin = Atype ?   16 : 127;
    const int stepmax = Atype ? 1552 : 24576;
    const int* stepLUT = Atype ? stepsizeTable_A : stepsizeTable;
    int stepSize = stepmin;

    flag = 0;
    shift = 4;
    step = 0;
    while( len-- ) {
        adpcm = ( *src >> shift ) & 0xf;
        i = (( ( adpcm & 7 ) * 2.0 + 1 ) * stepSize) / 8.0;
        if( adpcm & 8 )
            xn -= i;
        else
            xn += i;
        // if( xn > 32767 )
        //     xn = 32767;
        // else if( xn < -32768 )
        //     xn = -32768;
        stepSize = (stepSize * stepLUT[ adpcm ]) / 64;
        if( stepSize < stepmin )
            stepSize = stepmin;
        else if ( stepSize > stepmax )
            stepSize = stepmax;
        // DC removal
        //zn = xn + 0.95*zprev;
        //yn = zn - zprev;
        //zprev=zn;

        *dest = ( short )xn;
        dest++;
        src += step;
        step = step ^ 1;
        shift = shift ^ 4;
    }
    return 0;
}

int YM2610_ADPCMB_Encode( short *src , unsigned char *dest , int len ) {
    int lpc , flag;
    long i , dn , xn , stepSize;
    unsigned char adpcm;
    unsigned char adpcmPack;
    xn = 0;
    stepSize = 127;
    flag = 0;
    for( lpc = 0 ; lpc < len ; lpc++ ) {
        dn = *src - xn;
        src++;
        i = ( abs( dn ) << 16 ) / ( stepSize << 14 );
        if( i > 7 ) i = 7;
        adpcm = ( unsigned char )i;
        i = ( adpcm * 2 + 1 ) * stepSize / 8;
        if( dn < 0 ) {
            adpcm |= 0x8;
            xn -= i;
        }
        else {
            xn += i;
        }
        stepSize = ( stepsizeTable[ adpcm ] * stepSize ) / 64;
        if( stepSize < 127 )
            stepSize = 127;
        else if( stepSize > 24576 )
            stepSize = 24576;
        if( flag == 0 ) {
            adpcmPack = ( adpcm << 4 ) ;
            flag = 1;
        }
        else {
            adpcmPack |= adpcm;
            *dest = adpcmPack;
            dest++;
            flag = 0;
        }
    }
    return 0;
}

// ADPCM-A the MAME way
static int jedi_table[ 49*8 ];
static constexpr int step_inc[8] = { -1, -1, -1, -1, 2, 5, 7, 9 };
/* usual ADPCM table (16 * 1.1^N) */

void Init_ADPCMATable()
{
    int step, nib;
    constexpr int steps[49] =
    { // 7 rows x 7 columns
         16,  17,   19,   21,   23,   25,   28,
         31,  34,   37,   41,   45,   50,   55,
         60,  66,   73,   80,   88,   97,  107,
        118, 130,  143,  157,  173,  190,  209,
        230, 253,  279,  307,  337,  371,  408,
        449, 494,  544,  598,  658,  724,  796,
        876, 963, 1060, 1166, 1282, 1411, 1552
    };
    ofstream fout("adpcm_table.txt");
    fout << setfill('0');
    const int max_inc = (1<<11)-1;
    for (step = 0; step < 49; step++)
    {
        /* loop over all nibbles and compute the difference */
        for (nib = 0; nib < 8; nib++)
        {
            int value = (2*(nib & 0x07) + 1) * steps[step] / 8;
            if( value > max_inc ) value=max_inc;
            int idx = (step<<3) + nib;
            jedi_table[idx] = (nib&0x08) ? -value : value;
            fout << "lut[9'o" << setw(2) << oct << step << "_"  << nib << "] = 12'd"
                 << setw(4) << value << "; ";
            if(nib==3) fout <<'\n';
        }
        fout << '\n';
    }
}

void YM2610_ADPCMA_Decode( unsigned char *src, short *dest, int len ) {
    static bool init=false;
    if( !init ) { Init_ADPCMATable(); init=true; }
    int nibble=1;
    int step=0, x=0;
    while( len-- ) {
        int data = nibble ? (*src>>4) : *src;
        data&=0xf;
        int addr = (step<<3) | (data&7);
        x = (data&8) ? x-jedi_table[ addr ] : x+jedi_table[ addr ];
        // if( x & ~0x7ff )    // 12-bit sign extension
        //     x |= ~0xffff;
        // else
        //     x &= 0xffff;
        step += step_inc[ data&7 ];
        if( step>48 ) step=48;
        if( step<0 ) step=0;
        *dest++ = (short)x;
        if( !nibble ) src++;
        nibble = 1-nibble;
    }
}
