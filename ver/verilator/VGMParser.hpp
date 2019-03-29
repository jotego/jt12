#ifndef __VGMPARSER
#define __VGMPARSER

#include <fstream>
#include <map>
#include <string>

// Do not output to cout because it will interfere with
// signal dumping!

class RipParser {
public:
	enum chip_type { ym2203=1, ym2612=2, ym2610=3, unknown=0 };
protected:
	int clk_period; // synthesizer clock period
	chip_type chip_cfg;
public:
	char cmd, val, addr;
	uint64_t wait;
	virtual void open(const char *filename, int limit=0)=0;	
	virtual int parse()=0;
	virtual uint64_t length()=0;
	virtual ~RipParser() {};
	virtual uint8_t ADPCM(int offset) {
		std::cerr << "ERROR: No ADPCM buffer available\n";
		throw 1;
	}
    virtual void saveADPCMA(const char* filename) {};
	RipParser(int c) { clk_period = c; }
	enum { cmd_error=-2, cmd_finish=-1, cmd_write=0, cmd_wait=1, cmd_psg=2 };
	chip_type chip() { return chip_cfg; }
	virtual int period();
};

RipParser* ParserFactory( const char *filename, int clk_period );

// class ADPCMdec {
//     int jedi_table[ 49*16 ];
// public:
//     ADPCMdec();
//     void decode( char *buf, int *dest, int length );
// };

class VGMParser : public RipParser {
	std::ifstream file;	
	std::ofstream ftrans; // translation to JTT format
	float cur_time; // used by ftrans
	int totalwait, pending_wait, stream_id;
	bool done, stream_notmplemented_info;
	void adjust_wait() { 
		double w=wait;
		w /= 44100.0;
		w *= 1e9;
		wait = (uint64_t)w; 
	}
	void translate_cmd();
	void translate_wait();
    void decode_save( char *buf, int length, int rom_start );
	char *stream_data;
	uint32_t data_offset, ym_freq;	
    char *ADPCM_data;
    // int max_PSG_warning;
    // ADPCMdec dec;
public:
	void open(const char *filename, int limit=0);
	int parse();
	uint64_t length();
	int period();
    void saveADPCMA(const char* filename);
	uint8_t ADPCM(int offset) {
		if( offset > 12*1024*1024 ) {
			std::cerr << "ERROR: ADPCM offset too long\n";
			throw 1;
		}
		if( ADPCM_data==NULL ) {
			return 0;
		}
		// int d = ADPCM_data[offset]&0xff;
		// if(offset!=0)std::cerr << "INFO: read ADPCM " << d << " at " << offset << '\n';
		return ADPCM_data[offset];
	}
	VGMParser(int c) : RipParser(c) {
		stream_data=NULL; stream_id=0; ADPCM_data=0;
	}
	~VGMParser();
};

class Gym : public RipParser {
	std::ifstream file;	
	int max_PSG_warning;
	int count, count_limit;
	void adjust_wait() { wait*=100000; wait/=441; }
public:
	void open(const char *filename, int limit=0);
	int parse();
	uint64_t length() { return 0; /* unknown */ }
	Gym(int c) : RipParser(c) {}
};

class JTTParser : public RipParser {
	std::ifstream file;	
	int line_cnt;
	bool done;
	int default_ch;
	// int max_PSG_warning;
	void remove_blanks( char*& str );
	void parse_chdata(char *txt_arg, int cmd_base);
	void parse_opdata(char *txt_arg, int cmd_base);
	void parse_adpcma_data(char *txt_arg, int cmd_base);

	std::map<std::string, char> op_commands;
	std::map<std::string, char> ch_commands;
	std::map<std::string, char> adpcma_commands;
	std::map<std::string, char> global_commands;
    unsigned char *adpcm_sine;
    char *ADPCM_data;
public:
    JTTParser(int c);
	~JTTParser();
	void open(const char *filename, int limit=0);
	int parse();
	uint64_t length() { return 0; }
	uint8_t ADPCM(int offset);
	int period();
};

int YM2610_ADPCMB_Encode( short *src , unsigned char *dest , int len );
int YM2610_ADPCMB_Decode( unsigned char *src , short *dest , int len );

#endif