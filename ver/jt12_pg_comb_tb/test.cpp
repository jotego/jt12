#include <cstring>
#include <cstdio>
#include <cmath>
#include <iostream>
#include <iomanip>
#include "Vtest.h"
#include "verilated_vcd_c.h"

using namespace std;


vluint64_t main_time = 0;
double sc_time_stamp () { return main_time; }


class Top {
	Vtest *dut;
	VerilatedVcdC* vcd;
	bool tracing;
public:
	// inputs
	int block, fnum, lfo_mod, pms, detune, mul, phase_in, pg_rst;
	// outputs
	int keycode, phase_out, phase_op, phinc;
	// reference
	int ref_ph;
	void reset();
	void apply();
	void get();
	void trace_on();
	void next();
	void trace();
	void feedback();
	int OPN2_PhaseCalcIncrement();
	void side_by_side();
	Top();
	~Top();
};
/* side-by-side comparison with ym3438.c code
 that code is allegedly a one-to-one version of the die shot */
void Top::side_by_side() {
	ref_ph = 0;
	block=1;
	lfo_mod=6; pms=7;detune=0;mul=1;
	phase_in=0; pg_rst=0;	
	for(block=0;block<8;block++)
	for(fnum=0;fnum<2048;fnum++)	
	for(mul=0;mul<16;mul++)
	for(detune=0;detune<8;detune++)
	for(pms=0;pms<8;pms++)
	for(lfo_mod=0;lfo_mod<32;lfo_mod++)
	{
		apply();
		dut->eval();
		get();
		int ref_inc = OPN2_PhaseCalcIncrement();
		//cout << block << ' ' << fnum << "*" << mul << " \t -> " << ref_inc << "\t" << phase_out << '\n';
		if( ref_inc != phase_out )
			printf("%d,%4d,(%d),*%2d ~%3d(%d) -> %6d <> %6d\n", 
				block, fnum, detune, mul, 
				(lfo_mod&0x10 ? -1 : 1 )*(lfo_mod%0xf), pms,
				ref_inc, phase_out);
		//cout << block << ' ' << fnum << '\n';
	}
}

int Top::OPN2_PhaseCalcIncrement()
{
	const uint32_t pg_detune[8] = { 16, 17, 19, 20, 22, 24, 27, 29 };	
	const uint32_t pg_lfo_sh1[8][8] = {
	    { 7, 7, 7, 7, 7, 7, 7, 7 },
	    { 7, 7, 7, 7, 7, 7, 7, 7 },
	    { 7, 7, 7, 7, 7, 7, 1, 1 },
	    { 7, 7, 7, 7, 1, 1, 1, 1 },
	    { 7, 7, 7, 1, 1, 1, 1, 0 },
	    { 7, 7, 1, 1, 0, 0, 0, 0 },
	    { 7, 7, 1, 1, 0, 0, 0, 0 },
	    { 7, 7, 1, 1, 0, 0, 0, 0 }
	};
	const uint32_t pg_lfo_sh2[8][8] = {
	    { 7, 7, 7, 7, 7, 7, 7, 7 },
	    { 7, 7, 7, 7, 2, 2, 2, 2 },
	    { 7, 7, 7, 2, 2, 2, 7, 7 },
	    { 7, 7, 2, 2, 7, 7, 2, 2 },
	    { 7, 7, 2, 7, 7, 7, 2, 7 },
	    { 7, 7, 7, 2, 7, 7, 2, 1 },
	    { 7, 7, 7, 2, 7, 7, 2, 1 },
	    { 7, 7, 7, 2, 7, 7, 2, 1 }
	};	
	uint32_t fnum = this->fnum;
    uint32_t fnum_h = fnum >> 4;
    uint32_t fm;
    uint32_t basefreq;
    uint8_t  lfo_l = lfo_mod & 0x0f;
    uint8_t  pms = this->pms;
    uint8_t  dt = this->detune;
    uint8_t  dt_l = dt & 0x03;
    uint8_t  detune = 0;
    uint8_t  block = this->block, note;
    uint8_t  sum, sum_h, sum_l;
    uint8_t  kcode = this->keycode;
    int mul = this->mul==0 ? 1 : this->mul*2;

    fnum <<= 1;
    /* Apply LFO */
    if (lfo_l & 0x08)
    {
        lfo_l ^= 0x0f;
    }
    fm = (fnum_h >> pg_lfo_sh1[pms][lfo_l]) + (fnum_h >> pg_lfo_sh2[pms][lfo_l]);
    if (pms > 5)
    {
        fm <<= pms - 5;
    }
    fm >>= 2;
    // printf("fm offset=%d\n",fm);
    if (lfo_mod & 0x10)
    {
        fnum -= fm;
    }
    else
    {
        fnum += fm;
    }
    fnum &= 0xfff;

    basefreq = (fnum << block) >> 2;

    /* Apply detune */
    if (dt_l)
    {
        if (kcode > 0x1c)
        {
            kcode = 0x1c;
        }
        block = kcode >> 2;
        note = kcode & 0x03;
        sum = block + 9 + ((dt_l == 3) | (dt_l & 0x02));
        sum_h = sum >> 1;
        sum_l = sum & 0x01;
        detune = pg_detune[(sum_l << 2) | note] >> (9 - sum_h);
    }
    if (dt & 0x04)
    {
        basefreq -= detune;
    }
    else
    {
        basefreq += detune;
    }
    basefreq &= 0x1ffff;
    int pg_inc = (basefreq * mul) >> 1;
    pg_inc &= 0xfffff;
    return pg_inc;
}


