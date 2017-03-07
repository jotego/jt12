close all;
clear all;
clf;
pkg load signal;

f1 = 17000;
f2 = 22000;
delta_f = f2-f1;
Fs = 54e6/7/6;
dB  = 20;
N = dB*Fs/(22*delta_f);
Nodd = round(N);
if mod(Nodd,2) == 0
  Nodd = Nodd+1;
 endif
 printf("New sampling frequency %f Hz\n", Fs);
 printf("%d stages\n", Nodd);

f =  [f1 ]/(Fs/2);
# hc = fir1(Nodd-1, f,'low');
hc = fir1(200, f,'low');


figure
plot((-0.5:1/4096:0.5-1/4096)*Fs,20*log10(abs(fftshift(fft(hc,4096)))))
axis([0 20000 -60 20])
title('Filter Frequency Response')
grid on

# Implementation
h_scl = max(hc);
h_q2 = floor((hc/h_scl)*2^8)/2^8;
q2 = h_scl *h_q2 - hc;

h_q2 = h_q2/sum(h_q2);

figure
plot((-0.5:1/4096:0.5-1/4096)*Fs,20*log10(abs(fftshift(fft(hc,4096)))))
hold on
plot((-0.5:1/4096:0.5-1/4096)*Fs,20*log10(abs(fftshift(fft(h_q2,4096)))),'color','r')
grid on
axis([-Fs/2 Fs/2 -140 5])
title('Frequency Spectrum W/ Scaling - Blue(Octave), Red(8-Bit Quantized)')

# Scale to 9 bits (8 bit + sign)
h3 = round( h_q2/max(abs(h_q2))*255);
for j=1:101
  printf("\tcoeff[%d] <= 9'd%d;\n",j-1,h3(j));
endfor