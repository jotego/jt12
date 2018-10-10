#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <string>
#include <cstdlib>
#include <cstring>

using namespace std;

int cont=0;

string reg2str(unsigned r) {
	switch(r) {
		case 0x21: return "TEST";
		case 0x22: return "LFO";
		case 0x24: return "TIMER A, MSB";
		case 0x25: return "TIMER A, LSB";
		case 0x26: return "TIMER B";
		case 0x27: return "TIMER CTRL";
		case 0x28: return "KEY ON/OFF";
		case 0x29: return "SCH / IRQ ENABLE";
		case 0x2D: return "BURISU";
		case 0x2E: return "CLOCK DIVIDER 1/3, 1/6";
		case 0x2F: return "CLOCK DIVIDER 1/2";
		
		case 0x30: return "DT/MULT";
		case 0x31: return "DT/MULT";
		case 0x32: return "DT/MULT";

		case 0x34: return "DT/MULT";
		case 0x35: return "DT/MULT";
		case 0x36: return "DT/MULT";

		case 0x38: return "DT/MULT";
		case 0x39: return "DT/MULT";
		case 0x3A: return "DT/MULT";

		case 0x3C: return "DT/MULT";
		case 0x3D: return "DT/MULT";
		case 0x3E: return "DT/MULT";

		case 0x40: return "TL";
		case 0x41: return "TL";
		case 0x42: return "TL";

		case 0x44: return "TL";
		case 0x45: return "TL";
		case 0x46: return "TL";

		case 0x48: return "TL";
		case 0x49: return "TL";
		case 0x4A: return "TL";

		case 0x4C: return "TL";
		case 0x4D: return "TL";
		case 0x4E: return "TL";

		case 0x50: return "AR/KS";
		case 0x51: return "AR/KS";
		case 0x52: return "AR/KS";

		case 0x54: return "AR/KS";
		case 0x55: return "AR/KS";
		case 0x56: return "AR/KS";

		case 0x58: return "AR/KS";
		case 0x59: return "AR/KS";
		case 0x5A: return "AR/KS";

		case 0x5C: return "AR/KS";
		case 0x5D: return "AR/KS";
		case 0x5E: return "AR/KS";

		case 0x60: return "AMON/DR";
		case 0x61: return "AMON/DR";
		case 0x62: return "AMON/DR";

		case 0x64: return "AMON/DR";
		case 0x65: return "AMON/DR";
		case 0x66: return "AMON/DR";

		case 0x68: return "AMON/DR";
		case 0x69: return "AMON/DR";
		case 0x6A: return "AMON/DR";

		case 0x6C: return "AMON/DR";
		case 0x6D: return "AMON/DR";
		case 0x6E: return "AMON/DR";

		case 0x70: return "SR";
		case 0x71: return "SR";
		case 0x72: return "SR";

		case 0x74: return "SR";
		case 0x75: return "SR";
		case 0x76: return "SR";

		case 0x78: return "SR";
		case 0x79: return "SR";
		case 0x7A: return "SR";

		case 0x7C: return "SR";
		case 0x7D: return "SR";
		case 0x7E: return "SR";

		case 0x80: return "SL/RR";
		case 0x81: return "SL/RR";
		case 0x82: return "SL/RR";

		case 0x84: return "SL/RR";
		case 0x85: return "SL/RR";
		case 0x86: return "SL/RR";

		case 0x88: return "SL/RR";
		case 0x89: return "SL/RR";
		case 0x8A: return "SL/RR";

		case 0x8C: return "SL/RR";
		case 0x8D: return "SL/RR";
		case 0x8E: return "SL/RR";

		case 0x90: return "SSG-EG";
		case 0x91: return "SSG-EG";
		case 0x92: return "SSG-EG";

		case 0x94: return "SSG-EG";
		case 0x95: return "SSG-EG";
		case 0x96: return "SSG-EG";

		case 0x98: return "SSG-EG";
		case 0x99: return "SSG-EG";
		case 0x9A: return "SSG-EG";

		case 0x9C: return "SSG-EG";
		case 0x9D: return "SSG-EG";
		case 0x9E: return "SSG-EG";

		case 0xA0: return "F-NUM 1";
		case 0xA1: return "F-NUM 1";
		case 0xA2: return "F-NUM 1";

		case 0xA4: return "BLOCK/F-NUM 2";
		case 0xA5: return "BLOCK/F-NUM 2";
		case 0xA6: return "BLOCK/F-NUM 2";

		case 0xA8: return "3 CH F-NUM";
		case 0xA9: return "3 CH F-NUM";
		case 0xAA: return "3 CH F-NUM";

		case 0xAC: return "3 CH BLOCK/ F-NUM";
		case 0xAD: return "3 CH BLOCK/ F-NUM";
		case 0xAE: return "3 CH BLOCK/ F-NUM";

		case 0xB0: return "FB/CONNECT";
		case 0xB1: return "F-NUM 1";
		case 0xB2: return "F-NUM 1";

		case 0xB4: return "LR/AMS/PMS";
		case 0xB5: return "LR/AMS/PMS";
		case 0xB6: return "LR/AMS/PMS";				
	}
	return "BAD REGISTER";
}

void write( unsigned chnum, unsigned reg, unsigned val, bool addr1=false ) {
	cout << "cfg[" << dec << cont++ << "] = { 1'b";
    if( addr1 )
    	cout << '1';
    else {
        if( chnum < 3 )
	        cout << '0';
        else
	        cout << '1';
    }
	cout <<", 8'h" << hex << ((reg+(chnum&3))&0xff) << ", 8'h" << (val&0xff) << "};\t // ";
	cout << reg2str(reg) << '\n';
	cout << dec;
}

void wait( float ms ) {
	int x = ms/8.5*255.0;
	cout << "// Wait for " << ms << "ms\n";
	for( int k=0; k<(x/255); k++ )
		write( 0, 1, 255 );
	write( 0, 1, x%255 );
}