void Top::trace() {
	if( tracing ) vcd->dump(main_time);
}

void Top::next() {
	if( tracing ) vcd->dump(main_time);
	apply();
	dut->eval();
	get();
	main_time += 10; // this time is not intended to be used for frequency calculations
	feedback();
}

Top::Top() {
	dut = new Vtest;
	vcd = new VerilatedVcdC;
	tracing=false;
	reset();
}

Top::~Top() {
	VerilatedCov::write("logs/coverage.dat");
	if(tracing) {
		tracing=false;
		vcd->close();
	}
	delete dut;	dut=0;
	delete vcd; vcd=0;
}

void Top::trace_on() {
	Verilated::traceEverOn(true);
	dut->trace(vcd,99);
	vcd->open("test.vcd");	
	tracing=true;
}

void Top::reset() {
	block = fnum = lfo_mod = pms = detune = phase_in = pg_rst =0;
	mul=1;
	// get outputs for initial values:
	dut->eval();
	get();
}

void Top::apply() {
	dut->block		= block;
	dut->fnum		= fnum;
	dut->lfo_mod	= lfo_mod;
	dut->pms		= pms;
	dut->detune		= detune;
	dut->mul		= mul;
	dut->phase_in	= phase_in;
	dut->pg_rst		= pg_rst;
}

void Top::get() {
	keycode		= dut->keycode;
	phase_out	= dut->phase_out;
	phase_op	= dut->phase_op;
	phinc		= dut->phinc;
}

void Top::feedback() {
	// cout << "Phase out = " << phase_out << '\n';
	phase_in	= phase_out;
}

float ticks2freq(int ticks, int repeats=1) {
	float fop = 8e6/6/24;
	float freq = fop/ticks;
	freq *= repeats;
	return freq;
}

float get_freq(Top& top) {
	top.phase_in = 0;
	int ticks=0;
	int repeats=400; // needs to repeat many cycles 
		// to get precision for detune results
	const int max_ticks=(1<<29)-1;
	for(int k=0; k<repeats && ticks<max_ticks; k++ ) {
		//cerr << last_phase << " " << top.phase_op << " " << ticks << '\n';
		int last_phase = top.phase_op;
		while( last_phase <= top.phase_op && ticks<max_ticks ) {
			last_phase = top.phase_op;
			top.next();
			ticks++;
		};
	}
	if( ticks==max_ticks) cerr << "WARNING: Reached max ticks\n";
	return ticks==max_ticks ? 0 : ticks2freq(ticks, repeats);
}

