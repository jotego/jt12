#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <cstdlib>

using namespace std;

class JT12_REG {
	unsigned dt[24], mul[24], tl[24], ks[24], ar[24], am[24];
	unsigned dr[24], sr[24], sl[24], rr[24], ssgen[24], ssg[24];
	int dt_stg, mul_stg, tl_stg, ks_stg, 
		ar_stg, am_stg, dr_stg, sr_stg, sl_stg,
		rr_stg, ssgen_stg, ssg_stg;
		
	unsigned fnum[6], block[6], fnum_latch, 
		fb[6], alg[6], lr[6], ams[6], pms[6];
		
	unsigned block_ch3s1, fnum_ch3s1, block_ch3s2, fnum_ch3s2, block_ch3s3, fnum_ch3s3;
	void parse_fnum( unsigned &block, unsigned& fnum, unsigned val ) {
		fnum  = ((fnum_latch<<8) | val)&0x7ff;
		block = (fnum_latch>>3)&7;
	}
	public:
	JT12_REG();
	int mod(int op, int ch, int stg) { 
		// this mod is different from mod6 because this mod is used to store the values
		// and mod6 is used to extract them
		// I should change it so operator values are stored without mixing
		// and sorted at output, like frequency values...
		int x = op*6+ch+stg-1;
		if( x==0 ) 
			return 23;
		else
			return (x-1)%24; 
	}
	int mod6( int ch, int stg ) {
		int x = ch+6-(stg-1);
		return x%6;
	}
	void write( int addr, int reg, unsigned val );
	void save();
};

JT12_REG::JT12_REG() {
	dt_stg = 2, mul_stg=5, tl_stg=4, ks_stg=2, 
	ar_stg = 1, am_stg=4, dr_stg=1, sr_stg=1, sl_stg=1,
	rr_stg = 1, ssgen_stg=1, ssg_stg=1;		
	for( int op=0; op<24; op++ ) {
		dt[op]= mul[op]= tl[op]= ks[op]= ar[op]= am[op] = 0xdead;
		dr[op]= sr[op]= sl[op]= rr[op]= ssgen[op]= ssg[op] = 0xdead;
	}
	for( int ch=0; ch<6; ch++ ) {
		fnum[ch] = block[ch]= 0xdead;
		fb[ch]= alg[ch]= lr[ch]= ams[ch]= pms[ch] =0xdead;		
	}
	fnum_latch = 0xdead;
	block_ch3s1 = fnum_ch3s1 = block_ch3s2 = fnum_ch3s2 = block_ch3s3 = fnum_ch3s3 = 0xdead;
}

void JT12_REG::write( int addr, int reg, unsigned val ) {
	int op = (reg>>2)&3;
	int ch =  reg&3;
	if( ch==3 ) return; // illegal write
	ch += (addr ? 3 : 0);
	if(reg>=0x30 && ( (reg&3)==3 ) ) return; // ignore writes to invalid register
	switch( reg>>4 ) {
		case 3: 
			dt[mod(op,ch,dt_stg)] = (val>> 4)&7;
			mul[mod(op,ch,mul_stg)]= val&0xf;
			break;
		case 4:
			tl[mod(op,ch,tl_stg)] = val&0x7f;
			break;
		case 5:
			ks[mod(op,ch,ks_stg)] = (val>>6)&3;
			ar[mod(op,ch,ar_stg)] = val&0x1f;
			break;
		case 6:
			am[mod(op,ch,am_stg)] = (val>>7)&1;
			dr[mod(op,ch,dr_stg)] = val&0x1f;
			break;
		case 7:
			sr[mod(op,ch,sr_stg)] = val&0x1f;
			break;
		case 8:
			sl[mod(op,ch,sl_stg)] = (val>>4)&0xf;
			rr[mod(op,ch,rr_stg)] = val&0xf;
			break;
		case 9:
			ssgen[mod(op,ch,ssgen_stg)] = (val>>3)&1;
			ssg[mod(op,ch,ssg_stg)] = val&7;
			break;
		case 0xa:
			if( (reg&0x4)==4 ) 
				fnum_latch = val&0x3f;
			else {
				if( (reg&0x8) ==0 ) {
					// cerr << "CH=" << ch << " val=" << hex << val << '\n';
					parse_fnum( block[ch], fnum[ch], val );
				}
				else switch( reg&0xf ) {
					case 0xD: parse_fnum( block_ch3s1, fnum_ch3s1, val ); break;
					case 0xC: parse_fnum( block_ch3s3, fnum_ch3s3, val ); break;
					case 0xE: parse_fnum( block_ch3s2, fnum_ch3s2, val ); break;
				}
			}
			break;
		case 0xb:
			if( (reg&0xf) <= 2) {
				fb[ch] = (val>>3)&7;
				alg[ch]= val&7;
			}
			else if( (reg&0xf) <=6 ) {
				lr[ch] = (val>>6)&3;
				ams[ch]= (val>>4)&3;
				pms[ch]= val&7;
			}
	}
}

