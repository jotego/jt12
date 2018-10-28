#include <cstdio>
#include <iostream>
#include <fstream>
#include <string>
#include <string>
#include <list>
#include "Vjt12.h"
#include "verilated_vcd_c.h"
#include "VGMParser.hpp"
#include "feature.hpp"

  // #include "verilated.h"

using namespace std;

// const int PERIOD=130; // Must be an even number. use with -DFASTDIV
// const int PERIOD=132; // Must be an even number. use with -DFASTDIV
const int PERIOD=132*6; // Must be an even number. use with -DFASTDIV
const int SEMIPERIOD=PERIOD/2; // make sure result is an even number
const int CLKSTEP=SEMIPERIOD/2;
const int SAMPLERATE=48000; // 1.0e9/PERIOD/24;
const vluint64_t SAMPLING_PERIOD = 1e9/SAMPLERATE;

class SimTime {
	vluint64_t main_time, time_limit, fast_forward;
	vluint64_t main_next;
	int verbose_ticks;
	bool toggle;
public:
	SimTime() { 
		main_time=0; fast_forward=0; time_limit=0; toggle=false;
		verbose_ticks = 48000*24/2;
	}
	void set_time_limit(vluint64_t t) { time_limit=t; }
	bool limited() { return time_limit!=0; }
	vluint64_t get_time_limit() { return time_limit; }
	vluint64_t get_time() { return main_time; }
	int get_time_s() { return main_time/1000000000; }
	int get_time_ms() { return main_time/1000000; }
	bool next_quarter() {
		if( !toggle ) {
			main_next = main_time + SEMIPERIOD;
			main_time += CLKSTEP;
			toggle = true;
			return false; // toggle clock
		}
		else {
			main_time = main_next;
			if( --verbose_ticks == 0 ) {
				cout << "Current time " << dec << (int)(main_time/1000000) << " ms\n";				
				verbose_ticks = 48000*24/2;
			}
			toggle=false;
			return true; // do not toggle clock
		}
	}
	bool finish() { return main_time > time_limit && limited(); }
} sim_time;

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
	list<FeatureUse>features;
	struct Block_def{ int cmd_mask, cmd, val_and, val_or; };
	list<Block_def>blocks;
public:
	CmdWritter( Vjt12* _top );
	void Write( int _addr, int _cmd, int _val );
	void block( int cmd_mask, int cmd, int val_and, int val_or ) {
		Block_def aux;
		aux.cmd_mask = cmd_mask;
		aux.cmd = cmd;
		aux.val_and = val_and;
		aux.val_or = val_or;
		blocks.push_back( aux );
	};
	void watch( int addr, int ch ) { watch_addr=addr; watch_ch=ch; }
	void Eval();
	bool Done() { return done; }
	void report_usage();
};

class WaveWritter {
	ofstream fsnd;
public:
	WaveWritter(const char *filename);
	void write( int16_t *lr );
	~WaveWritter();
};

struct YMcmd { int addr; int cmd; int val; };

