#ifndef __VGMPARSER
#define __VGMPARSER

#include <fstream>

class RipParser {
public:
	char cmd, val, addr;
	int wait;
	virtual void open(const char *filename, int limit=0)=0;
	virtual int parse()=0;
};

class VGMParser : public RipParser {
	std::ifstream file;	
	// int max_PSG_warning;
public:
	void open(const char *filename, int limit=0);
	int parse();
};

class Gym : public RipParser {
	std::ifstream file;	
	int max_PSG_warning;
	int count, count_limit;
public:
	void open(const char *filename, int limit=0);
	int parse();
};

#endif