# Munin-Plugin for Vigor 130 or Vigor 165

This repository contains a Munin-Plugin to read VDSL stats from a Draytek Vigor 130 or
a Vigor 165 VDSL-modem.

There are two versions of the plugin-script:
* The default version uses the webinterface to get information from the modem. It needs the
LWP::UserAgent perl module installed to work.
* The version with the "-telnet" in the name uses telnet to get information from the modem.
It needs the Net::Telnet perl module installed to work.

You need to chose one version and one version only, it does not make sense to use both.

The webinterface-version is older and works reasonably well, but it is known that the webinterface
of at least the Vigor 130 leaks memory, so you'll have to reboot it from time to time because the
webinterface will stop responding.

The telnet-version is faster in querying the modem, but it is unknown if it will also cause
a memory leak, or how fast.

Usage information is included at the top of the scripts. The script grabs the DSL status page
from the modems webinterface or in the telnet-console and parses that. This was tested
on a Vigor 130 with firmware version 3.7.9.1_m7, and others reported success with a Vigor 165.
Other versions may produce different output though, so parsing the data may not work there. YMMV.

License is GPL.

### Example images

Here are some images showing what graphs it produces.

#### Telekom VDSL

This is a 50 MBit line by Deutsche Telekom, and the graphs show
the effects of them replacing some equipment. Thanks to Bianco Veigel
for the pictures.

![example datarate graph 1](img/bv-vig130_datarates-week.png)
![example error graph upstream 1](img/bv-vig130_errors1_dn-week.png)
![example error graph downstream 1](img/bv-vig130_errors1_up-week.png)
![example SNR margin graph 1](img/bv-vig130_snrmargins-week.png)

#### My own line at home

My line is way too good because it's just some 10 meters into the basement
(FTTB), so these look extremely dull...

![example datarate graph 2](img/fox-vig130_datarates-day.png)
![example error graph downstream 2](img/fox-vig130_errors1_dn-day.png)
![example SNR margin graph 2](img/fox-vig130_snrmargins-week.png)