int main(int argc, char** argv, char** env) {
	Verilated::commandArgs(argc, argv);
	Vjt12* top = new Vjt12;
	CmdWritter writter(top);
	bool trace = false;
	RipParser *gym;
	bool forever=true;
	assert( PERIOD%2 == 0);

	for( int k=0; k<argc; k++ ) {
		if( string(argv[k])=="-trace" ) { trace=true; continue; }
		if( string(argv[k])=="-gym" ) { 
			string filename(argv[++k]);
			auto ext = filename.find_last_of('.');
			if( ext == string::npos ) {
				cout << "The filename must end in .gym or .vgm\n";
				return 1;
			}
			if( filename.substr(ext)==".gym") {
				gym = new Gym(PERIOD); gym->open(argv[k]); 
				continue; 
			}
			if( filename.substr(ext)==".vgm") {
				gym = new VGMParser(PERIOD); gym->open(argv[k]); 
				continue; 
			}
			if( filename.substr(ext)==".jtt") {
				gym = new JTTParser(PERIOD); gym->open(argv[k]); 
				continue; 
			}
			cout << "The filename must end in .gym or .vgm\n";
			return 1;
		}
		if( string(argv[k])=="-time" ) { 
			int aux;
			sscanf(argv[++k],"%d",&aux);
			vluint64_t time_limit = aux;
			time_limit *= 1000000;
			forever=false;
			cout << "Simulate until " << time_limit/1000000 << "ms\n";
			sim_time.set_time_limit( time_limit );
			continue; 
		}
		/*
		if( string(argv[k])=="-fast" ) { 
			int aux;
			sscanf(argv[++k],"%d",&aux);
			fast_forward = aux;
			fast_forward *= 1000000;
			fast_forward *= 1000;
			cout << "Fast forward until " << aux << "s\n";
			continue; 
		}
		*/
		if( string(argv[k])=="-noam" ) {
			writter.block( 0xF0, 0x60, 0x7F, 0 ); 
			continue;
		}
		if( string(argv[k])=="-noks") {
			writter.block( 0xF0, 0x50, 0x1F, 0 ); 
		}
		if( string(argv[k])=="-nomul") {
			cout << "All writes to MULT locked to 1\n";
			writter.block( 0xF0, 0x30, 0x70, 1 ); 
		}
	}

	if( gym->length() != 0 && !sim_time.limited() ) sim_time.set_time_limit( gym->length() );

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
	// cout << "Reset\n";
	while( sim_time.get_time() < 256*PERIOD ) {
		top->eval();
		if( sim_time.next_quarter() ) top->clk = 1-top->clk;
		// if(trace) tfp->dump(main_time);
	}
	top->rst = 0;
	int last_a=0;
	enum { WRITE_REG, WRITE_VAL, WAIT_FINISH } state;
	state = WRITE_REG;
	
	vluint64_t timeout=0;
	bool wait_nonzero=true;
	const int check_step = 200;
	int next_check=check_step;
	int reg, val;
	bool fail=true;
	// cout << "Main loop\n";
	vluint64_t wait=0;
	int last_sample=0;
	WaveWritter wav("jt12_test.wav");

	// forced values
	list<YMcmd> forced_values;
	// forced_values.push_back( {0, 0xb4, 0x40} );
	// forced_values.push_back( {0, 0xb5, 0x40} );
	// forced_values.push_back( {0, 0xb6, 0x40} );
	// forced_values.push_back( {1, 0xb4, 0x80} ); // canal malo
	// forced_values.push_back( {1, 0xb5, 0x40} );
	// forced_values.push_back( {1, 0xb6, 0x40} ); // no es
	// main loop
	// writter.watch( 1, 0 ); // top bank, channel 0
	bool skip_zeros=true;
	vluint64_t adjust_sum=0;
	int next_verbosity = 200;
	vluint64_t next_sample=0;
	while( forever || !sim_time.finish() ) {
		top->eval();
		if( sim_time.next_quarter() ) {
			int clk = top->clk;
			top->clk = 1-clk;
			// int dout = top->dout;
			if( sim_time.get_time() > next_sample ) {
				int16_t snd[2];
				// snd[0] = (top->snd_left & 0x800) ? (top->snd_left|0xf000) : top->snd_left;
				// snd[1] = (top->snd_right & 0x800) ? (top->snd_right|0xf000) : top->snd_right;
				snd[0] = top->snd_left << 4;
				snd[1] = top->snd_right << 4;
				// skip initial set of zero's
				if( !skip_zeros || snd[0]!=0 || snd[1] != 0 ) {
					skip_zeros=false;
					// cout << (int)snd[0] << '\n';
					wav.write( snd );
				}
				next_sample = sim_time.get_time() + SAMPLING_PERIOD;
			}
			last_sample = top->snd_sample;
			writter.Eval();

			if( timeout!=0 && sim_time.get_time()>timeout ) {				
				cout << "Timeout waiting for BUSY to clear\n";
				cout << "writter.done == " << writter.Done() << '\n';
				goto finish;
			}
			if( sim_time.get_time() < wait ) continue;
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
					if( !sim_time.finish() ) {
						cout << "go on\n";
						continue;
					}
					goto finish;
				case RipParser::cmd_write: 
					// if( /*(gym->cmd&(char)0xfc)==(char)0xb4 ||*/
					// /*(gym->addr==0 && gym->cmd>=(char)0x30) || */
					// ((gym->cmd&(char)0xf0)==(char)0x90)) {
					// 	 cout << "Skipping write to " << hex << (gym->cmd&0xff) << " register\n" ;
					// 	break; // do not write to RL register
					// }
					// cout << "CMD = " << hex << ((int)gym->cmd&0xff) << '\n';
					writter.Write( gym->addr, gym->cmd, gym->val );
					timeout = sim_time.get_time() + PERIOD*6*100;
					break; // parse register
				case RipParser::cmd_wait: 
					// cout << "Waiting\n";
					wait=gym->wait;
					// cout << "Wait for " << dec << wait << "ns (" << wait/1000000 << " ms)\n";
					// if(trace) wait/=3;
					wait+=sim_time.get_time();
					timeout=0;
					break;// wait 16.7ms	
				case RipParser::cmd_finish: // reached end of file
					goto finish;
				case RipParser::cmd_error: // unsupported command
					goto finish;				
			}		
		}
		if(trace) tfp->dump(sim_time.get_time());
	}
