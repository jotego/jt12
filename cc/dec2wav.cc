#include <fstream>
#include <sstream>
#include <iostream>
#include "WaveWritter.hpp"

using namespace std;

int main(int argc, char *argv[] ) {
    int sample_rate = 55500;
    ifstream fin;
    string filename;
    for( int k=1; k<argc; k++ ) {
        // Is the argument a file name?
        if( !fin.is_open() ) {
            fin.open(argv[k]);
            if( fin.is_open() ) {
                filename = argv[k];
                continue; // it was a file name
            }
        }
        stringstream parse( argv[k] );
        parse >> sample_rate;
        if( parse.fail() ) {
            cout << "Unexpected parameter " << argv[k] << '\n';
            cout << "Usage: dec2wav filename sample_rate\n";
            cout << "\tThis program converts a text file with one value\n";
            cout << "\tper line into a .wav file.\n";
            return 1;
        }        
    }

    string output_name;
    int dot = filename.find_last_of('.');
    if( dot == string::npos ) dot = filename.length();
    output_name = filename.substr(0, dot ) + ".wav";

    cout << "INFO: sample rate = " << sample_rate << " Hz\n";
    WaveWritter wav( output_name.c_str(), sample_rate, false );
    while( !fin.eof() ) {
        int val;
        fin >> val;
        int16_t lr[3];
        lr[0] = lr[1] = val*2;
        lr[2] = 0;
        wav.write( lr );
    }
    return 0;
}