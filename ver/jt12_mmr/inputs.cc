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
		
	unsigned fnum1[6], fnum2[6], block[6], 
		fb[6], alg[6], lr[6], ams[6], pms[6];
		
	unsigned fnum1_sup[6], fnum2_sup[6], block_sup[6];
	public:
	JT12_REG() {
		dt_stg = 2, mul_stg=5, tl_stg=7, ks_stg=3, 
		ar_stg = 2, am_stg=7, dr_stg=2, sr_stg=2, sl_stg=1,
		rr_stg = 2, ssgen_stg=1, ssg_stg=2;		
		for( int op=0; op<24; op++ ) {
			dt[op]= mul[op]= tl[op]= ks[op]= ar[op]= am[op] = 0xdead;
			dr[op]= sr[op]= sl[op]= rr[op]= ssgen[op]= ssg[op] = 0xdead;
		}
		for( int ch=0; ch<6; ch++ ) {
			fnum1[ch]= fnum2[ch]= block[ch]= 0xdead;
			fb[ch]= alg[ch]= lr[ch]= ams[ch]= pms[ch] =0xdead;		
			fnum1_sup[ch] = fnum2_sup[ch] = block_sup[ch] = 0xdead;
		}
	}
    void write( int addr, int reg, unsigned val ) {
    	int op = (reg>>2)&3;
        int ch = (reg&3) + (addr ? 3 : 0);
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
				if( (reg&0xf) <= 2) {
					fnum1[ch] = val;
				}
				else if( (reg&0xf) <=6 ) {
					fnum2[ch] = val&7;
					block[ch] = (val>>3)&7;
				}
				else switch( (reg&0xf) ) {
					case 0x9: fnum1_sup[addr  ] = val; break; // S1
					case 0x8: fnum1_sup[addr+1] = val; break; // S3
					case 0xA: fnum1_sup[addr+2] = val; break; // S2
					
					case 0xD: fnum2_sup[addr  ] = val&7; 
						block[addr] = (val>>3)&7; break; // S1
					case 0xC: fnum2_sup[addr+1 ] = val&7; 
						block[addr+1] = (val>>3)&7; break; // S3
					case 0xE: fnum2_sup[addr+2 ] = val&7;
						block[addr+2] = (val>>3)&7; break; // S2
				}
			case 0xb:
				if( (reg&0xf) <= 2) {
					fb[ch] = (val>>3)&3;
					alg[ch]= val&7;
				}
				else if( (reg&0xf) <=6 ) {
					lr[ch] = (val>>6)&3;
					ams[ch]= (val>>4)&3;
					pms[ch]= val&7;
				}
        }
    }
	int mod(int op, int ch, int stg) { 
		// cout << "Op = " << op << " CH=" << (ch+1) << " STG=" << stg << "\n";
		int x = op*6+ch+stg-1;
		if( x==0 ) 
			return 23;
		else
			return (x-1)%24; 
	}
    void save() {
       	ofstream of("verify.csv");
/* 	$display("%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X", 
    	s_hot, dt1_II, mul_V, tl_VII, ks_III, ar_II,
    	amsen_VII, d1r_II, d2r_II, d1l, rr_II, ssg_en, ssg_eg_II ); */
        of << hex;

        for( int k=0; k<24; k++ ) {
			int ophot;
			if( k<6 ) ophot=1;
			else if( k<12 ) ophot=2;
			else if( k<18 ) ophot=4;
			else ophot=8;
			// of << k << ',';
			of << ophot << ',';
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
			of << ssg[k] << '\n';
        }
    }
};

int main( int argc, char *argv[] ) {
	int aux=0;
    int cont=0;
    JT12_REG regs;
    
    int base_start = 3, base_end = 0xd;
	enum { use_cont, use_zero, use_rand } use=use_rand;
    srand(0);
    for( int k=1; k<argc; k++ ) {
    	if( string(argv[k]) == "-mul" ) { base_end=4; }
		if( string(argv[k]) == "-tl" ) { base_start=4; base_end=5; }
		if( string(argv[k]) == "-cont" ) { use=use_cont; };
		if( string(argv[k]) == "-zero" ) { use=use_zero; };
    }
    
	for( int base=base_start; base<base_end; base++ )     
    for( int bank=0; bank<=1; bank++ )
    for( int ch=0; ch<3; ch++ )			
    {
		int op_max = base<0xa ? 4 : 2;
		for( int op=0; op<op_max; op++ ) {
    		int reg = (base << 4) | (op<<2) | ch;   
			// cout << "************\nREG= " << hex << reg << "\n";
        	unsigned val=0;
			switch( use ) {
				case use_cont: val = cont; break;
				case use_rand: val = rand()%256; break;
				case use_zero: val = 0; break;
			}
        	regs.write( bank, reg, val );

        	cout << "cfg[" << cont <<"] = { 1'b" << bank << ", ";
        	cout << "8'h" << hex << reg << ", 8'h" << val << "};" << dec;
        	cout << " // CH=" << (ch+(bank?3:0)) << " OP=" << op << '\n';
        	cont++;
		}
    }
	
	// Finish
    cout << "\ncfg["<<cont<<"] = { 1'b0, 8'h0, 8'h00 }; // done\n";
    regs.save();
	return 0;
}
