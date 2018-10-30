#include <cstring>
#include <iostream>
#include "Vtest.h"
#include "verilated_vcd_c.h"

using namespace std;

class Stim {
public:
	// inputs
	int keyon_now, keyoff_now, state_in, eg_in, arate, rate1, rate2, rrate, sl, ssg_en,
		ssg_eg, ssg_inv_in, ssg_lock_in, keycode, eg_cnt, cnt_in, ks,
		lfo_mod, amsen, ams, tl;
	// outputs
	int ssg_inv_out, ssg_lock_out, state_next, pg_rst, cnt_lsb, pure_eg_out, eg_out;
	void reset();
	void apply(Vtest* dut);
	void get(Vtest* dut);
	void next(Vtest* dut);
	Stim() { reset(); }
};

void Stim::reset() {
	keyon_now=0, keyoff_now=0, state_in=0, eg_in=0x3ff, arate=0, rate1=0, 
	rate2=0, rrate=0, sl=0, ssg_en=0,
	ssg_eg=0, ssg_inv_in=0, ssg_lock_in=0, keycode=0, eg_cnt=0, cnt_in=0, ks=0,
	lfo_mod=0, amsen=0, ams=0, tl=0;
}

void Stim::apply(Vtest* dut) {
	dut->keyon_now	= keyon_now;
	dut->keyoff_now	= keyoff_now;
	dut->state_in	= state_in;
	dut->eg_in		= eg_in;
	dut->arate		= arate;
	dut->rate1		= rate1;
	dut->rate2		= rate2;
	dut->rrate		= rrate;
	dut->sl			= sl;
	dut->ssg_en		= ssg_en;
	
	dut->ssg_eg		= ssg_eg;
	dut->ssg_inv_in	= ssg_inv_in;
	dut->ssg_lock_in= ssg_lock_in;
	dut->keycode	= keycode;
	dut->eg_cnt		= eg_cnt;
	dut->cnt_in		= cnt_in;
	dut->ks			= ks;
	
	dut->lfo_mod	= lfo_mod;
	dut->amsen		= amsen;
	dut->ams		= ams;
	dut->tl			= tl;
}

void Stim::get(Vtest* dut) {
	ssg_inv_out	= dut->ssg_inv_out;
	ssg_lock_out= dut->ssg_lock_out;
	state_next	= dut->state_next;
	pg_rst		= dut->pg_rst;
	cnt_lsb		= dut->cnt_lsb;
	pure_eg_out	= dut->pure_eg_out;
	eg_out		= dut->eg_out;
}

vluint64_t main_time = 0;	   // Current simulation time

void Stim::next(Vtest* dut) {
	apply(dut);
	dut->eval();
	main_time+=22*3;
	get(dut);
	state_in = state_next;
	ssg_inv_in = ssg_inv_out;
	ssg_lock_in = ssg_inv_out;
	eg_in = pure_eg_out;
	cnt_in = cnt_lsb;
	eg_cnt++;
}


float egcnt2us( int cnt, float phim=7.6e6 ) {
	float t = cnt;
	t /= phim;
	return t*3*24*6;
}


double sc_time_stamp () {	   // Called by $time in Verilog
   return main_time;		   // converts to double, to match
							   // what SystemC does
}

int main(int argc, char *argv[]) {
	Vtest* top = new Vtest;
	Stim stim;
	int err_code=0;
	VerilatedVcdC* vcd = new VerilatedVcdC;
	bool trace=false;
	// bool do_attack=true, do_decay=true,do_am=true;

	for(int k=1; k<argc; k++ ) {
		if( strcmp(argv[k],"-w")==0 ) { trace=true; continue; }
		// if( strcmp(argv[k],"-noar")==0 ) { do_attack=false; continue; }
		// if( strcmp(argv[k],"-nodr")==0 ) { do_decay=false; continue; }
		// if( strcmp(argv[k],"-noam")==0 ) { do_am=false; continue; }
		cout << "ERROR: unknown argument " << argv[k] << '\n';
		err_code = 2;
		goto quit;
	}

	if( trace ) {
		Verilated::traceEverOn(true);
		top->trace(vcd,99);
		vcd->open("test.vcd");	
	}	
	// Try attack
	stim.reset();
	stim.arate = 0x10;
	stim.rate1 = 0x7;
	stim.sl = 7;
	stim.rate2 = 0;
	stim.rrate = 0x8;
	stim.keyon_now = 1;
	// time 0 state:
	stim.apply(top); top->eval();
	if(trace) vcd->dump(main_time);

	do {
		stim.next( top );
		stim.keyon_now = 0;
		if(trace) vcd->dump(main_time);
	} while( main_time<5'000'000 );
	stim.keyoff_now = 1;
	stim.next( top );
	if(trace) vcd->dump(main_time);
	stim.keyoff_now = 0;
	do {
		stim.next( top );
		if(trace) vcd->dump(main_time);
	} while( main_time<10'000'000 );

	quit:
	if(trace) vcd->close();	
	// VerilatedCov::write("logs/coverage.dat");
	delete vcd;
	delete top;
	return err_code;
}