void parse_gym( char *filename ) {
	ifstream file(filename,ios_base::binary);
	cerr << "Parsing GYM file " << filename << endl;
	// int max=400;
	while( !file.eof() /*&& --max */ ) {
		char c;
		file.read( &c, 1);
		switch(c) {
			case 0: 
				wait(17); // should be 16.7ms
				continue;
			case 3: {
				file.read(&c,1);
				unsigned p = (unsigned char)c;
				cerr << "Attempt to write to PSG port " << p << endl;
				continue;
			}
			case 1:
			case 2:	{
				char buf[2];
				file.read(buf,2);
				write( 0, buf[0], buf[1], c==2 /* addr1? */);
				continue;				
			}
			default:
				cerr << "Wrong code ( " << ((int)c) << ") in GYM file\n";
				return;
		}
	}
}

void write_allop(  int chnum, int reg, int val ) {
	for( int k=0; k<4; k++ )
		write( chnum, reg + (k<<2), val );
}

struct Op {
private:
	int reg_offset() {
		int a;
		switch( opnum ) {
			case 0: a=0; break;
			case 1: a=2; break;
			case 2: a=1; break;
			case 3: a=3; break;
		}
		a <<= 2;
		return a;
	}
public:
	int opnum, chnum;
	int kon;
	int dt, mul, tl, ks, ar, am, dr, sr, sl, rr, ssgen, ssg;
	void writecfg() {
		int a=reg_offset();
		write( chnum, 0x30+a, (dt<<4)| mul );
		write( chnum, 0x40+a, tl );
		write( chnum, 0x50+a, (ks<<6)| ar );
		// anyadir AM
		write( chnum, 0x60+a, dr );
		write( chnum, 0x70+a, sr );
		write( chnum, 0x80+a, (sl<<4)| rr );
		write( chnum, 0x90+a, (ssgen<<3)| ssg );
	}
	void set_dt( int a ) {
		dt = a;
		cout << "// DT= " << a << '\n';
		write( chnum, 0x30+reg_offset(), (dt<<4)| mul );
	}
	void set_mul( int a ) {
		mul = a;
		cout << "// MUL= " << a << '\n';
		write( chnum, 0x30+reg_offset(), (dt<<4)| mul );
	}
	void set_tl( int a ) {
		tl = a;
		write( chnum, 0x40+reg_offset(), a );
	}
	void set_sl( int a ) {
		sl = a;
		write( chnum, 0x80+reg_offset(), (sl<<4)| rr );
	}
	void set_ks( int a ) {
		ks = a;
		write( chnum, 0x50+reg_offset(), (ks<<6)| ar );
	}
	void set_ar( int a ) {
		ar = a;
		write( chnum, 0x50+reg_offset(), (ks<<6)| ar );
	}
	void set_sr( int a ) {
		sr = a;
		write( chnum, 0x70+reg_offset(), a );
	}
	void set_rr( int a ) {
		rr = a;
		write( chnum, 0x80+reg_offset(), (sl<<4)| rr );
	}
	void set_dr( int a ) {
		dr = a;
		write( chnum, 0x60+reg_offset(), a );
	}
	void set_ssg( int a  ) {
		ssg = a;
		write( chnum, 0x90+reg_offset(), (ssgen<<3)| ssg );
	}
	void set_ssg4( int a  ) {
		ssg = a&7;
		ssgen=(a>>3)&1;
		write( chnum, 0x90+reg_offset(), (ssgen<<3)| ssg );
	}

	Op() { kon=0; }
};

struct Ch {
	int chnum;
	int fnum, block;
	int fb, alg, rl, ams, pms;
	Op op[4];

	void writecfg() {
		write( chnum, 0xa4, (block<<3) | (fnum>>8) );
		write( chnum, 0xa0, fnum&0xff );
		write( chnum, 0xb0, (fb<<3) | (alg&7) );
		write( chnum, 0xb4, (rl<<6) | (ams<<3) | pms );
		for( int k=0; k<4; k++ )
			op[k].writecfg();
	}
	void set_alg( int a ) {
		alg = a;
		write( chnum, 0xb0, (fb<<3) | (alg&7) );
	}
	void set_fb( int a ) {
		fb = a;
		write( chnum, 0xb0, (fb<<3) | (alg&7) );
	}
	void set_block( int a ) {
		block = a;
		write( chnum, 0xa4, (block<<3) | (fnum>>8) );
		write( chnum, 0xa0, fnum&0xff );
	}
	void set_fnumber( int a ) {
		fnum = a;
		write( chnum, 0xa4, (block<<3) | (fnum>>8) );
		write( chnum, 0xa0, fnum&0xff );
	}
	void set_rl( int a ) {
		rl = a;
		write( chnum, 0xb4, (rl<<6) | (ams<<3) | pms );
	}
	void keyon( int x ) {
		op[0].kon = x&1;
		op[1].kon = x&2?1:0;
		op[2].kon = x&4?1:0;
		op[3].kon = x&8?1:0;
		//cout << "// keyon for chnum=" << chnum << '\n';
		write(  0, 0x28, (x<<4) | (chnum) );
	}
};

void dump( ofstream& of, Ch ch[6] ) {
 /* format in Verilog file:
		"%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t",
		block_ch0s1, fnum_ch0s1, rl_ch0s1, fb_ch0s1, alg_ch0s1,
		dt1_ch0s1, mul_ch0s1, tl_ch0s1, ar_ch0s1, d1r_ch0s1,
		d2r_ch0s1, rr_ch0s1, d1l_ch0s1, ks_ch0s1, ssg_ch0s1 );
		*/
	of << hex;
	of << "-------------------------------\n";
	for( int c=0; c<6; c++ )
	for( int o=0; o<4; o++ )
	{
		of << ch[c].block << ' ' ;
		of << setfill('0') << setw(3);
		of << ch[c].fnum  << ' ' ;
		of << ch[c].rl    << ' ' ;
		of << ch[c].fb    << ' ' ;
		of << ch[c].alg   << ", ";

		of << ch[c].op[o].dt  << ' ' ;
		of << ch[c].op[o].mul << ' ' ;

		of << setfill('0') << setw(2);
		of << setw(2) << ch[c].op[o].tl  << ' ' ;
		of << setw(2) << ch[c].op[o].ar  << ' ' ;
		of << setw(2) << ch[c].op[o].dr  << ' ' ;
		of << setw(2) << ch[c].op[o].sr  << ", ";

		of << setw(1);
		of << ch[c].op[o].rr  << ' ' ;
		of << ch[c].op[o].sl  << ' ' ;
		of << ch[c].op[o].ks  << ' ' ;
		of << ch[c].op[o].ssg << ' ' ;
		of << ch[c].op[o].kon;
		of << '\n';
	}
}

