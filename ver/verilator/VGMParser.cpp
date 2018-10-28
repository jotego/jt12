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

JTTParser::JTTParser(int c) : RipParser(c) {
	op_commands["dt"] = 0x30;
	op_commands["mul"] = 0x30;
	op_commands["tl"] = 0x40;
	op_commands["ar"] = 0x50;
	op_commands["ks"] = 0x50;
	op_commands["dr"] = 0x60;
	op_commands["amon"] = 0x60;
	op_commands["sr"] = 0x70;
	op_commands["sl"] = 0x80;
	op_commands["rr"] = 0x80;
	op_commands["ssg-eg"] = 0x90;
	op_commands["ssg"] = 0x90;
	ch_commands["fnum"] = 0xa0;
	ch_commands["fnum_lsb"] = 0xa0;
	ch_commands["block"] = 0xa4;
	ch_commands["blk_fnum"] = 0xa4;
	ch_commands["fnum_msb"] = 0xa4;
	ch_commands["fb"] = 0xb0;
	ch_commands["alg"] = 0xb0;
	ch_commands["conn"] = 0xb0;
	ch_commands["lr"] = 0xb4;
	ch_commands["ams"] = 0xb4;
	ch_commands["pms"] = 0xb4;
	global_commands["kon"] = 0x28;
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
				cout << "Wait for " << wait << '\n';
				return cmd_wait;
			}

			auto op_cmd = op_commands.find(txt_cmd);
			if( op_cmd != op_commands.end() ) {
				cmd_base = op_cmd->second;
				parse_opdata(txt_arg, cmd_base);
				return cmd_write;
			}

			auto ch_cmd = ch_commands.find(txt_cmd);
			if( ch_cmd != ch_commands.end() ) {
				cmd_base = ch_cmd->second;
				parse_chdata(txt_arg, cmd_base);
				return cmd_write;
			}

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
	else {
		int32_t start;
		file.seekg(0x34);
		file.read( (char*)&start, 4 );
		start+=0x34;
		file.seekg(start);
	}
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
				return cmd_write;
			case 0x53: // A1=1
			case 0x57:
				addr = 1;
				file.read( extra, 2);
				cmd = extra[0];
				val = extra[1];
				return cmd_write;
			case 0x61:
				file.read( extra, 2);
				wait = extra[0];
				wait <<= 8;
				wait |= extra[1];
				wait&=0xffff;
				adjust_wait();
				return cmd_wait; // request wait
			case 0x62:
				wait = 735;
				adjust_wait();
				return cmd_wait; // wait one frame (NTSC)
			case 0x63:
				wait = 882; // wait one frame (PAL)
				adjust_wait();				
				return cmd_wait;
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
			case 2:	{
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