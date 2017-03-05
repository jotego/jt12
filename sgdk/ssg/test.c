#include <genesis.h>
#include <ym2612.h>

int main() {
    char ymregs[] = {
        0xb2, 0x07,
        0xb6, 0xc0,
        0x3e, 0x01,
        0x4e, 0x02,
        0x5e, 0x1f, // AR
        0x6e, 0x08, // DR
        0x7e, 0x08, // SR

        0x8e, 0xf4, // SL+RR
        0x9e, 0x00, // SSG
        0xa6, 0x34,
        0xa2, 0x43,
        0x9e, 0x7 // SSG
    };
    int k;
    int ssg=7;
    Z80_requestBus(1000);
    // YM2612_reset();
    for ( k=0; k<sizeof(ymregs); k+=2 ) {
        YM2612_writeReg( 0, ymregs[k], ymregs[k+1]);
    }
    VDP_drawText("SSG", 10, 13);
    while(1) {
        unsigned k1=160;
        char a[2]= {0,0};
        a[0] = (ssg&7)+48;
        VDP_drawText( a, 15,13 );
        YM2612_writeReg( 0, 0x28, 0x82 );
        while(k1--) {
            unsigned k2=0xffff;
            while(k2--);
        }
        YM2612_writeReg( 0, 0x28, 0x02 );
        ssg++;
        YM2612_writeReg( 0, 0x9e, 0x08 | (ssg&7) );
    }
    return 0;
}