void keyoff_all( Ch ch[6] ) {
	for( int k=0; k<6; k++ ) {
		for( int j=0; j<4; j++ ) ch[k].op[j].kon = 0;
		int e = k>2 ? 1:0;
		write(  0, 0x28, k+e );
	}
}

void initial_clear( Ch ch[6] ) {
	for( int k=0, slot=0; k<6; k++ ) {
		if( k<3  ) ch[k].chnum=k;
		if( k>=3 ) ch[k].chnum=k+1;
		ch[k].fnum = 1024;
		ch[k].block= 4;
		ch[k].rl = 3;
		ch[k].ams = 0;
		ch[k].pms = 0;
		ch[k].fb  = 0; //ch[k].chnum;
		ch[k].alg = 7;
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].opnum = j;
			ch[k].op[j].chnum = ch[k].chnum;
			ch[k].op[j].dt = 0;
			ch[k].op[j].mul= 1;
			ch[k].op[j].tl = 127;
			ch[k].op[j].ks = 0;
			ch[k].op[j].ar = 31;
			ch[k].op[j].am = 0;
			ch[k].op[j].dr = 0; //ch[k].chnum+j*6-(ch[k].chnum>3?1:0);
			ch[k].op[j].sr = 0;
			ch[k].op[j].sl = 10;
			ch[k].op[j].rr = 15;
			ch[k].op[j].ssgen = 0;
			ch[k].op[j].ssg = 0;
			slot++;
		}
	}
	for( int k=0; k<6; k++ ) {
		ch[k].writecfg();
	}
	// Key on
	for( int k=0; k<6; k++ ) {
		int e = k>2 ? 1:0;
		write(  0, 0x28, 0xf0 | (k+e) );
	}
	wait(2);
	keyoff_all(ch);
	wait(12);
	cout << "// Initial clear done\n";
}

void keyon( Ch ch[], int c, int op ) {
	ch[c].keyon(op);
}

void lfo_check() {
	cout << "\n// LFO check\n";
	write( 0, 0x22, 0xf ); // 72.2 Hz
	wait( 80 );

	write( 0, 0x22, 8 | 6 ); // 48.1 Hz
	wait( 80 );	
}

void alg_single_test( Ch ch[6], int alg ) {
	cout << "\n\n// Starting ALG="<<alg <<endl;
	keyoff_all(ch);
	wait(1);
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(alg);
		ch[k].op[0].set_tl(20);
		ch[k].op[0].set_dr(0);
		ch[k].set_fb(5);
		for( int j=1; j<4; j++ ) {
			ch[k].op[j].set_tl( 0 );
		}
	}
	for( int k=0; k<6; k++ )
		ch[k].keyon( 0xf );
	wait(10);
}

void alg_test( Ch ch[6], int mask, int fb_max ) {
	initial_clear( ch );
	// ALG = 7
	if (mask&0x80) {
	cout << "\n\n// Starting ALG=7"<<endl;
	for( int fb=0; fb<fb_max; fb++ ) {
		cout << "//\tFB="<<fb<<endl;
		for( int k=0; k<6; k++ ) {
			ch[k].set_alg(7);
			ch[k].set_fb(fb);
			ch[k].op[0].set_dr(0);
			ch[k].set_rl(3);
		}
		for( int k=0; k<6; k++ ) {
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_tl( 16 );
			ch[k].op[j].set_rr( 15 );
			ch[k].keyon( 1<<j );
			write( 0, 0x01, 64 ); // wait
			}
			keyoff_all(ch);
		}
		for( int k=0; k<6; k++ ) ch[k].keyon( 0xf );
		wait(10);
		keyoff_all(ch);
	}
	}
	// ALG = 6
	for( int m=6; m>=0; m-- )
		if (mask&(1<<m)) alg_single_test( ch, m );

}

void ssg_test( Ch ch[6] ) {
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(0);
	}
	ch[0].set_rl(1);
	ch[1].set_rl(2);
	int ssg=0;
	for( int j=0; j<4; j++ ) {
	for( int k=0; k<2; k++, ssg++ ) {
			ch[k].op[j].ssgen = 1;
			ch[k].op[j].set_ssg( ssg%8 );
			ch[k].op[j].set_mul( 1 );
			ch[k].op[j].set_tl( 12 );
			ch[k].op[j].set_sr( 20 ); //  25
			ch[k].op[j].set_dr( 24 ); // 28
			ch[k].keyon( 1<<j );
		}
		for( int wait=0; wait<5; wait++ )
			write( 0, 0x01, 255 ); // wait
		keyoff_all(ch);
	}

	/*
	for( int k=0; k<6; k++ )
	for( int j=0; j<4; j++, ssg++ ) {
		ch[k].op[j].ssgen = 0;
        ch[k].op[j].set_ssg(0);
	}*/
}

void tone00( Ch ch[6] ) {
	initial_clear( ch );
	wait(5);
	ch[0].op[0].set_sl(15);
	ch[0].set_alg(7);
	ch[0].keyon( 15 );
    ch[0].set_rl(3);
	ch[0].keyon( 0 );
    ch[0].set_block(4);
    ch[0].set_fnumber(512);

    Op& op = ch[0].op[0];
	op.set_tl( 0 );
    op.set_ar( 31 );
    op.set_dr( 0 );
	ch[0].keyon( 1 );
    wait( 12 );
    ch[0].set_rl(1);
    wait( 12 );
    ch[0].set_rl(2);
	wait( 12 );
}

void fnum_check( Ch ch[6] ) {
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(3);
		ch[k].set_block(k+1);
		ch[k].set_fnumber(734);
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_tl( 0 );
			ch[k].op[j].set_dr( 0 );
		}
	}
	for( int k=0; k<6; k++ ) {
		ch[k].keyon( 0xf );
	}
	for( int wait=0; wait<17; wait++ )
		write( 0, 0x01, 255 ); // wait
	keyoff_all(ch);
	ofstream of("fnum_check.log");
	dump( of, ch );
}

