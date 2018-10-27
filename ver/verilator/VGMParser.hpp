#ifndef __VGMPARSER
#define __VGMPARSER

#include <fstream>

class RipParser {
public:
	char cmd, val, addr;
	int wait;
	virtual void open(const char *filename, int limit=0)=0;
	virtual int parse()=0;
	virtual uint64_t length()=0;
	enum { cmd_error=-2 };
};

class VGMParser : public RipParser {
	std::ifstream file;	
	int totalwait;
	bool done;
	// int max_PSG_warning;
public:
	void open(const char *filename, int limit=0);
	int parse();
	uint64_t length();
};

class Gym : public RipParser {
	std::ifstream file;	
	int max_PSG_warning;
	int count, count_limit;
public:
	void open(const char *filename, int limit=0);
	int parse();
	uint64_t length() { return 0; /* unknown */ }
};

class JTTParser : public RipParser {
	std::ifstream file;	
	int totalwait;
	bool done;
	// int max_PSG_warning;
	void remove_blanks( (char*&) str );
public:
	void open(const char *filename, int limit=0);
	int parse();
	uint64_t length() { return 0; }
};

#endif