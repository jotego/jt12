#include <iostream>

using namespace std;

void VGMParser::open(const char* filename, int limit=-1) {
	file.open(filename,ios_base::binary);	
	if ( !file.good() ) cout << "Failed to open file: " << filename << '\n';
	cout << "Open " << filename << '\n';
	cmd = val = addr = 0;
	// max_PSG_warning = 10;
}

int VGMParser::parse() {
	while( !file.eof() && file.good() ) {
		char vgm_cmd;
		file.read( &vgm_cmd, 1);
		if( !file.good() ) return -1; // finish immediately
		char extra[2];
		switch( vgm_cmd ) {
			case 0x52:
				addr = 0;
				file.read( extra, 2);
				cmd = extra[0];
				val = extra[1];
				return 0;
			case 0x53:
				addr = 1;
				file.read( extra, 2);
				cmd = extra[0];
				val = extra[1];
				return 0;
			case 0x61:
				file.read( extra, 2);
				wait = extra[0] | ( extra[1]<<8);
				return 1; // request wait
			case 0x62:
				wait = 735;
				return 1; // wait one frame (NTSC)
			case 0x63:
				wait = 882; // wait one frame (PAL)
				return 1;
			case 0x66:
				return -1; // finish
			default:
				cout << "ERROR: Unsupported VGM command 0x" << hex << (((int)vgm_cmd)&0xff) << '\n';
				return -1;
		}
	}
	return -1;
}