void pcm_check( Ch ch[6] ) {
	cerr << "PCM check. 1m20s run time.\n";
	cerr << "It will enable all operators and then PCM output\n";
	cerr << "Check that channel 6 is being replaced by PCM samples\n";
	cerr << "As RL settings go from 0 to 3, output should be checked\n";
	cerr << "on both channels\n";
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].keyon( 15 );
		ch[k].keyon( 0 );
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_ar(0);
			ch[k].op[j].set_sl(0);
			ch[k].op[j].set_sr(0);
			ch[k].op[j].set_dr(0);
			ch[k].op[j].set_tl( k==5? 0 : 127 );
		}
		ch[k].keyon( 15 );
	}
	for( int wait=0; wait<2; wait++ )
		write( 0, 0x01, 255 ); // wait
	// Output PCM
	write( 0, 0x2B, 0x80 );
	for( int rl=0,k=0; rl<4; rl++ ) {
		ch[5].set_rl(rl);
		for( int j=0; j<64; j++ ) {
			write( 0, 0x2A, k );
			write( 0, 0x01, 5 ); // wait
			k+=2;
		}
	}
}

void timer_test() {
	write( 0, 0x26, 120 );
	write( 0, 0x25, 0 );
	write( 0, 0x24, 150 );
	write( 0, 0x27, 0x5 );
	for( int wait=0; wait<4; wait++ )
		write( 0, 0x01, 255 ); // wait
	write( 0, 0x27, 0x2 | (3<<2) | (3<<4) );
	for( int wait=0; wait<4; wait++ )
		write( 0, 0x01, 255 ); // wait
}

void ch3effect_test( Ch ch[6] ) {
	write( 0, 0x27, 0x40 ); // Effect mode
	// block
	write( 0, 0xAD, (0<<3) | 0 );
	write( 0, 0xAC, (1<<3) | 1 );
	write( 0, 0xAE, (2<<3) | 2 );
	write( 0, 0xA6, (3<<3) | 3 );

	write( 0, 0xA9, 0x10 );
	write( 0, 0xA8, 0x20 );
	write( 0, 0xAA, 0x30 );
	write( 0, 0xA2, 0x40 );
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(3);
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_tl( 0 );
			ch[k].op[j].set_dr( 0 );
		}
	}
	for( int k=0; k<6; k++ ) {
		ch[k].keyon( 0xf );
	}
	for( int wait=0; wait<2; wait++ )
		write( 0, 0x01, 255 ); // wait
	keyoff_all(ch);
}

void csm_test(Ch ch[6]) {
	cerr << "CSM test\n";
	initial_clear( ch );
	ch[2].set_alg(7);
	ch[2].set_fb(0);
	ch[2].set_fnumber(925);
	ch[2].set_block(4);
	ch[2].set_rl(3);
	for( int j=0; j<4; j++ ) {
		ch[2].op[j].set_tl( 0 );
		ch[2].op[j].set_dr( 0 );
		ch[2].op[j].set_rr( 15 );
		ch[2].op[j].set_mul(1);
	}
	unsigned faux = 925&0xff;
	unsigned baux = (4<<3)|(925>>8);
	write( 0, 0xad, baux );
	write( 0, 0xac, baux );
	write( 0, 0xae, baux );
	write( 0, 0xa6, baux );
	write( 0, 0xa9, faux );
	write( 0, 0xa8, faux );
	write( 0, 0xaa, faux );
	write( 0, 0xa2, faux );

	write( 0, 0x24, 200 );
	write( 0, 0x25, 0 );
	write( 0, 0x27, 0xb5 ); // CSM
	wait( 40 );
	//keyoff_all(ch);
}

void maxtl_test(Ch ch[6]) {
	cerr << "Dynamic range test\n";
	//initial_clear( ch );
	write( 0, 0x21, 1<<3 ); // PG stop
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(0);
		ch[k].set_fnumber(925);
		ch[k].set_block(3);
		ch[k].set_rl(3);
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_tl( 0 );
			ch[k].op[j].set_ar( 31 );
			ch[k].op[j].set_sr( 0 );
			ch[k].op[j].set_dr( 0 );
			ch[k].op[j].set_rr( 15 );
			ch[k].op[j].set_mul(1);
			ch[k].op[j].set_ssg4(0);
		}
		ch[k].keyon(0xf);
	}
	write( 0, 0x21, 0<<3 ); // PG on
	wait( 30 );
}

void dr_test(Ch ch[6]) {
	cerr << "Dynamic range test\n";
	//initial_clear( ch );
	write( 0, 0x21, 1<<3 ); // PG stop
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(0);
		ch[k].set_fnumber(925);
		ch[k].set_block(3);
		ch[k].set_rl(3);
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_tl( j==0 ? 0 : 127);
			ch[k].op[j].set_ar( 31 );
			ch[k].op[j].set_sr( 0 );
			ch[k].op[j].set_dr( 0 );
			ch[k].op[j].set_rr( 15 );
			ch[k].op[j].set_mul(1);
			ch[k].op[j].set_ssg4(0);
		}
		ch[k].keyon(0xf);
	}
	write( 0, 0x21, 0<<3 ); // PG on
	wait( 10 );
	for( int k=0; k<5; k++ ) {
		ch[k].op[0].set_tl(127);
//		wait( 6 );
	}
	write( 0, 0x21, 1<<3 ); // PG stop
	for( int k=0; k<64; k+=2 ) {
		ch[5].op[0].set_tl(k);
		wait( 1 );
	}
	wait(2);
}

