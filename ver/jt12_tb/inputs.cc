#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <cstdlib>
#include <cstring>

using namespace std;

int cont=0;

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
	cout <<", 8'h" << hex << ((reg+(chnum&3))&0xff) << ", 8'h" << (val&0xff) << "};\n";
	cout << dec;
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
	void set_mul( int a ) {
		mul = a;
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
	void set_ar( int a ) {
		ar = a;
		write( chnum, 0x50+reg_offset(), (ks<<6)| ar );
	}
	void set_sr( int a ) {
		sr = a;
		write( chnum, 0x70+reg_offset(), a );
	}
	void set_dr( int a ) {
		dr = a;
		write( chnum, 0x60+reg_offset(), a );
	}
	void set_ssg( int a  ) {
		ssg = a;
		write( chnum, 0x90+reg_offset(), (ssgen<<3)| ssg );
	}
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
};

void keyoff_all() {
	for( int k=0; k<6; k++ ) {
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
	write( 0, 0x01, 55 ); // wait
	keyoff_all();
	write( 0, 0x01, 155 ); // wait
}

void keyon( int ch, int op ) {
	if( ch>2 ) ch++;
	write(  0, 0x28, (op<<4) | (ch) );
}

void alg_test( Ch ch[6], int mask, int fb_max ) {
	// ALG = 7
	if (mask&0x80) {
	cerr << "Starting ALG=7"<<endl;
	for( int fb=0; fb<fb_max; fb++ ) {
		cerr << "FB="<<fb<<endl;
		for( int k=0; k<6; k++ ) {
			ch[k].set_alg(7);
			ch[k].set_fb(fb);
			ch[k].set_rl(3);
		}
		for( int k=0; k<3; k++ ) {
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_tl( 16 );
			keyon( k, 1<<j );
			write( 0, 0x01, 64 ); // wait
			}
			keyoff_all();
		}
	}
	}
	// ALG = 6
	if (mask&0x40) {
	cerr << "Starting ALG=6"<<endl;
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(6);
		ch[k].op[0].set_tl(20);
		ch[k].op[0].set_dr(0);
		for( int j=1; j<4; j++ ) {
			ch[k].op[j].set_tl( 0 );
		}
		keyon( k, 0xf );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait

		keyoff_all();
	}
	}
	// ALG = 5
	if (mask&0x20) {
	cerr << "Starting ALG=5"<<endl;
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(5);
		ch[k].set_fb(0);
		ch[k].op[0].set_tl(20);
		ch[k].op[0].set_dr(0);
		for( int j=1; j<4; j++ ) {
			ch[k].op[j].set_tl( 0 );
		}
		keyon( k, 0xf );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait

		keyoff_all();
	}
	}
	// ALG = 4
	if (mask&0x10) {
	cerr << "Starting ALG=4"<<endl;
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(4);
		ch[k].set_fb(k+1);
		ch[k].op[0].set_tl(20);
		ch[k].op[2].set_tl(25);
		ch[k].op[1].set_tl(0);
		ch[k].op[3].set_tl(0);
		for( int j=0; j<4; j++ )
			ch[k].op[j].set_dr(0);
		keyon( k, 15 );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait

		keyoff_all();
	}
	}
	// ALG = 3
	if (mask&0x8) {
	cerr << "Starting ALG=3"<<endl;
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(3);
		ch[k].set_fb(k+1);
		ch[k].op[0].set_tl(20); // S1
		ch[k].op[2].set_tl(25); // S3
		ch[k].op[1].set_tl(20); // S2
		ch[k].op[3].set_tl(0);
		ch[k].op[0].set_dr(0);
		ch[k].op[3].set_dr(0);
		keyon( k, 0xc );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait
		keyon( k, 0xb );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait
		keyon( k, 0xf );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait

		keyoff_all();
	}
	}
	// ALG = 2..0
	for( int alg=2, m=4; alg>=0; alg--,m>>=1 )
	if( mask& m ) {
	cerr << "Starting ALG="<<alg<<endl;
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(alg);
		ch[k].set_fb(k+1);
		ch[k].op[0].set_tl(20); // S1
		ch[k].op[2].set_tl(25); // S3
		ch[k].op[1].set_tl(20); // S2
		ch[k].op[3].set_tl(0);
		ch[k].op[0].set_dr(0);
		ch[k].op[3].set_dr(0);
		keyon( k, 0x8 );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait
		keyon( k, 0xc );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait
		keyon( k, 0xe );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait
		keyon( k, 0xf );
		for( int wait=0; wait<3; wait++ )
			write( 0, 0x01, 255 ); // wait

		keyoff_all();
	}
	}
}

void ssg_test( Ch ch[6] ) {
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(4);
	}
	int ssg=0;
	for( int k=0; k<6; k++ ) {
		for( int j=0; j<4; j++, ssg++ ) {
			ch[k].op[j].ssgen = 1;
			ch[k].op[j].set_ssg( ssg%8 );
			ch[k].op[j].set_tl( 0 );
			ch[k].op[j].set_sr( 25 );
			ch[k].op[j].set_dr( 28 );
		}
		keyon( k, 0xf );
		for( int wait=0; wait<7; wait++ )
			write( 0, 0x01, 255 ); // wait

		keyoff_all();
	}
	for( int k=0; k<6; k++ )
	for( int j=0; j<4; j++, ssg++ ) {
		ch[k].op[j].ssgen = 0;
        ch[k].op[j].set_ssg(0);
	}
}

