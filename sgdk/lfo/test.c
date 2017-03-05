#include <genesis.h>
#include <ym2612.h>

void timer_wait(int m) {
    int wait;
    YM2612_writeReg( 0, 0x26, 0x0 );
    for( wait=0; wait<m; wait++ ) {
        YM2612_writeReg( 0, 0x27, 0x2A );
        while( (YM2612_read(0)&3) == 0 );
    }
}

void play() {
    int k;
    int freq=0;
    int ams=0, pms=0;
    int bank,ch,op;
    int path0[] = { 0, 0, 31, 0x80, 0, 15, 0 };
    char msg[10] = "AMS = ";
    char msg2[10] = "FREQ= ";
    msg[7] = 0;
    msg2[7] = 0;

    YM2612_writeReg( 0, 0x26, 0x0 );

    for(bank=0;bank<2;bank++)
    for(ch=0;ch<3;ch++)
    for(op=0;op<4;op++) {
        YM2612_writeReg( bank, 0x40+ch+(op<<2), 0xff); // TL
    }
    // CH0, OP0
    for( k=0; k<7; k++ )
        YM2612_writeReg( 0, 0x30+0x10*k, path0[k] );
//    YM2612_writeReg( 0, 0xa4, (3<<3) | 0x3);
//    YM2612_writeReg( 0, 0xa0, 0xff);
    YM2612_writeReg( 0, 0xa4, 15);
    YM2612_writeReg( 0, 0xa0, 0);

    YM2612_writeReg( 0, 0xb0, 7 );

    for(ams=0; ams<4; ams++)
    for(freq=0; freq<8; freq++) {
        msg[6] = 48+ams;
        msg2[6] = 48+freq;
        VDP_drawText( msg, 10, 13);
        VDP_drawText( msg2, 10, 14);

        YM2612_writeReg( 0, 0xb4, 0xc0 | (ams<<4) );
        YM2612_writeReg( 0, 0x22, 0x8 | freq );
        YM2612_writeReg( 0, 0x28, 0x10 );
        timer_wait(15);
        YM2612_writeReg( 0, 0x28, 0x0 );
        timer_wait(1);
    }
}

int main() {
    Z80_requestBus(1000);
    YM2612_reset();
    while(1) play();
    return 0;
}