void JT12_REG::save() {
	ofstream of("verify.csv");
/* 	$display("%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X", 
	s_hot, dt1_II, mul_V, tl_VII, ks_III, ar_II,
	amsen_VII, d1r_II, d2r_II, d1l, rr_II, ssg_en, ssg_eg_II ); */
	of << hex;

	for( int k=0; k<24; k++ ) {
		int aux=k+1;
		if(aux>23) aux=0;
		int ch=aux%6;
		int ch_index = ch;
		int op=aux/6;
		if (ch>2) ch++;
		// of << k << ',';
		of << op << ',' << ch << ' ';
		of << dt[k] << ',';
		of << mul[k] << ',';
		of << setfill('0') << setw(2) << tl[k] << ',';
		of << ks[k] << ',';
		of << setw(2) << ar[k] << ',';
		of << am[k] << ',';
		of << setw(2) << dr[k] << ',';
		of << setw(2) << sr[k] << ',';
		of << setw(1) << sl[k] << ',';
		of << rr[k] << ',';
		of << ssgen[k] << ',';
		of << ssg[k] << " / ";
		// channel info
		of << block[ch_index] << ',';
		of << setfill('0') << setw(3) << fnum[ch_index] << setw(0) << ',';
		of << fb[ mod6(ch_index,2) ] << ',';
		of << alg[ mod6(ch_index,1) ] << ',';
		of << lr[ mod6(ch_index,1) ] << ',';
		of << ams[ mod6(ch_index,4) ] << ',';
		of << pms[ mod6(ch_index,1) ];
		of << '\n';
	}
}

void write_vh( int cont, int bank, int reg, int val ) {
	int ch=reg&3;
	int op=(reg>>2)&3;
	cout << "cfg[" << cont <<"] = { 1'b" << bank << ", ";
	cout << "8'h" << hex << reg << ", 8'h" << val << "};" << dec;
	cout << " // CH=" << (ch+(bank?3:0)) << " OP=" << op << '\n';	
}

int main( int argc, char *argv[] ) {
	int aux=0;
	int cont=0;
	JT12_REG regs;
	int rand_iter = 5000;
	
	int base_start = 3, base_end = 0x10;
	enum { use_cont, use_zero, use_rand, full_rand } use=use_rand;
	srand(0);
	for( int k=1; k<argc; k++ ) {
		if( string(argv[k]) == "-mul" ) { base_end=4; continue; }
		if( string(argv[k]) == "-tl" ) { base_start=4; base_end=5;  continue; }
		if( string(argv[k]) == "-cont" ) { use=use_cont; continue; };
		if( string(argv[k]) == "-zero" ) { use=use_zero; continue; };
		if( string(argv[k]) == "-rand" ) { use=use_rand; continue; };
		if( string(argv[k]) == "-full_rand" ) { use=full_rand; continue; };
		if( string(argv[k]) == "-max" ) {
			if( ++k == argc ) {
				cerr << "ERROR: expecting maximum number of iterations after -max\n";
				return 2;
			}
			if( sscanf( argv[k], "%d", &rand_iter ) != 1 ) {
				cerr << "ERROR: expecting maximum number of iterations after -max but got '"
					<< argv[k] << "'\n";
				return 2;				
			}
			continue;
		}
		cerr << "ERROR: Unknown argument '" << argv[k] << "'\n";
		cerr << "With no arguments, it will run a long set of random writes to\n"
			"registers in the 0x30-0xFF space in random order. Expected outputs are dump to the\n"
			"screen and can be redirected to a text file for comparison with simulation.\n";
		cerr << "Usage:\n";
		cerr << "\t-mul\tsimulate only writes to the MUL register\n";
		cerr << "\t-tl\tsimulate only writes to the TL register\n";
		cerr << "\t-cont\twrite sequential values to registers\n";
		cerr << "\t-zero\twrite zero to registers\n";
		cerr << "\t-max\tnumber of iterations (only for random stimuli)\n";
		cerr << "\t-rand\twrite random values but in sequential order\n";
		return 1;
	}
	if( use!= full_rand ) {
		regs.write( 0, 0xa4, 0 ); // set the fnum latch to 0
		write_vh( cont++, 0, 0xa4, 0 );		
		for( int base=base_start; base<base_end; base++ ) {
		int op_max = base<0xa ? 4 : 2;
		for( int op=0; op<op_max; op++ ) {
			for( int bank=0; bank<=1; bank++ ) 
			for( int ch=0; ch<3; ch++ )			
			{
					int reg = (base << 4) | (op<<2) | ch;   
					// cout << "************\nREG= " << hex << reg << "\n";
					unsigned val=0;
					switch( use ) {
						case use_cont: val = cont; break;
						case use_rand: val = rand()%256; break;
						case use_zero: val = 0; break;
					}
					regs.write( bank, reg, val );
					write_vh( cont++, bank, reg, val );
				}
			}
		}
	}
	else {
		base_start<<=4;		
		base_end<<=4;
		for( cont=0; cont<rand_iter; cont++ ) {
			int bank=rand()%2, val=rand()%256, reg=rand()%256;	
			while( reg<base_start || reg>=base_end ) reg=rand()%256;
			regs.write( bank, reg, val );
			write_vh( cont, bank, reg, val );
		}
	}
	finish:
	// Finish
	cout << "\ncfg["<<cont<<"] = { 1'b0, 8'h0, 8'h00 }; // done\n";
	regs.save();
	return 0;
}
