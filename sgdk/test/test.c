#include <genesis.h>
#include <ym2612.h>

int main() {
    char ymregs[] = {
        0x30, 1,
        0x40, 0,
        0x50, 0x1f,
        0x60, 0,
        0x70, 0,
        0x80, 0,
        0x90, 0,

        0x34, 1,
        0x44, 0,
        0x54, 0x1f,
        0x64, 0,
        0x74, 0,
        0x84, 0,
        0x94, 0,

        0x38, 1,
        0x48, 0,
        0x58, 0x1f,
        0x68, 0,
        0x78, 0,
        0x88, 0,
        0x98, 0,

        0xa4, 4<<3,
        0xa0, 0xff,
        0xb0, 7,
        0xb4, 0xc0,

        0x28, 0xf0
    };
    int k;
    Z80_requestBus(1000);
    // YM2612_reset();
    for ( k=0; k<sizeof(ymregs); k+=2 ) {
        YM2612_writeReg( 0, ymregs[k], ymregs[k+1]);
    }
    VDP_drawText("Vaya", 10, 13);
    while(1);
    return 0;
}
