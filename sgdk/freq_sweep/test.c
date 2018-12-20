#include <genesis.h>
#include <ym2612.h>

void write_freq( int freq ) {
    char aux = freq>>8;
    YM2612_writeReg( 0, 0xa4, aux );
    aux = freq&0xff;
    YM2612_writeReg( 0, 0xa4, aux );
}

int main() {
    char ymregs[] = {
        0xb0, 0x07, // FB - connect
        0xb4, 0xc0, // LR
        0x30, 0x01, // DT - MULT
        0x40, 0x00, // TL
        0x50, 0x1f, // AR
        0x60, 0x00, // DR
        0x70, 0x00, // SR

        0x80, 0x00, // SL+RR
        0x90, 0x00, // SSG
        0xa4, 0x00, // Block
        0xa0, 0x00  // Fnum
    };
    int k;
    int ssg=7;
    int inc=1;
    Z80_requestBus(1000);
    // YM2612_reset();
    for ( k=0; k<sizeof(ymregs); k+=2 ) {
        YM2612_writeReg( 0, ymregs[k], ymregs[k+1]);
    }
    VDP_drawText("Freq sweep", 10, 13);
    YM2612_writeReg( 0, 0x28, 0x10 ); // key-on channel 0 op 0
    while(1) {
        unsigned k1;
        int freq=0;
        for(k1=160;k1>0;k1--) {
            unsigned k2=0xffff;
            while(k2--);
        }
        if(freq==0) inc=1;
        freq+=inc;
        if(freq>0xc000) inc=-1;
        YM2612_writeReg( freq );
    }
    return 0;
}
