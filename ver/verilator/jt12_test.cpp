#include <iostream>
#include <fstream>
#include <string>
#include "Vjt12.h"
#include "verilated_vcd_c.h"

  // #include "verilated.h"

using namespace std;

const int PERIOD=100;
const int SEMIPERIOD=50;
const int CLKSTEP=10;

vluint64_t main_time = 0;	   // Current simulation time
// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  You can also use a double, if you wish.

double sc_time_stamp () {	   // Called by $time in Verilog
   return main_time;		   // converts to double, to match
							   // what SystemC does
}

class Gym {
	ifstream file;	
public:
	char cmd, val, addr;
	void open(const char *filename);
	int parse();
};

void Gym::open(const char* filename) {
	file.open(filename,ios_base::binary);	
	if ( !file.good() ) cout << "Failed to open file: " << filename << '\n';
	cout << "Open " << filename << '\n';
	cmd = val = addr = 0;
}

int Gym::parse() {
	char c;
	do {
		if( ! file.good() ) return -1; // finish
		file.read( &c, 1);
		// cout << "Read "	<< (int)c << '\n';
		// cout << (int) c << " @ " << file.tellg() << '\n';
		switch(c) {
			case 0: 
				return 1; // wait 16.7ms
			case 3: {
				file.read(&c,1);
				unsigned p = (unsigned char)c;
				cerr << "Attempt to write to PSG port " << p << endl;
				continue;
			}
			case 1:
			case 2:	{
				char buf[2];
				file.read(buf,2);
				cmd = buf[0];
				val = buf[1];
				addr = (c == 2); // if c==2 then write to top bank of JT12
				return 0;
			}
			default:
				cerr << "Wrong code ( " << ((int)c) << ") in GYM file\n";
				continue;
		}
	}while(file.good());
	cout << "Done\n";
	return -1;
}

int main(int argc, char** argv, char** env) {
	Verilated::commandArgs(argc, argv);
	Vjt12* top = new Vjt12;
	bool trace = false;
	Gym gym;

	for( int k=0; k<argc; k++ ) {
		if( string(argv[k])=="--trace" ) { trace=true; continue; }
		if( string(argv[k])=="--gym" ) { gym.open(argv[++k]); continue; }
	}

	VerilatedVcdC* tfp = new VerilatedVcdC;
	if( trace ) {
		Verilated::traceEverOn(true);
		top->trace(tfp,99);
		tfp->open("jt12_test.vcd");	
	}

	// Reset
	top->rst = 1;
	top->clk = 0;
	top->cen = 1;
	top->din = 0;
	top->addr = 0;
	top->cs_n = 0;
	top->wr_n = 1;
	top->limiter_en=0;
	cout << "Reset\n";
	while( main_time < 256*PERIOD ) {
		top->eval();
		if( main_time%SEMIPERIOD==0 ) top->clk = 1-top->clk;
		main_time++;
		// if(trace) tfp->dump(main_time);
	}
	top->rst = 0;
	int last_a=0;
	enum { WRITE_REG, WRITE_VAL, WAIT_FINISH } state;
	state = WRITE_REG;
	
	vluint64_t clk_time = main_time+SEMIPERIOD;
	bool wait_nonzero=true;
	const int check_step = 200;
	int next_check=check_step;
	int reg, val;
	bool fail=true;
	cout << "Main loop\n";
	vluint64_t wait=0;
	int last_sample=0;
	ofstream fsnd("jt12_test.out", ios_base::binary);
	// main loop
	while( true ) {
		top->eval();
		if( clk_time==main_time ) {
			int clk = top->clk;
			clk_time = main_time+SEMIPERIOD;
			top->clk = 1-clk;
			// int dout = top->dout;
			if( last_sample != top->snd_sample &&  top->snd_sample ) {
				int16_t snd[2];
				snd[0] = (int16_t)top->snd_left;
				snd[1] = (int16_t)top->snd_right;
				fsnd.write( (char*)snd, sizeof(int16_t)*2 );
			}
			last_sample = top->snd_sample;
			if( main_time < wait ) continue;

			int action = gym.parse();
			switch( action ) {
				default: 
					// cout << "File read\n";
					goto finish;
				case 0: 
					// cout << "CMD= " << (int) gym.cmd << '\n';
					break; // parse register
				case 1: 
					// cout << "Waiting\n";
					wait=main_time+16700000; 
					break;// wait 16.7ms					
			}		
		}
		main_time+=CLKSTEP;
		if(trace && (main_time%SEMIPERIOD==0)) { tfp->dump(main_time); }
	}
finish:
	cout << "$finish: #" << dec << main_time << '\n';
	if(trace) tfp->close();	
	delete top;
 }