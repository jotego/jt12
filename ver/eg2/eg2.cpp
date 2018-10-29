#include <iostream>
#include "Veg_comb.h"

using namespace std;

class Stim {
public:
	int state, arate, base_rate, keycode,
		eg_cnt, cnt_in, ks, eg_in, lfo_mod,
		amsen, ams, tl;
	void reset();
	void apply(Veg_comb* dut);
	Stim() { reset(); }
};

void Stim::reset() {
	state=0, arate=0, base_rate=0, keycode=0,
	eg_cnt=0, cnt_in=0, ks=0, eg_in=0, lfo_mod=0,
	amsen=0, ams=0, tl=0;
}

void Stim::apply(Veg_comb* dut) {
	dut->state=state;
	dut->arate=arate;
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

float egcnt2us( int cnt, float phim=6.7e6 ) {
	float t = cnt;
	t /= phim;
	return t*3*24;
}

int main() {
	Veg_comb* top = new Veg_comb;
	Stim stim;
	// Try attack
	stim.reset();	
	stim.apply(top);
	for( stim.arate=1; stim.arate<32; stim.arate++ )
	for( stim.ks=0; stim.ks<4; stim.ks++ )
	for( stim.keycode=0; stim.keycode<32; stim.keycode++ )
	{
		stim.eg_in=0x3ff;
		stim.eg_cnt = 0;
		int max_rep = 1000000;
		bool report = true;
		while( max_rep-- ) {
			stim.apply(top);
			top->eval();
			stim.cnt_in = top->cnt_lsb;
			int new_eg = top->eg_limited;
			if( new_eg >= stim.eg_in ) {
				cout << "ERROR:EG direction reversed during attack phase\n";
				return 1;
			}
			if( new_eg == 0 && report ) {
				cout << hex << stim.arate << "," << stim.ks << ',' << stim.keycode
					<< ',' << stim.eg_cnt << '\n';
			}
			stim.eg_in = new_eg;
			stim.eg_cnt++;
		}

	}
	return 0;
}