int main(int argc, char *argv[]) {
	Top top;
	int err_code=0;
	bool do_detune=false, do_pm=false;
	int first_note=0, last_note=10;
	int first_block=0, last_block=7;
	int first_mul=1, last_mul=1;
	int mul=1, pms=0;
	
	for(int k=1; k<argc; k++ ) {
		if( strcmp(argv[k],"-w")==0 ) { top.trace_on(); continue; }
		if( strcmp(argv[k],"-dt")==0 ) { do_detune=true; continue; }
		if( strcmp(argv[k],"-pm")==0 ) { do_pm=true; continue; }
		if( strcmp(argv[k],"-mul")==0 ) { first_mul=0; last_mul=15; continue; }
		if( strcmp(argv[k],"-side")==0 ) { 
			top.side_by_side();
			return 0;
		}
		if( strcmp(argv[k],"-note")==0 ) { 
			if( ++k==argc ) { cerr << "ERROR: expecting note (0-10) after -note argument\n"; return 3; }
			if( sscanf( argv[k], "%d", &first_note)!=1 ) { cerr << "ERROR: expecting note (0-10) after -note argument\n"; return 3; }
			if( first_note<0 || first_note>10 ) { cerr << "ERROR: expecting note (0-10) after -note argument\n"; return 3; }
			last_note=first_note; continue; 
		}
		if( strcmp(argv[k],"-block")==0 ) { 
			if( ++k==argc ) { cerr << "ERROR: expecting block (0-7) after -block argument\n"; return 3; }
			if( sscanf( argv[k], "%d", &first_block)!=1 ) { cerr << "ERROR: expecting block (0-7) after -block argument\n"; return 3; }
			if( first_block<0 || first_block>7 ) { cerr << "ERROR: expecting block (0-7) after -block argument\n"; return 3; }
			last_block=first_block; continue; 
		}
		if( strcmp(argv[k],"-mul")==0 ) { 
			if( ++k==argc ) { cerr << "ERROR: expecting mul (0-15) after -mul argument\n"; return 3; }
			if( sscanf( argv[k], "%d", &mul)!=1 ) { cerr << "ERROR: expecting mul (0-15) after -mul argument\n"; return 3; }
			if( mul<0 || mul>15 ) { cerr << "ERROR: expecting mul (0-15) after -mul argument\n"; return 3; }
			continue;
		}
		if( strcmp(argv[k],"-pms")==0 ) { 
			if( ++k==argc ) { cerr << "ERROR: expecting pms (0-7) after -pms argument\n"; return 3; }
			if( sscanf( argv[k], "%d", &pms)!=1 ) { cerr << "ERROR: expecting pms (0-7) after -pms argument\n"; return 3; }
			if( pms<0 || pms>7 ) { cerr << "ERROR: expecting pms (0-7) after -pms argument\n"; return 3; }
			do_pm = true;
			continue;
		}		
		cout << "ERROR: unknown argument " << argv[k] << '\n';
		return 2;
	}
	//                   0  1   2   3    4   5   6   7   8     9    10
	int fnum_test[] = { 654,692,734,823,872,924,979,1038,1099,1165,1234 };
	top.reset();
	top.pms = pms;
	for( top.mul = first_mul; top.mul<=last_mul; top.mul++)
	for( top.block=first_block; top.block<=last_block; top.block++) {
	for( int k=first_note; k<=last_note; k++ ) 
	{
		top.lfo_mod= top.detune=0;
		top.fnum = fnum_test[k];
		top.phase_in = 0;
		float base_freq = get_freq(top);

		printf("(%2d) %d,%2d, %4d,", top.mul, top.block, top.keycode&3, top.fnum );
		printf("%4.1fHz -> ", base_freq );
		if( do_detune ) {
			for( top.detune=1; top.detune<8; top.detune++ ) {
				if( top.detune==4 ) continue;
				float detune_freq = get_freq(top) - base_freq;
				printf("%.3f, ", detune_freq );
			}}
		if( do_pm ) {
			int offsets[] = {0x17,0x07};
			for( int j=0; j<sizeof(offsets)/sizeof(int); j++  ) {
				top.lfo_mod=offsets[j];
				float interval = get_freq(top) / base_freq;
				if( interval==0 )
					cout << "N/A, ";
				else {
					float cent = 3986*log10(interval);
					printf("%.2f cent, ", cent );
				}
			}
		}
		cout << '\n';
	}}

	quit:
	return err_code;
}
