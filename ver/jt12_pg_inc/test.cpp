#include <cstring>
#include <iostream>
#include <iomanip>
#include "Vjt12_pg_inc.h"
#include "verilated_vcd_c.h"

using namespace std;


vluint64_t main_time = 0;
double sc_time_stamp () { return main_time; }


class Top {
	Vjt12_pg_inc *dut;
	VerilatedVcdC* vcd;
	bool tracing;
public:
	int block, detune, mul, fnum, phase_in, pg_rst, pm_offset;
	int keycode, phase_out, phase_op;
	void reset();
	void apply();
	void get();
	void trace_on();
	void next();
	void trace();
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
	phase_in = phase_out;
}

Top::Top() {
	dut = new Vjt12_pg_inc;
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
	block = detune = mul = fnum = phase_in = pg_rst = pm_offset = 0;
	// get outputs for initial values:
	dut->eval();
	get();
}

void Top::apply() {
	dut->block 		= block;
	dut->detune 	= detune;
	dut->mul 		= mul;
	dut->fnum 		= fnum;
	dut->phase_in 	= phase_in;
	dut->pg_rst 	= pg_rst;
	dut->pm_offset 	=pm_offset;
}

void Top::get() {
	keycode		= dut->keycode;
	phase_out	= dut->phase_out;
	phase_op	= dut->phase_op;
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
	int repeats=200; // needs to repeat many cycles 
		// to get precision for detune results
	const int max_ticks=(1<<24)-1;
	for(int k=0; k<repeats && ticks<max_ticks; k++ ) {
		int last_phase = -1;
		while( last_phase < top.phase_op && ticks<max_ticks ) {
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
	
	for(int k=1; k<argc; k++ ) {
		if( strcmp(argv[k],"-w")==0 ) { top.trace_on(); continue; }
		if( strcmp(argv[k],"-dt")==0 ) { do_detune=true; continue; }
		if( strcmp(argv[k],"-pm")==0 ) { do_pm=true; continue; }
		if( strcmp(argv[k],"-note")==0 ) { 
			if( ++k==argc ) { cerr << "ERROR: expecting note (0-10) after -note argument\n"; return 3; }
			if( sscanf( argv[k], "%d", &first_note)!=1 ) { cerr << "ERROR: expecting note (0-10) after -note argument\n"; return 3; }
			if( first_note<0 || first_note>10 ) { cerr << "ERROR: expecting note (0-10) after -note argument\n"; return 3; }
			last_note=first_note; continue; 
		}
		cout << "ERROR: unknown argument " << argv[k] << '\n';
		return 2;
	}
	//                   0  1   2   3    4   5   6   7   8     9    10
	int fnum_test[] = { 654,692,734,823,872,924,979,1038,1099,1165,1234 };
	top.reset();
	//for( top.block=0; top.block<8; top.block++) {
	top.block=5; {
	for( int k=first_note; k<=last_note; k++ ) 
	{
		top.pm_offset= top.detune=0;
		top.fnum = fnum_test[k];
		float base_freq = get_freq(top);

		printf("%d,%2d,%4d,", top.block, top.keycode&3, top.fnum );
		printf("%4.1fHz -> ", base_freq );
		if( do_detune ) {
			for( top.detune=1; top.detune<8; top.detune++ ) {
				if( top.detune==4 ) continue;
				float detune_freq = get_freq(top) - base_freq;
				printf("%.3f, ", detune_freq );
			}}
		if( do_pm ) {
			int offsets[] = {0xc0,0x40};
			for( int j=0; j<sizeof(offsets)/sizeof(int); j++  ) {
				top.pm_offset=offsets[j];
				float pm_freq = get_freq(top) - base_freq;
				printf("%.3f, ", pm_freq );
			}
		}
		cout << '\n';
	}}

	quit:
	return err_code;
}