void gng2( Ch *ch ) {
    int patch_00[] = {
0x02, 0x01, 0x31, 0x00, 0x02, 0x01, 0x32, 0x00, 0x02, 0x01, 0x39, 0x00, 0x01, 0x01, 0x34, 0x00, // 30
0x25, 0x1B, 0X13, 0X00, 0X1B, 0x1b, 0x25, 0x00, 0x1b, 0x39, 0x1b, 0x00, 0x17, 0x19, 0x18, 0x00, // 40
0x1f, 0x1f, 0xd9, 0x00, 0x11, 0x1f, 0x56, 0x00, 0x17, 0x1f, 0xdc, 0x00, 0x10, 0x1f, 0x54, 0x00, // 50
0x80, 0x87, 0x8b, 0x00, 0x80, 0x80, 0x80, 0x00, 0x80, 0x87, 0x8c, 0x00, 0x82, 0x82, 0x86, 0x00, // 60
0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x01, 0x0c, 0x00, 0x01, 0x00, 0x00, 0x00, // 70
0x03, 0x0d, 0x13, 0x00, 0x03, 0x0d, 0x1b, 0x00, 0x03, 0x0d, 0x5b, 0x00, 0x38, 0x0f, 0x0b, 0x00, // 80
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // 90
};

	int patch_10[] = {
0x01, 0x02, 0x31, 0x00, 0x01, 0x02, 0x32, 0x00, 0x01, 0x02, 0x39, 0x00, 0x01, 0x01, 0x34, 0x00, // 30
0x1B, 0x25, 0X13, 0X00, 0X1B, 0x1b, 0x25, 0x00, 0x39, 0x1B, 0x1b, 0x00, 0x18, 0x16, 0x1C, 0x00, // 40
0x1F, 0x1f, 0xd9, 0x00, 0x1F, 0x11, 0x56, 0x00, 0x1F, 0x17, 0xdc, 0x00, 0x1F, 0x10, 0x54, 0x00, // 50
0x87, 0x80, 0x8b, 0x00, 0x80, 0x80, 0x80, 0x00, 0x87, 0x80, 0x8c, 0x00, 0x82, 0x82, 0x86, 0x00, // 60
0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x01, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, // 70
0x0D, 0x03, 0x13, 0x00, 0x0D, 0x03, 0x1b, 0x00, 0x0D, 0x03, 0x5b, 0x00, 0x0F, 0x0f, 0x0b, 0x00, // 80
0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // 90
};

	for( int k=0; k<0x70; k++ ) {
    	write( 0, 0x30+k, patch_00[k] );
        write( 0, 0x30+k, patch_10[k], true );
    }

    int patch_freq_00[] = {
    	0xdd, 0x9c, 0x4b, 0x00,
        0x2a, 0x1b, 0x1c, 0x00,
        0x38, 0x2a, 0x2a, 0x00,
        0xc0, 0xc0, 0xc0, 00 };
    int patch_freq_10[] = {
    	0xdd, 0xdd, 0x4b, 0x00,
        0x1a, 0x2a, 0x1c, 0x00,
        0x2a, 0x38, 0x2a, 0x00,
        0xc0, 0xc0, 0xc0, 0x00 };
     for( int k=0; k<8; k++ ) {
     	write( 0, 0xA0+k, patch_freq_00[k] );
        write( 0, 0xA0+k, patch_freq_10[k], true );
        write( 0, 0xB0+k, patch_freq_00[k+8] );
        write( 0, 0xB0+k, patch_freq_10[k+8], true );
     }

     for( int k=0; k<6; k++ ) {
     	ch[k].keyon( 0xf );
		for( int wait=0; wait<25; wait++ )
			write( 0, 0x01, 255 ); // wait
        keyoff_all(ch);
        write( 0, 0x01, 55 ); // wait
     }
}

void test_bin( Ch ch[6] ) {
    unsigned char ymregs[] = {
        0x30, 1,
        0x40, 0,
        0x50, 0x1f,
        0x60, 0,
        0x70, 0,
        0x80, 0,
        0x90, 0,

        0x34, 1,
        0x44, 0,
        0x54, 0x1f,
        0x64, 0,
        0x74, 0,
        0x84, 0,
        0x94, 0,

        0x38, 1,
        0x48, 0,
        0x58, 0x1f,
        0x68, 0,
        0x78, 0,
        0x88, 0,
        0x98, 0,

        0xa4, 4<<3,
        0xa0, 0xff,
        0xb0, 7,
        0xb4, 0xc0,

        0x28, 0xf0
    };
    int k;
    // YM2612_reset();
    for ( k=0; k<sizeof(ymregs); k+=2 ) {
        write( 0, ymregs[k], ymregs[k+1]);
    }

	for( int wait=0; wait<2; wait++ )
		write( 0, 0x01, 255 ); // wait
}

void timerb( Ch ch[6] ) {
	write( 0, 0x21, 4 ); // fast timers
    for( int k=105; k<255; k+=10 ) {
    	write( 0, 0x26, k );
        write( 0, 0x27, 0x2a );
        write( 0, 3, 3 );
        write( 0, 1, 10 );
    }
}

void keyon_simple( Ch ch[6] ) {
	for( int k=0; k<6; k++ )
	for( int j=0; j<4; j++ ) {
		ch[k].op[j].set_tl(0);
		ch[k].op[j].set_ar(31);
		ch[k].op[j].set_dr(0);
		ch[k].op[j].set_sr(0);
	}
	write( 0, 1, 20 );
	cerr << "Primero todos por orden\n";
	for( int k=0; k<6; k++ )
	for( int j=0; j<4; j++ ) {
		ch[k].op[j].set_tl(0);
		ch[k].keyon( 1<<j );
		write( 0, 1, 20 );
	}
	cerr << "Luego los apago todos\n";
	keyoff_all(ch);
	write( 0, 1, 200 );
	cerr << "Y ahora los enciendo aleatoriamente\n";
	srand(0);
	for( int k=0; k<30; k++ ) {
		int opmask = rand()%16;
		int chnum = rand()%6;
		cerr << "Canal " << chnum << " -> ";
		if ( opmask&1 ) cerr << "1"; else cerr << " ";
		if ( opmask&2 ) cerr << "2"; else cerr << " ";
		if ( opmask&4 ) cerr << "3"; else cerr << " ";
		if ( opmask&8 ) cerr << "4"; else cerr << " ";
		cerr << endl;
		if( chnum>2) chnum++;
		write( 0, 0x28, (opmask<<4)|chnum );
		write( 0, 1, 200 );
	}
}

