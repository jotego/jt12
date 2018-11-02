#include <cstring>
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
	int keycode, phase_out, phase_op;
	void reset();
	void apply();
	void get();
	void trace_on();
	void next();
	void trace();
	void feedback();
	Top();
	~Top();
};

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
	int mul=1;
	
	for(int k=1; k<argc; k++ ) {
		if( strcmp(argv[k],"-w")==0 ) { top.trace_on(); continue; }
		if( strcmp(argv[k],"-dt")==0 ) { do_detune=true; continue; }
		if( strcmp(argv[k],"-pm")==0 ) { do_pm=true; continue; }
		if( strcmp(argv[k],"-mul")==0 ) { first_mul=0; last_mul=15; continue; }
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
		cout << "ERROR: unknown argument " << argv[k] << '\n';
		return 2;
	}
	//                   0  1   2   3    4   5   6   7   8     9    10
	int fnum_test[] = { 654,692,734,823,872,924,979,1038,1099,1165,1234 };
	top.reset();
	for( top.mul = first_mul; top.mul<=last_mul; top.mul++)
	for( top.block=first_block; top.block<=last_block; top.block++) {
	for( int k=first_note; k<=last_note; k++ ) 
	{
		top.lfo_mod= top.detune=0;
		top.fnum = fnum_test[k];
		float base_freq = get_freq(top);

		printf("(%2d) %d,%2d,%4d,", top.mul, top.block, top.keycode&3, top.fnum );
		printf("%4.1fHz -> ", base_freq );
		if( do_detune ) {
			for( top.detune=1; top.detune<8; top.detune++ ) {
				if( top.detune==4 ) continue;
				float detune_freq = get_freq(top) - base_freq;
				printf("%.3f, ", detune_freq );
			}}
		if( do_pm ) {
			int offsets[] = {0x1f,0x0f};
			for( int j=0; j<sizeof(offsets)/sizeof(int); j++  ) {
				top.lfo_mod=offsets[j];
				float pm_freq = get_freq(top) - base_freq;
				printf("%.3f, ", pm_freq );
			}
		}
		cout << '\n';
	}}

	quit:
	return err_code;
}
