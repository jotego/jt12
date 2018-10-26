#include <cstdio>
#include <iostream>
#include <fstream>
#include <string>
#include <string>
#include <list>
#include "Vjt12.h"
#include "verilated_vcd_c.h"
#include "VGMParser.hpp"

  // #include "verilated.h"

using namespace std;

const int PERIOD=784; // use with -DFASTDIV
const int SEMIPERIOD=392;
const int CLKSTEP=196;

vluint64_t main_time = 0;	   // Current simulation time
// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  You can also use a double, if you wish.

double sc_time_stamp () {	   // Called by $time in Verilog
   return main_time;		   // converts to double, to match
							   // what SystemC does
}


class CmdWritter {
	int addr, cmd, val;
	Vjt12 *top;
	bool done;
	int last_clk;
	int state;
	int watch_addr, watch_ch;
public:
	CmdWritter( Vjt12* _top );
	void Write( int _addr, int _cmd, int _val );
	void watch( int addr, int ch ) { watch_addr=addr; watch_ch=ch; }
	void Eval();
	bool Done() { return done; }
};

CmdWritter::CmdWritter( Vjt12* _top ) {
	top  = _top;
	last_clk = 0;
	done = true;
}

void CmdWritter::Write( int _addr, int _cmd, int _val ) {
	// cout << "Writter command\n";
	addr = _addr;
	cmd  = _cmd;
	val  = _val;
	done = false;
	state = 0;
	if( addr == watch_addr && cmd>=(char)0x30 && (cmd&0x3)==watch_ch )
		cout << addr << '-' << watch_ch << " CMD = " << hex << (cmd&0xff) << " VAL = " << (val&0xff) << '\n';
	// cout << addr << '\t' << hex << "0x" << ((unsigned)cmd&0xff);
	// cout  << '\t' << ((unsigned)val&0xff) << '\n' << dec;
}

void CmdWritter::Eval() {	
	int clk = top->clk;	
	if( (clk==0) && (last_clk != clk) ) {
		switch( state ) {
			case 0: 
				top->addr = addr ? 2 : 0;
				top->din = cmd;
				top->wr_n = 0;
				state=1;
				break;
			case 1:
				top->wr_n = 1;
				state = 2;
				break;
			case 2:
				top->addr = ((int)top->addr) + 1;
				top->din = val;
				top->wr_n = 0;
				state = 3;
				break;
			case 3:
				top->wr_n = 1;
				state=4;
				break;
			case 4:				
				if( (((int)top->dout) &0x80 ) == 0 ) {
					done = true;
					state=5;
				}
				break;
			default: break;
		}
	}
	last_clk = clk;
}

struct YMcmd { int addr; int cmd; int val; };

