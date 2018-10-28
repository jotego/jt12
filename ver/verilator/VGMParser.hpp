#ifndef __VGMPARSER
#define __VGMPARSER

#include <fstream>
#include <map>
#include <string>

class RipParser {
protected:
	int clk_period; // synthesizer clock period
public:
	char cmd, val, addr;
	uint64_t wait;
	virtual void open(const char *filename, int limit=0)=0;
	virtual int parse()=0;
	virtual uint64_t length()=0;
	RipParser(int c) { clk_period = c; }
	enum { cmd_error=-2, cmd_finish=-1, cmd_write=0, cmd_wait=1 };
};

class VGMParser : public RipParser {
	std::ifstream file;	
	int totalwait;
	bool done;
	void adjust_wait() { wait*=100000; wait/=441; }
	// int max_PSG_warning;
public:
	void open(const char *filename, int limit=0);
	int parse();
	uint64_t length();
	VGMParser(int c) : RipParser(c) {}
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

	std::map<std::string, char> op_commands;
	std::map<std::string, char> ch_commands;
	std::map<std::string, char> global_commands;
public:
	JTTParser(int c);
	void open(const char *filename, int limit=0);
	int parse();
	uint64_t length() { return 0; }
};

#endif