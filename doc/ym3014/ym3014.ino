// B.0 = data   (pin  8)
// B.1 = clock  (pin  9)
// B.5 = load   (pin 13)

void convert(int data) {
	for(int i=0; i<16; i++) {    
		int d = data&1;
		if (i>8) d|=0x20;
		PORTB=d;    // B.0, PIN 8
		PORTB=2|d;       
		data >>= 1;
	}  
	toggle_clock();
	toggle_clock();
	toggle_clock();
}

void toggle_clock() {
	PORTB=0;
	PORTB=2;
	PORTB=0;
}

long readDAC() {
	long dac = analogRead(0);
	dac = dac*5000/1024;
	return dac;	
}

void loop() {
}

void setup() {
	char sz[40];
	DDRB=0xff;
	PORTB=0;  
	Serial.begin(9600);
	int exp=7;
	for(int man=0;man<8;man++) { // 3 bits
		int val = ((exp<<3)|man)<<10;
		convert(val);
		delay(5);
		sprintf(sz,"%d,%ld\n",man,readDAC());
		Serial.print(sz);
	}
	Serial.end();
}
