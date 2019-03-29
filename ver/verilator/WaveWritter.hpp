#ifndef __WAVEWRITTER_H
#define __WAVEWRITTER_H

#include <fstream>

class WaveWritter {
    std::ofstream fsnd, fhex;
    bool dump_hex;
public:
    WaveWritter(const char *filename, int sample_rate, bool hex );
    void write( int16_t *lr );
    ~WaveWritter();
};

#endif