#include <cstring>
#include <iostream>
#include "Veg_comb.h"
#include "verilated_vcd_c.h"

using namespace std;

class Stim {
public:
	int attack, base_rate, keycode,
		eg_cnt, cnt_in, ks, eg_in, lfo_mod,
		amsen, ams, tl;
	void reset();
	void apply(Veg_comb* dut);
	Stim() { reset(); }
};

void Stim::reset() {
	attack=0, base_rate=0, keycode=0,
	eg_cnt=0, cnt_in=0, ks=0, eg_in=0, lfo_mod=0,
	amsen=0, ams=0, tl=0;
}

void Stim::apply(Veg_comb* dut) {
	dut->attack=attack;
	dut->base_rate=base_rate;
	dut->keycode=keycode;
	dut->eg_cnt=eg_cnt;
	dut->cnt_in=cnt_in;
	dut->ks=ks;
	dut->eg_in=eg_in;
	dut->lfo_mod=lfo_mod;
	dut->amsen=amsen;
	dut->ams=ams;
	dut->tl=tl;
}

float egcnt2us( int cnt, float phim=7.6e6 ) {
	float t = cnt;
	t /= phim;
	return t*3*24*6;
}

vluint64_t main_time = 0;	   // Current simulation time
// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  You can also use a double, if you wish.

double sc_time_stamp () {	   // Called by $time in Verilog
   return main_time;		   // converts to double, to match
							   // what SystemC does
}

