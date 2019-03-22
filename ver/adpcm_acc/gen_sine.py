#!/usr/bin/python

import math

def tohex(val, nbits):
  return hex((val + (1 << nbits)) % (1 << nbits))

for k in range(128):
    lin = math.sin( 2.0*k/128.0 * math.pi  )*32767
    print(tohex( int(lin), 16)[2:])