void tone00( Ch ch[6] ) {
	ch[0].op[0].set_sl(15);
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		keyon( k, 15 );
		keyon( k, 0 );
	}
	ch[0].op[0].set_tl( 0 );
			keyon( 0, 1 );
	for( int wait=0; wait<2; wait++ )
		write( 0, 0x01, 255 ); // wait
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
		keyon( k, 0xf );
	}
	for( int wait=0; wait<17; wait++ )
		write( 0, 0x01, 255 ); // wait
	keyoff_all();
}

void pcm_check( Ch ch[6] ) {
	cerr << "PCM check. 1m20s run time.\n";
	cerr << "It will enable all operators and then PCM output\n";
	cerr << "Check that channel 6 is being replaced by PCM samples\n";
	cerr << "As RL settings go from 0 to 3, output should be checked\n";
	cerr << "on both channels\n";
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		keyon( k, 15 );
		keyon( k, 0 );
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_ar(0);
			ch[k].op[j].set_sl(0);
			ch[k].op[j].set_sr(0);
			ch[k].op[j].set_dr(0);
			ch[k].op[j].set_tl( k==5? 0 : 127 );
		}
		keyon( k, 15 );
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
		keyon( k, 0xf );
	}
	for( int wait=0; wait<2; wait++ )
		write( 0, 0x01, 255 ); // wait
	keyoff_all();
}

void csm_test(Ch ch[6]) {
	initial_clear( ch );
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(0);
		ch[k].set_fnumber(925);
		ch[k].set_block(4);
		ch[k].set_rl(3);
		for( int j=0; j<4; j++ ) {
			ch[k].op[j].set_tl( 0 );
			ch[k].op[j].set_dr( 0 );
			ch[k].op[j].set_mul(1);
		}
	}
	unsigned faux = 925&0xff;
	unsigned baux = (4<<3)|(925>>8);
	write( 0, 0xa9, faux );
	write( 0, 0xa8, faux );
	write( 0, 0xaa, faux );
	write( 0, 0xa2, faux );
	write( 0, 0xad, baux );
	write( 0, 0xac, baux );
	write( 0, 0xae, baux );
	write( 0, 0xa6, baux );

	write( 0, 0x24, 120 );
	write( 0, 0x25, 0 );
	write( 0, 0x27, 0x75 ); // CSM
	for( int wait=0; wait<8; wait++ )
		write( 0, 0x01, 255 ); // wait
	keyoff_all();
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
     	keyon( k, 0xf );
		for( int wait=0; wait<25; wait++ )
			write( 0, 0x01, 255 ); // wait
        keyoff_all();
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
    for( int k=0; k<256; k++ ) {
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
		keyon( k, 1<<j );
		write( 0, 1, 20 );
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
		keyon( k, 15 );
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
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(7);
		ch[k].set_fb(0);
		ch[k].set_rl(3);
	}
	for( int k=0; k<6; k++ ) {
	//for( int j=0; j<4; j++ ) {
		int j=0;
		ch[k].op[j].set_tl( 0 );
		keyon( k, 1<<j );
		write( 0, 0x01, 50 ); // wait
//		}
	}
	write( 0, 0x21, 1<<3 ); // PG stop
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

void mmr_test( Ch ch[6] ) {
	cerr << "MMR test\n";
	for( int k=0; k<6; k++ ) {
		ch[k].set_alg(k);
		ch[k].set_fb(k);
		for( int j=0; j<4; j++ ) {
			int c = k;
			if ( k>2 ) c++;
			int op ;
			switch(j) {
				case 0: op=0; break;
				case 1: op=2; break;
				case 2: op=1; break;
				case 3: op=3; break;
				default: op=0; break;
			}
			int n = (op<<3) | c;
			ch[k].op[j].set_tl( n );
			ch[k].op[j].set_ar( n );
			ch[k].op[j].set_dr( n );
			ch[k].op[j].set_sr( n );
		}
	}
}

int main( int argc, char *argv[] ) {
	Ch ch[6];
	initial_clear( ch );

	for( int k=1; k<argc; k++ ) {
		if( strcmp( argv[k], "-pcm" )==0 ) pcm_check( ch );
		if( strcmp( argv[k], "-dr" )==0 || strcmp( argv[k], "-csm" )==0)
			csm_test( ch );
		if( strcmp( argv[k], "-csm" )==0 )  csm_test( ch );
		if( strcmp( argv[k], "-fnum" )==0 )  fnum_check( ch );
		if( strcmp( argv[k], "-ssg" )==0 )  ssg_test( ch );
		if( strcmp( argv[k], "-ch3" )==0 )  ch3effect_test( ch );
		if( strcmp( argv[k], "-timerB" )==0 )  timerb( ch );
		if( strcmp( argv[k], "-keyon2" )==0 )  keyon_doble( ch );
		if( strcmp( argv[k], "-keyon" )==0 )  keyon_simple( ch );
		if( strcmp( argv[k], "-tone00" )==0 )  tone00( ch );
		if( strcmp( argv[k], "-alg" )==0 )  alg_test( ch, 0x80, 1 );
		if( strcmp( argv[k], "-am" )==0 )  am_test( ch );
		if( strcmp( argv[k], "-amfreq" )==0 )  amfreq_test( ch );
		if( strcmp( argv[k], "-fnumorder" )==0 )  fnumorder_test( ch );
		if( strcmp( argv[k], "-acc" )==0 )  acc_test( ch );
		if( strcmp( argv[k], "-dac" )==0 )  dacmux_test( ch );
		
		if( strcmp( argv[k], "-mmr" )==0 )  mmr_test( ch );
	}

//	ch[0].op[0].set_sl(15);
    // gng2( ch ); // 27 min en casa
  //  test_bin( ch );

	// Finish
	cout << "\ncfg["<<cont<<"] = { 1'b0, 8'h0, 8'h00 }; // done\n";
	return 0;
}
