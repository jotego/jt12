#include <iostream>
#include <cmath>

using namespace std;

static long stepsizeTable[ 16 ] = {
    57, 57, 57, 57, 77,102,128,153,
    57, 57, 57, 57, 77,102,128,153
};

int YM2610_ADPCMB_Decode( unsigned char *src , short *dest , int len ) {
    int lpc , flag , shift , step;
    long i , xn , stepSize;
    long adpcm;
    xn = 0;
    stepSize = 127;
    flag = 0;
    shift = 4;
    step = 0;
    for( lpc = 0 ; lpc < len ; lpc++ ) {
        adpcm = ( *src >> shift ) & 0xf;
        i = ( ( adpcm & 7 ) * 2 + 1 ) * stepSize / 8;
        if( adpcm & 8 )
            xn -= i;
        else
            xn += i;
        if( xn > 32767 )
            xn = 32767;
        else if( xn < -32768 )
            xn = -32768;
        stepSize = stepSize * stepsizeTable[ adpcm ] / 64;
        if( stepSize < 127 )
            stepSize = 127;
        else if ( stepSize > 24576 )
            stepSize = 24576;
        *dest = ( short )xn;
        dest++;
        src += step;
        step = step ^ 1;
        shift = shift ^ 4;
        // debug
        cout << adpcm << " -> " << xn << '\t' << stepSize << '\n';
    }
    return 0;
}

int YM2610_ADPCMB_Encode( short *src , unsigned char *dest , int len ) {
    int lpc , flag;
    long i , dn , xn , stepSize;
    unsigned char adpcm;
    unsigned char adpcmPack;
    xn = 0;
    stepSize = 127;
    flag = 0;
    for( lpc = 0 ; lpc < len ; lpc++ ) {
        dn = *src - xn;
        src++;
        i = ( abs( dn ) << 16 ) / ( stepSize << 14 );
        if( i > 7 ) i = 7;
        adpcm = ( unsigned char )i;
        i = ( adpcm * 2 + 1 ) * stepSize / 8;
        if( dn < 0 ) {
            adpcm |= 0x8;
            xn -= i;
        }
        else {
            xn += i;
        }
        stepSize = ( stepsizeTable[ adpcm ] * stepSize ) / 64;
        if( stepSize < 127 )
            stepSize = 127;
        else if( stepSize > 24576 )
            stepSize = 24576;
        if( flag == 0 ) {
            adpcmPack = ( adpcm << 4 ) ;
            flag = 1;
        }
        else {
            adpcmPack |= adpcm;
            *dest = adpcmPack;
            dest++;
            flag = 0;
        }
    }
    return 0;
}

int main() {
    const int sine_len = 2048;
    short *sine = new short[sine_len];
    for(int k=0;k<sine_len;k++) {
        sine[k]=32767.0*sin( 6.283185*k*4.0/sine_len );
    }
    unsigned char *pack   = new unsigned char[sine_len/2];
    short *unpack = new short[sine_len];
    YM2610_ADPCMB_Encode( sine, pack, sine_len );
    YM2610_ADPCMB_Decode( pack, unpack, sine_len);
    cout << "------------------------\n";
    for(int k=0;k<sine_len;k++) {
        cout << k << '\t' << sine[k] << '\t' << unpack[k] << '\n';
    }
    return 0;
}