int main(int argc, char** argv, char** env) {
	Verilated::commandArgs(argc, argv);
	Vjt12* top = new Vjt12;
	bool trace = false;
	RipParser *gym;
	bool forever=true;
	vluint64_t time_limit=0;

	for( int k=0; k<argc; k++ ) {
		if( string(argv[k])=="--trace" ) { trace=true; continue; }
		if( string(argv[k])=="--gym" ) { 
			string filename(argv[++k]);
			auto ext = filename.find_last_of('.');
			if( ext == string::npos ) {
				cout << "The filename must end in .gym or .vgm\n";
				return 1;
			}
			if( filename.substr(ext)==".gym") {
				gym = new Gym(); gym->open(argv[k]); 
				continue; 
			}
			if( filename.substr(ext)==".vgm") {
				gym = new VGMParser(); gym->open(argv[k]); 
				continue; 
			}
			cout << "The filename must end in .gym or .vgm\n";
			return 1;
		}
		if( string(argv[k])=="--time" ) { 
			int aux;
			sscanf(argv[++k],"%d",&aux);
			time_limit = aux*1000000;
			forever=false;
			cout << "Simulate until " << aux << "ms\n";
			continue; 
		}
	}

	if( gym->length() != 0 && time_limit == 0 ) time_limit=gym->length();

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
	vluint64_t timeout=0;
	bool wait_nonzero=true;
	const int check_step = 200;
	int next_check=check_step;
	int reg, val;
	bool fail=true;
	cout << "Main loop\n";
	vluint64_t wait=0;
	int last_sample=0;
	ofstream fsnd("jt12_test.wav", ios_base::binary);
	// write header
	char zero=0;
	for( int k=0; k<45; k++ ) fsnd.write( &zero, 1 );
	fsnd.seekp(0);
	fsnd.write( "RIFF", 4 );
	fsnd.seekp(8);
	fsnd.write( "WAVEfmt ", 8 );
	int32_t number32 = 16;
	fsnd.write( (char*)&number32, 4 );
	int16_t number16 = 1;
	fsnd.write( (char*) &number16, 2);
	number16=2;
	fsnd.write( (char*) &number16, 2);
	number32 = 48000; // should be 52847
	fsnd.write( (char*)&number32, 4 );
	number32 = 48000*2*2; 
	fsnd.write( (char*)&number32, 4 );
	number16=2*2;	// Block align
	fsnd.write( (char*) &number16, 2);
	number16=16;
	fsnd.write( (char*) &number16, 2);
	fsnd.write( "data", 4 );
	fsnd.seekp(44);	

	// forced values
	list<YMcmd> forced_values;
	// forced_values.push_back( {0, 0xb4, 0x40} );
	// forced_values.push_back( {0, 0xb5, 0x40} );
	// forced_values.push_back( {0, 0xb6, 0x40} );
	// forced_values.push_back( {1, 0xb4, 0x80} ); // canal malo
	// forced_values.push_back( {1, 0xb5, 0x40} );
	// forced_values.push_back( {1, 0xb6, 0x40} ); // no es
	// main loop
	CmdWritter writter(top);
	// writter.watch( 1, 0 ); // top bank, channel 0
	bool skip_zeros=true;
	while( forever || main_time < time_limit ) {
		top->eval();
		if( clk_time==main_time ) {
			int clk = top->clk;
			clk_time = main_time+SEMIPERIOD;
			top->clk = 1-clk;
			// int dout = top->dout;
			if( last_sample != top->snd_sample &&  top->snd_sample ) {
				int16_t snd[2];
				// snd[0] = (top->snd_left & 0x800) ? (top->snd_left|0xf000) : top->snd_left;
				// snd[1] = (top->snd_right & 0x800) ? (top->snd_right|0xf000) : top->snd_right;
				snd[0] = top->snd_left << 4;
				snd[1] = top->snd_right << 4;
				// skip initial set of zero's
				if( skip_zeros && snd[0]==0 && snd[1] == 0 ) continue;
				else skip_zeros=false;
				// cout << (int)snd[0] << '\n';
				fsnd.write( (char*)snd, sizeof(int16_t)*2 );
			}
			last_sample = top->snd_sample;
			writter.Eval();

			if( timeout!=0 && main_time>timeout ) {				
				cout << "Timeout waiting for BUSY to clear\n";
				cout << "writter.done == " << writter.Done() << '\n';
				goto finish;
			}
			if( main_time < wait ) continue;
			if( !writter.Done() ) continue;

			if( !forced_values.empty() ) {
				const YMcmd &c = forced_values.front();
				cout << "Forced value\n";
				writter.Write( c.addr, c.cmd, c.val );
				forced_values.pop_front();
				continue;
			}

			int action = gym->parse();
			switch( action ) {
				default: 
					// cout << "File read\n";
					if( main_time < time_limit && time_limit!=0 ) continue;
					goto finish;
				case 0: 
					// if( /*(gym->cmd&(char)0xfc)==(char)0xb4 ||*/
					// /*(gym->addr==0 && gym->cmd>=(char)0x30) || */
					// ((gym->cmd&(char)0xf0)==(char)0x90)) {
					// 	 cout << "Skipping write to " << hex << (gym->cmd&0xff) << " register\n" ;
					// 	break; // do not write to RL register
					// }
					// cout << hex << (unsigned) gym->cmd << '\n';
					writter.Write( gym->addr, gym->cmd, gym->val );
					timeout = main_time + PERIOD*6*100;
					break; // parse register
				case 1: 
					// cout << "Waiting\n";
					wait=gym->wait;
					wait*=100000/441; // sample period in ns
					// cout << "Wait for " << dec << wait << "ns (" << wait/1000000 << " ms)\n";
					// if(trace) wait/=3;
					wait+=main_time;
					timeout=0;
					break;// wait 16.7ms	
				case -2: // unsupported command
					goto finish;				
			}		
		}
		main_time+=CLKSTEP;
		if(trace && (main_time%SEMIPERIOD==0)) { tfp->dump(main_time); }
	}
finish:
	if( skip_zeros ) {
		cout << "WARNING: Output wavefile is empty. No sound output was produced.\n";
	}
	streampos file_length = fsnd.tellp();
	number32 = (int32_t)file_length-8;
	fsnd.seekp(4);
	fsnd.write( (char*)&number32, 4);
	fsnd.seekp(40);
	number32 = (int32_t)file_length-44;
	fsnd.write( (char*)&number32, 4);
	cout << "$finish at " << dec << main_time/1000000 << "ms = " << main_time << " ns\n";
	if( gym->length() != 0 ) {
		float l = (float) gym->length()/1e6;
		cout << "Expected time from input file was " << l << "ms\n";
	}
	if(trace) tfp->close();	
	delete gym;
	delete top;
 }