finish:
	writter.report_usage();
	if( skip_zeros ) {
		cout << "WARNING: Output wavefile is empty. No sound output was produced.\n";
	}

	if( main_time>1000000000 ) { // sim lasted for seconds
		cout << "$finish at " << dec << sim_time.get_time_s() << "s = " << sim_time.get_time_ms() << " ms\n";
	} else {
		cout << "$finish at " << dec << sim_time.get_time_ms() << "ms = " << sim_time.get_time() << " ns\n";
	}
	if(trace) tfp->close();	
	delete gym;
	delete top;
 }


void WaveWritter::write( int16_t* lr ) {
	fsnd.write( (char*)lr, sizeof(int16_t)*2 );
}

WaveWritter::WaveWritter(const char *filename) {
	fsnd.open(filename, ios_base::binary);
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
	number32 = SAMPLERATE; 
	fsnd.write( (char*)&number32, 4 );
	number32 = SAMPLERATE*2*2; 
	fsnd.write( (char*)&number32, 4 );
	number16=2*2;	// Block align
	fsnd.write( (char*) &number16, 2);
	number16=16;
	fsnd.write( (char*) &number16, 2);
	fsnd.write( "data", 4 );
	fsnd.seekp(44);	
}

WaveWritter::~WaveWritter() {
	int32_t number32;
	streampos file_length = fsnd.tellp();
	number32 = (int32_t)file_length-8;
	fsnd.seekp(4);
	fsnd.write( (char*)&number32, 4);
	fsnd.seekp(40);
	number32 = (int32_t)file_length-44;
	fsnd.write( (char*)&number32, 4);	
}


void CmdWritter::report_usage() {
	cout << "Features used: \t";
	for( const auto& k : features )
		if(k.is_used()) cout << k.name() << ' ';
	cout << '\n';
}

CmdWritter::CmdWritter( Vjt12* _top ) {
	top  = _top;
	last_clk = 0;
	done = true;
	features.push_back( FeatureUse("DT",   0xF0, 0x30, 0x70, [](char v)->bool{return v!=0;} ));
	features.push_back( FeatureUse("MULT", 0xF0, 0x30, 0x0F, [](char v)->bool{return v!=1;} ));
	features.push_back( FeatureUse("KS",   0xF0, 0x50, 0xC0, [](char v)->bool{return v!=0;} ));
	features.push_back( FeatureUse("AM",   0xF0, 0x60, 0x80, [](char v)->bool{return v!=0;} ));
	features.push_back( FeatureUse("SSG",  0xF0, 0x90, 0x08, [](char v)->bool{return v!=0;} ));
}

void CmdWritter::Write( int _addr, int _cmd, int _val ) {
	// cout << "Writter command\n";
	for( auto&k : blocks ) {
		char aux = _cmd;
		aux &= k.cmd_mask;
		if( aux == k.cmd ) {
			_val &= k.val_and;
			_val |= k.val_or;
			cout << "Blocked!\n";
		}
	}
	addr = _addr;
	cmd  = _cmd;
	val  = _val;
	done = false;
	state = 0;
	if( addr == watch_addr && cmd>=(char)0x30 && (cmd&0x3)==watch_ch )
		cout << addr << '-' << watch_ch << " CMD = " << hex << (cmd&0xff) << " VAL = " << (val&0xff) << '\n';
	for( auto& k : features )
		k.check( cmd, val );	
	// cout << addr << '\t' << hex << "0x" << ((unsigned)cmd&0xff);
	// cout  << '\t' << ((unsigned)val&0xff) << '\n' << dec;
}

void CmdWritter::Eval() {	
	// cout << "Writter eval " << state << "\n";
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
