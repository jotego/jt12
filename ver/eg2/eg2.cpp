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

int main() {
	Veg_comb* top = new Veg_comb;
	Stim stim;
	VerilatedVcdC* vcd = new VerilatedVcdC;
	bool trace=false;
	if( trace ) {
		Verilated::traceEverOn(true);
		top->trace(vcd,99);
		vcd->open("test.vcd");	
	}	
	// Try attack
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
				return 1;
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
	if(trace) vcd->close();	
	VerilatedCov::write("logs/coverage.dat");
	return 0;
}
