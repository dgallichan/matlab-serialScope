# matlab-serialScope
Turn MATLAB into a 'scope' for live plotting (and recording) of USB/serial streamed data

I've found that although I've attempted to add the timestamps as the data
arrives here in MATLAB, this adds another artificial 'jitter' to the
timing - it is more accurate to add a milliseconds timestamp to the data
before streaming it from your microcontroller.

A simple example for what to put on a Micro:bit microcontroller can be
found here: https://github.com/dgallichan/microbit-serialSendData

It appears to work OK for data streams up to ~100 Hz or so. 
If you turn off the live plotting you should be able to go a fair amount faster. 
If you really want to go as fast as possible, the same code could be modified to read numbers from binary rather than ASCII text.

 **IMPORTANT** - don't forget to close the serial connections in other
 software running on your computer (e.g. Makecode browser, Arduino IDE,
 etc)