void keyon_doble( Ch ch[6] ) {
	cerr << "Prueba de keyon doble:\nEl keyon debe ignorarse en fases que no sean RELEASE\n";
    cerr << "En la primera onda hay un keyon antes de RELEASE, ha de ignorarse\n";
    cerr << "En la segunda onda se comprueba que el keyon ha reseteado la fase\n";
    cerr << "En la tercera onda hay otra vez keyon antes de RELEASE, pero con AR=31\n";
    cerr << "En la cuarta onda, hay keyon y enseguida keyoff para entrar en RELEASE\n"
    	<<  "pero el RELEASE es muy lento. Entra un keyon durante el RELEASE y debe\n"
        <<  "aceptarse, con reseteo de fase y amplitud a tope porque AR=31\n"
        <<  "Tarda unos 5 minutos en correr\n";
	write( 0, 0x40, 0 );
	write( 0, 0x50, 18);
	write( 0, 0xa4, 0xf );
	write( 0, 0xb0, 7 );
	write( 0, 0xb4, 0xc0 );
	write( 0, 0x60, 18 );
	write( 0, 0x70, 18 );
	write( 0, 0x80, 0x4f );
	write( 0, 0x28, 0x10 );
	for( int wait=0; wait<3; wait++ )
		write( 0, 0x01, 255 ); // wait
	write( 0, 0x28, 0x10 );
	for( int wait=0; wait<3; wait++ )
		write( 0, 0x01, 255 ); // wait
	// Release
	write( 0, 0x28, 0 );
	for( int wait=0; wait<3; wait++ )
		write( 0, 0x01, 255 ); // wait
	write( 0, 0x28, 0x10 );
	for( int wait=0; wait<3; wait++ )
		write( 0, 0x01, 255 ); // wait
	// AR=31
	write( 0, 0x28, 0 );
	for( int wait=0; wait<3; wait++ )
		write( 0, 0x01, 255 ); // wait
	write( 0, 0x50, 31);
	write( 0, 0x28, 0x10 ); // primer keyon
	for( int wait=0; wait<3; wait++ )
		write( 0, 0x01, 255 ); // wait
	write( 0, 0x28, 0x10 ); // segundo keyon
	for( int wait=0; wait<3; wait++ )
		write( 0, 0x01, 255 ); // wait
	write( 0, 0x28, 0 );
    write( 0, 0x01, 255 ); // espera
    // Release largo
    write( 0, 0x60, 0 ); // DR
    write( 0, 0x70, 0 ); // SR
    write( 0, 0x80, 0x0 ); // RR
    write( 0, 0x28, 0x10 );
    write( 0, 0x01, 255 ); // espera
	write( 0, 0x28, 0 );
    write( 0, 0x01, 255 ); // espera
    write( 0, 0x28, 0x10 ); // Segundo keyon, deberiamos estar en release
	for( int wait=0; wait<3; wait++ )
		write( 0, 0x01, 255 ); // wait
	write( 0, 0x28, 0 );
	write( 0, 0x01, 255 ); // espera
}

void dr_check( Ch ch[6] ) {
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(0);
		ch[k].set_rl(3);
	}
	for( int k=0; k<6; k++ ) {
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_tl( 0 );
			ch[k].op[j].set_sr(0);
			ch[k].op[j].set_ar(31);
			ch[k].op[j].set_dr(0);
		}
		ch[k].keyon( 15 );
		write( 0, 0x01, 55 ); // wait
	}
	for( int wait=0; wait<1; wait++ )
		write( 0, 0x01, 255 ); // wait for 8.5ms
}

void amfreq_test( Ch ch[6] ) {
	cerr << "AM Frequency test\n";
	for( int lfo_freq=0; lfo_freq<8; lfo_freq++ ) {
		write(	0, 0x22, 0 );
		write(	0, 0x22, 8 | lfo_freq );
		for( int wait=0; wait<29; wait++ )
			write( 0, 0x01, 255 ); // wait for 8.5ms
	}
}

void am_test( Ch ch[6] ) {
	//write(	0, 0x22, 0x80 | lfo_freq );
	for( int wait=0; wait<1; wait++ )
		write( 0, 0x01, 255 ); // wait for 8.5ms
}

void fnumorder_test( Ch ch[6] ) {
	// block / Fnum hi
	write( 0, 0xa4, (1<<3) | 1 );
	write( 0, 0xa5, (2<<3) | 2 );
	write( 0, 0xa6, (3<<3) | 3 );

	write( 0, 0xa4, (4<<3) | 4, true );
	write( 0, 0xa5, (5<<3) | 5, true );
	write( 0, 0xa6, (6<<3) | 6, true );

	write( 0, 0xad, (1<<3) | 1 );
	write( 0, 0xae, (2<<3) | 2 );
	write( 0, 0xac, (3<<3) | 3 );
	// fnum lo
	write( 0, 0xa0, 1 );
	write( 0, 0xa1, 2 );
	write( 0, 0xa2, 3 );

	write( 0, 0xa0, 4, true );
	write( 0, 0xa1, 5, true );
	write( 0, 0xa2, 6, true );

	write( 0, 0xa9, 1 );
	write( 0, 0xaa, 2 );
	write( 0, 0xa8, 3 );
	write( 0, 0x01, 50 );
}

void acc_test( Ch ch[6] ) {
	initial_clear( ch );
	cerr << "Prueba del acumulador\n"
		<< "Al principio salen por orden cada operador al maximo\n"
		<< "Deberia causar salidas erroneas por desborde\n"
		<< "Luego corrijo el volumen para que salga bien\n";
	write( 0, 0xa4, (3<<3) | 3 );
	write( 0, 0xa0, 0xf0 );
	write( 0, 0xb4, 3<<6 );

	for( int j=0; j<4; j++ ) {
		ch[0].op[j].set_dr(0);
		ch[0].op[j].set_sr(0);
	}

	write( 0, 0xb0, 7 );
	write( 0, 0x40, 0x0 );
	write( 0, 0x44, 0x7f );
	write( 0, 0x48, 0x7f );
	write( 0, 0x4C, 0x7f );
	write( 0, 0x28, 0xf0 );
	write( 0, 0x01, 200 );

	write( 0, 0x44, 0x0 );
	write( 0, 0x01, 200 );


	write( 0, 0x48, 0x0 );
	write( 0, 0x01, 200 );

	write( 0, 0x4c, 0x0 );
	write( 0, 0x01, 200 );
	// Ajuste
	write( 0, 0x40, 0x8 );
	write( 0, 0x44, 0x7f );
	write( 0, 0x48, 0x7f );
	write( 0, 0x4C, 0x7f );
	write( 0, 0x01, 200 );

	write( 0, 0x44, 0x8 );
	write( 0, 0x48, 0x7f );
	write( 0, 0x4C, 0x7f );
	write( 0, 0x01, 200 );

	write( 0, 0x40, 13 );
	write( 0, 0x44, 13 );
	write( 0, 0x48, 13 );
	write( 0, 0x4C, 0x7f );
	write( 0, 0x01, 200 );

	write( 0, 0x40, 16 );
	write( 0, 0x44, 16 );
	write( 0, 0x48, 16 );
	write( 0, 0x4C, 16 );
	write( 0, 0x01, 200 );

}

