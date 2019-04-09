#!/bin/python

print "ym2610"
print "# Generated with adpcma_fadein.py"
print "atl 3f"
print "aend_msb ff"
print "aon 1"

for i in range(0,64):
    print "alr 0,",hex(i|0xc0)[2:]
    print "wait 200"

for i in range(63,0,-1):
    print "alr 0,",hex(i|0x80)[2:]
    print "wait 200"

for i in range(0,64):
    print "alr 0,",hex(i|0x40)[2:]
    print "wait 200"