int main(int argc, char *argv[]) {
	Veg_comb* top = new Veg_comb;
	Stim stim;
	int err_code=0;
	VerilatedVcdC* vcd = new VerilatedVcdC;
	bool trace=false;
	bool do_attack=true, do_decay=true,do_am=true;

	for(int k=1; k<argc; k++ ) {
		if( strcmp(argv[k],"-w")==0 ) { trace=true; continue; }
		if( strcmp(argv[k],"-noar")==0 ) { do_attack=false; continue; }
		if( strcmp(argv[k],"-nodr")==0 ) { do_decay=false; continue; }
		if( strcmp(argv[k],"-noam")==0 ) { do_am=false; continue; }
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
	if( !do_attack ) goto decay;
	stim.reset();
	stim.attack=1;
	stim.apply(top);
	for( stim.base_rate=1; stim.base_rate<32; stim.base_rate++ )
	for( stim.ks=0; stim.ks<4; stim.ks++ )
	for( stim.keycode=0; stim.keycode<32; stim.keycode++ )
	{
		stim.eg_in=0x3ff;
		stim.eg_cnt = 0;
		stim.cnt_in = 1;
		int max_rep = 1'000'000;
		bool report = true;
		while( --max_rep>0 ) {
			stim.apply(top);
			top->eval(); main_time += 10;
			stim.cnt_in = top->cnt_lsb;
			int new_eg = top->eg_limited;
			if( new_eg > stim.eg_in ) {
				cout << "ERROR:EG direction reversed during attack phase\n";
				err_code = 1;
				goto quit;
			}
			if( new_eg == 0 && report ) {
				cout << hex << stim.base_rate << "," << stim.ks << ',' << stim.keycode
					<< ',' << dec << stim.eg_cnt*24 << "," << egcnt2us(stim.eg_cnt) << "\n";
				report=false;
			}
			if( new_eg==0 ) max_rep-=10'000;
			stim.eg_in = new_eg;
			stim.eg_cnt++;
			if(trace) vcd->dump(main_time);
		}
		if( report ) {
			cout << hex << stim.base_rate << "," << stim.ks << ',' << stim.keycode
				<< ',' << "N/A" << '\n';
		}
	}
	decay:
	if( !do_decay ) goto am;
	// Try decay
	stim.reset();
	stim.apply(top);
	for( stim.base_rate=1; stim.base_rate<32; stim.base_rate++ )
	for( stim.ks=0; stim.ks<4; stim.ks++ )
	for( stim.keycode=0; stim.keycode<32; stim.keycode++ )
	{
		stim.eg_in  = 0;
		stim.eg_cnt = 0;
		stim.cnt_in = 1;
		int max_rep = 10'000'000;
		bool report = true;
		while( --max_rep>0 ) {
			stim.apply(top);
			top->eval(); main_time += 10;
			stim.cnt_in = top->cnt_lsb;
			int new_eg = top->eg_limited;
			if( new_eg < stim.eg_in ) {
				cout << "ERROR:EG direction reversed during decay phase\n";
				err_code = 1;
				goto quit;
			}
			if( new_eg == 0x3ff && report ) {
				cout << hex << stim.base_rate << "," << stim.ks << ',' << stim.keycode
					<< ',' << dec << stim.eg_cnt*24 << "," << egcnt2us(stim.eg_cnt) << "\n";
				report=false;
			}
			if( new_eg==0x3ff ) max_rep-=100'000;
			stim.eg_in = new_eg;
			stim.eg_cnt++;
			if(trace) vcd->dump(main_time);
		}
		if( report ) {
			cout << hex << stim.base_rate << "," << stim.ks << ',' << stim.keycode
				<< ',' << "N/A" << '\n';
		}
	}	
	am:
	if(!do_am) goto total_level;
	stim.reset();
	// check for overflow when eg_in is at one limit
	stim.eg_in=0x3ff;
	stim.amsen=1;
	stim.apply(top);
	for( stim.attack=0; stim.attack<2; stim.attack++ )
	for( stim.ams=0; stim.ams<4; stim.ams++ )
	for( stim.tl=0; stim.tl<128; stim.tl++ )
	for( stim.lfo_mod=0; stim.lfo_mod<128; stim.lfo_mod++ ) {
		stim.apply(top);
		top->eval(); main_time+=10;
		stim.cnt_in = top->cnt_lsb;
		int new_eg = top->eg_limited;
		if( new_eg != 0x3ff ) {
			cout << "ERROR: AM overflow when EG is 0x3ff\n";
			err_code = 1;
			goto quit;
		}
	}
	stim.reset();
	// check for overflow when eg_in is at one limit
	stim.eg_in=0;
	stim.amsen=0;
	stim.apply(top);
	for( stim.attack=0; stim.attack<2; stim.attack++ )
	for( stim.ams=0; stim.ams<4; stim.ams++ )
	for( stim.tl=0; stim.tl<128; stim.tl++ )
	for( stim.lfo_mod=0; stim.lfo_mod<128; stim.lfo_mod++ ) {
		stim.apply(top);
		top->eval(); main_time+=10;
		stim.cnt_in = top->cnt_lsb;
		int new_eg = top->eg_limited;
		if( new_eg != (stim.tl<<3) ) {
			cout << "ERROR: AM had an effect when it was supposed to be zero\n";
			err_code = 1;
			goto quit;
		}
	}
	// check for overflow when eg_in is at the other limit
	stim.reset();
	stim.eg_in=0x0;
	stim.amsen=1;
	stim.apply(top);
	for( stim.attack=0; stim.attack<2; stim.attack++ )
	for( stim.ams=0; stim.ams<4; stim.ams++ ) {
		int min_am=0x3ff, max_am=0;
		for( stim.lfo_mod=0; stim.lfo_mod<128; stim.lfo_mod++ ) {
			stim.apply(top);
			top->eval(); main_time+=10;
			stim.cnt_in = top->cnt_lsb;
			int new_eg = top->eg_limited;
			if( new_eg < min_am ) min_am = new_eg;
			if( new_eg > max_am ) max_am = new_eg;
		}
		// cout << hex << stim.ams << ',' << stim.lfo_mod << ',' << new_eg << '\n';
		cout << hex << stim.ams << ',' << min_am*.09375 << ',' << max_am*.09375;
		if( min_am != 0 ) cout << " * min AM should be 0. ";
		cout <<'\n';
	}
	///////////////////////////////
	total_level:
	stim.reset();
	stim.apply(top);
	for( stim.attack=0; stim.attack<2; stim.attack++ )
	for( stim.tl=0; stim.tl<128; stim.tl++ ) {
		stim.apply(top);
		top->eval(); main_time+=10;
		stim.cnt_in = top->cnt_lsb;
		int new_eg = top->eg_limited;
		if( new_eg != (stim.tl<<3) ) {
			cout << "ERROR: incorrect total level value\n";
			err_code = 1;
			goto quit;
		}
	}
	quit:
	if(trace) vcd->close();	
	VerilatedCov::write("logs/coverage.dat");
	delete vcd;
	delete top;
	return err_code;
}