void dacmux_test( Ch ch[6] ) {
	initial_clear( ch );
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(0);
		ch[k].set_rl(3);
	}
	for( int k=0; k<6; k++ ) {
	//for( int j=0; j<4; j++ ) {
		int j=0;
		ch[k].op[j].set_tl( 0 );
		ch[k].keyon( 1<<j );
		write( 0, 0x01, 50 ); // wait
//		}
	}
	//write( 0, 0x21, 1<<3 ); // PG stop
	write( 0, 0x01, 10 ); // wait
	ch[0].set_rl(1);
	ch[4].set_rl(1);
	ch[2].set_rl(1);
	ch[1].set_rl(1);
	ch[5].set_rl(1);
	ch[3].set_rl(1);
	write( 0, 0x01, 10 ); // wait
	ch[0].set_rl(2);
	ch[4].set_rl(2);
	ch[2].set_rl(2);
	ch[1].set_rl(2);
	ch[5].set_rl(2);
	ch[3].set_rl(2);
	write( 0, 0x01, 10 ); // wait

	// los enciendo de uno en uno
	ch[0].set_rl(0);
	ch[4].set_rl(0);
	ch[2].set_rl(0);
	ch[1].set_rl(0);
	ch[5].set_rl(0);
	ch[3].set_rl(0);
	write( 0, 0x01, 20 ); // wait
	// todos apagados
	ch[0].set_rl(1);
	write( 0, 0x01, 10 ); // wait
	ch[4].set_rl(1);
	write( 0, 0x01, 5 ); // wait
	ch[2].set_rl(1);
	write( 0, 0x01, 5 ); // wait
	ch[1].set_rl(1);
	write( 0, 0x01, 5 ); // wait
	ch[5].set_rl(1);
	write( 0, 0x01, 5 ); // wait
	ch[3].set_rl(1);
	write( 0, 0x01, 5 ); // wait
	// los enciendo de uno en uno en el izquierdo
	ch[0].set_rl(0);
	ch[4].set_rl(0);
	ch[2].set_rl(0);
	ch[1].set_rl(0);
	ch[5].set_rl(0);
	ch[3].set_rl(0);
	write( 0, 0x01, 20 ); // wait
	ch[0].set_rl(2);
	write( 0, 0x01, 10 ); // wait
	ch[4].set_rl(2);
	write( 0, 0x01, 5 ); // wait
	ch[2].set_rl(2);
	write( 0, 0x01, 5 ); // wait
	ch[1].set_rl(2);
	write( 0, 0x01, 5 ); // wait
	ch[5].set_rl(2);
	write( 0, 0x01, 5 ); // wait
	ch[3].set_rl(2);
	write( 0, 0x01, 5 ); // wait

}

void mmr_test( Ch ch[6], int rnd_cases=3 ) {
	initial_clear( ch );
	cerr << "MMR test\n";
	cerr << "Tarda unos 25 minutos en el portatil en hacer 800 casos\n";
	cerr << "Tarda unos 45 minutos en el despacho en hacer 2000 casos\n";
	for( int k=0; k<6; k++ ) {
		int c = k;
		if ( k>2 ) c++;

		ch[k].set_alg(c);
		ch[k].set_fb(c);
		ch[k].set_rl(c&3);
		ch[k].set_block(c);
		for( int j=0; j<4; j++ ) {
			int op=j ;
			switch(j) {
				case 0: op=0; break;
				case 1: op=2; break;
				case 2: op=1; break;
				case 3: op=3; break;
				default: op=0; break;
			}
			int n = (op<<2) | (c&3);
			if( k>2 ) n |= 0x10;
			ch[k].op[j].dt = op;
			ch[k].op[j].set_tl( n );
			ch[k].op[j].set_mul( c );
			ch[k].op[j].set_ar( n );
			ch[k].op[j].set_dr( n );
			ch[k].op[j].set_sr( n );
			ch[k].op[j].set_ssg( c );
			ch[k].op[j].set_sl( c );
		}
	}
	wait( 5 );
	write( 0, 2, 4 ); // dump MMR data
	cerr << "Reference data dumped\n";

	ofstream of("mmr_ref.log");
	dump( of, ch );
	for( int i=0; i<rnd_cases; i++ ) {
		cout << "//Random set #" << i << "\n";
		srand(i);
		if( rand()%2 ) ch[rand()%6].set_alg( rand()%8 );
		if( rand()%2 ) ch[rand()%6].set_fb( rand()%8 );
		if( rand()%2 ) ch[rand()%6].set_rl( rand()%4 );
		if( rand()%2 ) ch[rand()%6].set_block( rand()%8 );
		if( rand()%2 ) ch[rand()%6].set_fnumber( rand()%2048 );
		if( rand()%2 ) ch[rand()%6].op[rand()%4].set_dt( rand()%8 );
		if( rand()%2 ) ch[rand()%6].op[rand()%4].set_tl( rand()%128 );
		if( rand()%2 ) ch[rand()%6].op[rand()%4].set_mul( rand()%16 );
		if( rand()%2 ) ch[rand()%6].op[rand()%4].set_ar( rand()%32 );
		if( rand()%2 ) ch[rand()%6].op[rand()%4].set_dr( rand()%32 );
		if( rand()%2 ) ch[rand()%6].op[rand()%4].set_sr( rand()%32 );
		if( rand()%2 ) ch[rand()%6].op[rand()%4].set_sr( rand()%16 );
		if( rand()%2 ) ch[rand()%6].op[rand()%4].set_ssg( rand()%8 );
		if( rand()%2 ) ch[rand()%6].op[rand()%4].set_sl( rand()%16 );
		ch[rand()%6].keyon( rand()%16 );
		write( 0, 1, 24+(rand()%4) );
		write( 0, 2, 4 ); // dump MMR data
		dump( of, ch );
	}
}

