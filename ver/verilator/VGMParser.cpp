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
}

void JTTParser::remove_blanks( (char*&) str ) {
	if( token==NULL ) { 
		cout << "Syntax error at line " << line_cnt << '\n'; 
		throw 0;
	}
	while( *str!=NULL && (*str==' ' || *str=='\t') ) str++;
}

void JTTParser::parse_opdata(int cmd_base) {
	int ch, op, int_val, read=0;
	read=sscanf( txt_ch, " %X , %X , %X ", &ch, &op, &int_val );
	if( read != 3 ) {
		cout << "Syntax error at line " << line_cnt << '\n';
		throw 0;
	}
	val = int_val;
	cmd = cmd_base | ((op<<2) | ch);
}

int JTTParser::parse() {
	if(done) return -1;
	while( !file.eof() && file.good() ) {
		try {
			string line;
			line << file;
			line_cnt++;
			char *token = strtok( line.c_str(), "#" );
			remove_blanks(token);
			char *txt_cmd = strtok( token, " \t" ); 
			remove_blanks(txt_cmd);
			if( strcmp(txt_cmd,"ar" ) {
				parse_opdata(0x50);
			}
		} 
		catch( int ) { return cmd_error; }
	}
}

uint64_t VGMParser::length() {
	uint64_t l = totalwait*1e9/44100; // total number of samples in ns
	return l;
}

void VGMParser::open(const char* filename, int limit) {
	file.open(filename,ios_base::binary);
	if ( !file.good() ) cout << "Failed to open file: " << filename << '\n';
	cout << "Open " << filename << '\n';
	cmd = val = addr = 0;
	file.seekg(0x18);
	file.read((char*)& totalwait, 4);
	totalwait &= 0xffffffff;
	// read version number
	char version[2];
	file.seekg(0x08);
	file.read( version,2 );
	if( version[0]<50 && version[1]==1 ) {
		cout << "VGM version < 1.50 in this file. Data offset set at 0x40\n";
		file.seekg(0x40);
	}
	else file.seekg(0x100);
	done=false;
	// max_PSG_warning = 10;
}

int VGMParser::parse() {
	if(done) return -1;
	while( !file.eof() && file.good() ) {
		char vgm_cmd;
		file.read( &vgm_cmd, 1);
		if( !file.good() ) return -1; // finish immediately
		// cout << "VGM 0x" << hex << (((int)vgm_cmd)&0xff) << '\n';
		char extra[2];
		switch( vgm_cmd ) {
			case 0x52: // A1=0
			case 0x56:
				addr = 0;
				file.read( extra, 2);
				cmd = extra[0];
				val = extra[1];
				return 0;
			case 0x53: // A1=1
			case 0x57:
				addr = 1;
				file.read( extra, 2);
				cmd = extra[0];
				val = extra[1];
				return 0;
			case 0x61:
				file.read( extra, 2);
				wait = extra[0];
				wait <<= 8;
				wait |= extra[1];
				wait&=0xffff;
				return 1; // request wait
			case 0x62:
				wait = 735;
				return 1; // wait one frame (NTSC)
			case 0x63:
				wait = 882; // wait one frame (PAL)
				return 1;
			case 0x66:
				done=true;
				return -1; // finish
				// continue;
			// wait short commands (bad design option for VGM file designer)
			case 0x70: wait=1; return 1;
			case 0x71: wait=2; return 1;
			case 0x72: wait=3; return 1;
			case 0x73: wait=4; return 1;
			case 0x74: wait=5; return 1;
			case 0x75: wait=6; return 1;
			case 0x76: wait=7; return 1;
			case 0x77: wait=8; return 1;
			case 0x78: wait=9; return 1;
			case 0x79: wait=0xa; return 1;
			case 0x7A: wait=0xb; return 1;
			case 0x7B: wait=0xc; return 1;
			case 0x7c: wait=0xd; return 1;
			case 0x7d: wait=0xe; return 1;
			case 0x7e: wait=0xf; return 1;
			case 0x7f: wait=0x10; return 1;
			case 0x4F: // PSG command, ignore
			case 0x50:
				file.read(extra,1);
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
}

int Gym::parse() {
	char c;
	do {
		if( ! file.good() ) return -1; // finish
		file.read( &c, 1);
		count++;
		// cout << "Read "	<< (int)c << '\n';
		// cout << (int) c << " @ " << file.tellg() << '\n';
		if( count> count_limit && count_limit>0 ) {
			cout << "GYM command limit achieved.\n";
			return -1;
		}
		switch(c) {
			case 0: 
				wait = 735; // 16.7ms
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
			case 2:	{
				char buf[2];
				file.read(buf,2);
				cmd = buf[0];
				val = buf[1];
				addr = (c == 2); // if c==2 then write to top bank of JT12
				return 0;
			}
			default:
				cerr << "Wrong code ( " << ((int)c) << ") in GYM file\n";
				continue;
		}
	}while(file.good());
	// cout << "Done\n";
	return -1;
}
