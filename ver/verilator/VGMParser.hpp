#ifndef __VGMPARSER
#define __VGMPARSER

#include <fstream>

class VGMParser {
	ifstream file;	
	// int max_PSG_warning;
public:
	char cmd, val, addr;
	void open(const char *filename, int limit);
	int parse();
};

#endif