void burst_test( Ch ch[6] ) {
	srand(0);
	for( int k=0; k<10; k++ ) {
		Ch* c = &ch[rand()%6];
		c->set_fnumber( 0x25e );
		c->set_block( 4 );
		c->set_alg(0);
		c->set_fb(4);
		c->set_rl(3);
		for( int j=0; j<4; j++ ) {
			c->op[j].set_tl(0x16);
			c->op[j].set_ar( 0x1f );
			c->op[j].set_sl( 0xf );
			c->op[j].set_sr(6);
			c->op[j].set_rr(0xf);
			c->op[j].set_dt(3);
			c->op[j].set_mul(5);
		}
		for( int j=0; j<5; j++ ) {
			int opmask = rand()%15;
			c->keyon( (~opmask)&0xf );
			write(0, 1, rand()%10 );
			c->keyon( ( opmask) );
			write(0, 1, 20+rand()%10 );
		}
	}
}
/*
void ssg2_test( Ch ch[6] ) {
	cerr << "This is Nemesis' SSG test\n";
	cerr << "Tarda 50 minutos en el despacho\n";
	ch[2].set_alg(7);
	ch[2].set_rl(3);
	Op& op = ch[2].op[3];
	op.set_mul(1);
	op.set_tl(2);
	op.set_ks(0);
	op.set_ar(31); // de momento 31, el original usa un 2
	op.set_dr(18); // 8 en el original
	op.set_sr(18); // 8 en el original
	op.set_sl(0xd);
	op.set_rr(15); // 4 en el original

	for( int ssg=7; ssg<16; ssg++ ) {
		op.set_ssg4( ssg );
		ch[2].keyon(8);
		for( int j=0; j<30;j++ ) write(0,1,255);
		ch[2].keyon(0);
		write(0,1,70);
	}
}
*/
void ssg2_test( Ch ch[6] ) {
	cerr << "This is Nemesis' SSG test\n";
	cerr << "1s de simulacion tarda 20m y ocupa 38MB\n";
	//cerr << "Tarda 50 minutos en el despacho\n";

    unsigned char ymregs[] = {
        0xb2, 0x07,
        0xb6, 0xc0,
        0x3e, 0x01,
        0x4e, 0x02,
        0x5e, 0x1f, // AR
        0x6e, 0x08, // DR
        0x7e, 0x08, // SR

        0x8e, 0xf4, // SL+RR
        0x9e, 0x00, // SSG
        0xa6, 0x34,
        0xa2, 0x43,
        0x9e, 0x7 // SSG
    };
    int k;
    // YM2612_reset();
    for ( k=0; k<sizeof(ymregs); k+=2 ) {
        write( 0, ymregs[k], ymregs[k+1]);
    }
    for( int ssg=0; ssg<8; ssg++ ) {
        write( 0, 0x28, 0x82 );
		wait( 5000 );
        write( 0, 0x28, 0x02 );
        write( 0, 0x9e, 0x08 | (ssg&7) );
		wait( 300 );
    }
}

int main( int argc, char *argv[] ) {
	Ch ch[6];
	for( int k=0, slot=0; k<6; k++ ) {
		if( k<3  ) ch[k].chnum=k;
		if( k>=3 ) ch[k].chnum=k+1;
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].opnum = j;
			ch[k].op[j].chnum = ch[k].chnum;
        }
    }
	// initial_clear( ch );

	for( int k=1; k<argc; k++ ) {
		if( strcmp( argv[k], "-pcm" )==0 ) pcm_check( ch );
		if( strcmp( argv[k], "-lfo" )==0 ) lfo_check();
		if( strcmp( argv[k], "-csm" )==0) csm_test( ch );
		if( strcmp( argv[k], "-dr" )==0 ) dr_test( ch );
		if( strcmp( argv[k], "-maxtl" )==0 ) maxtl_test( ch );
		if( strcmp( argv[k], "-fnum" )==0 )  fnum_check( ch );
		if( strcmp( argv[k], "-ssg" )==0 )  ssg_test( ch );
		if( strcmp( argv[k], "-ssg2" )==0 )  ssg2_test( ch );
		if( strcmp( argv[k], "-ch3" )==0 )  ch3effect_test( ch );
		if( strcmp( argv[k], "-timerB" )==0 )  timerb( ch );
		if( strcmp( argv[k], "-keyon2" )==0 )  keyon_doble( ch );
		if( strcmp( argv[k], "-keyon" )==0 )  keyon_simple( ch );
		if( strcmp( argv[k], "-tone00" )==0 )  tone00( ch );
		if( strcmp( argv[k], "-alg" )==0 )  alg_test( ch, 0xFF, 7 );
		if( strcmp( argv[k], "-am" )==0 )  am_test( ch );
		if( strcmp( argv[k], "-amfreq" )==0 )  amfreq_test( ch );
		if( strcmp( argv[k], "-fnumorder" )==0 )  fnumorder_test( ch );
		if( strcmp( argv[k], "-acc" )==0 )  acc_test( ch );
		if( strcmp( argv[k], "-dac" )==0 )  dacmux_test( ch );
		if( strcmp( argv[k], "-burst" )==0 )  burst_test( ch );
		if( strcmp( argv[k], "-powerup" )==0 )  wait(1000);
		if( strcmp( argv[k], "-gym" )==0 ) {			
			parse_gym( argv[++k] );
		}

		if( strcmp( argv[k], "-mmr" )==0 )  {
			k++;
			int cases=3;
			if( k==argc ) {
				cerr << "Use\n\t-mmr <number of random cases>\n";
				cerr << "Running 3 cases by default\n";

			}
			else {
				stringstream s(argv[k]);
				s >> cases;
				cerr << "Running " << cases << " random cases\n";
			}
			mmr_test( ch, cases );
		}
	}

//	ch[0].op[0].set_sl(15);
    // gng2( ch ); // 27 min en casa
  //  test_bin( ch );

	// Finish
	cout << "\ncfg["<<cont<<"] = { 1'b0, 8'h0, 8'h00 }; // done\n";
	return 0;
}
