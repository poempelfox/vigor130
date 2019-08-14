#!/usr/bin/perl -w

# You should put a symlink to this plugin into the munin plugindir.
#
# If you want to show the modem status under the hostname of your router,
# the name of the symlink should be formed like this:
#  SOMETHING_HOSTNAME-OR-IP, e.g. vdslstats_10.10.1.1
# HOSTNAME-OR-IP should be the IP of the modem.
# Note: In this case you can only feed info from one modem per host into munin.
#
# If you want to show the modem status as an individual host in munin instead,
# use the following naming scheme for the symlink instead:
#  HOSTNAME-OR-IP_SOMETHING,  e.g. 10.10.1.1_vdslstats
# In this case you will also have to configure your munin-server accordingly to
# query the new "host" (called virtual node in munin lingo).
#
# You can use environment variables to configure this script - you'll
# definitely need to do that if you changed the default username/password
# on the modem. This has to go into the munin plugin configuration on the host
# where this script will be executed.
#
# The following variables are supported:
#   hostname      Hostname or IP of the modem  (default: 192.168.1.1)
#   username      Username for login to the modem (default: admin)
#   password      Password for login to the modem (default: admin)

# Some tuneables:
# Timeout for requests.
my $timeout = 15; # the LWP default of 180 secs would be way too long

# ----------------------------------------------------------------------------

use Net::Telnet ();

# Par. 0: Hostname/IP
# Par. 1: Username
# Par. 2: Password
# Returns: The contents of the website
sub getdslstatuspage($$$) {
  my $rv1; my $rv2;
  my $hostname = shift();
  my $username = shift();
  my $password = shift();
  
  
  my $remote = new Net::Telnet (Timeout => $timeout,Errmode => 'die');
  $remote->open($hostname);
  $remote->waitfor('/Account:/');
  $remote->print($username);
  $remote->waitfor('/Password: /');
  $remote->print($password);
  $remote->waitfor('/(DrayTek|Vigor)> /');
  $remote->print("vdsl status");
  ($rv1) = $remote->waitfor('/(DrayTek|Vigor)> /');
  $remote->print("vdsl status more");
  ($rv2) = $remote->waitfor('/(DrayTek|Vigor)> /');
  
  return ($rv1.$rv2);
}

if ((@ARGV > 0) && ($ARGV[0] eq "autoconf")) {
  print("No\n");
  exit(0);
}
my $progname = $0;
my $hostname = '192.168.1.1';  # These are the factory defaults of the Vigor 130
my $username = 'admin';
my $password = 'admin';
my $fakehost = '';
if ($progname =~ m/([a-zA-Z0-9]+\.[a-zA-Z0-9.]+)_.+/) {
  $fakehost = $1;
  $hostname = $1;
} elsif ($progname =~ m/.+_(.+)/) {
  $hostname = $1;
}
if (defined($ENV{'hostname'})) { $hostname = $ENV{'hostname'} }
if (defined($ENV{'username'})) { $username = $ENV{'username'} }
if (defined($ENV{'password'})) { $password = $ENV{'password'} }
if ((@ARGV > 0) && ($ARGV[0] eq "config")) {
  if (length($fakehost) > 0) { print("host_name $fakehost\n"); }
  
  print("multigraph vig130_datarates\n");
  print("graph_category VDSL\n");
  print("graph_title VDSL Data Rate\n");
  print("graph_args --base 1000 --lower-limit 0\n");
  print("graph_vlabel bps\n");
  print("attdnrate.label attainable downstream rate\n");
  print("attdnrate.type GAUGE\n");
  print("attdnrate.draw LINE0.6\n");
  print("attdnrate.info This is the maximum downstream rate the modem thinks it could attain. This is mostly guesswork and not a reliable value.\n");
  print("attuprate.label attainable upstream rate\n");
  print("attuprate.type GAUGE\n");
  print("attuprate.draw LINE0.6\n");
  print("attuprate.info This is the maximum upstream rate the modem thinks it could attain. This is mostly guesswork and not a reliable value.\n");
  print("curdnrate.label current downstream rate\n");
  print("curdnrate.type GAUGE\n");
  print("curdnrate.draw LINE2.0\n");
  print("curdnrate.info This is the current downstream rate at which the modem communicates with the DSLAM.\n");
  print("curuprate.label current upstream rate\n");
  print("curuprate.type GAUGE\n");
  print("curuprate.draw LINE2.0\n");
  print("curuprate.info This is the current upstream rate at which the modem communicates with the DSLAM.\n");
  
  print("multigraph vig130_snrmargins\n");
  print("graph_category VDSL\n");
  print("graph_title SNR margins\n");
  print("graph_vlabel dB\n");
  print("snrmargindn.label downstream snr margin\n");
  print("snrmargindn.type GAUGE\n");
  print("snrmargindn.draw LINE2.0\n");
  print("snrmargindn.info The current SNR margin for the downstream. SNR margin is the difference between the current SNR value and the minimum SNR value required to sync, so a higher value means a more stable connection.\n");
  print("snrmarginup.label upstream snr margin\n");
  print("snrmarginup.type GAUGE\n");
  print("snrmarginup.draw LINE2.0\n");
  print("snrmarginup.info The current SNR margin for the upstream.\n");
  
  print("multigraph vig130_attenuation\n");
  print("graph_category VDSL\n");
  print("graph_title attenuation\n");
  print("graph_vlabel dB\n");
  print("attenuationdn.label attenuation downstream\n");
  print("attenuationdn.type GAUGE\n");
  print("attenuationdn.draw LINE2.0\n");
  print("attenuationdn.info The attenuation on the downstream. Attenuation is how much signal strength is lost on the line, lower is better.\n");
  print("attenuationup.label attenuation upstream\n");
  print("attenuationup.type GAUGE\n");
  print("attenuationup.draw LINE2.0\n");
  print("attenuationup.info The attenuation on the upstream.\n");
  
  # potential FIXME: These are not in the same units, so a graph combining them
  # all will probably scale wrong. Also, their proportions will depend on the
  # actual line. It might not be possible to combine those all into one graph.
  print("multigraph vig130_errors1_dn\n");
  print("graph_category VDSL\n");
  print("graph_title VDSL Errors Downstream\n");
  print("graph_vlabel n\n");
  print("crcerrsdn.label CRC errors\n");
  print("crcerrsdn.type DERIVE\n");
  print("crcerrsdn.min 0\n");
  print("crcerrsdn.draw LINE2.0\n");
  print("crcerrsdn.info The number of CRC (Cyclic Redundancy Check) errors on the" .
        " downstream. Those are corrupted and thus lost packets that required" .
        " resubmission, so these are bad.\n");
  print("fecsdn.label FECS\n");
  print("fecsdn.type DERIVE\n");
  print("fecsdn.min 0\n");
  print("fecsdn.draw LINE2.0\n");
  print("fecsdn.info The number of FECS (Forward Error Correction Seconds) on" .
        " the downstream, i.e. in how many seconds there were errors corrected" .
        " by FEC. Those are errors that could be fully corrected from" .
        " redundancy information by the modem, nothing was lost. These do not" .
        " have a negative impact on performance, so they are pretty much" .
        " irrelevant.\n");
  print("esdn.label ES\n");
  print("esdn.type DERIVE\n");
  print("esdn.min 0\n");
  print("esdn.draw LINE2.0\n");
  print("esdn.info The number of ES (Errored Seconds) on the downstream," .
        " i.e. in how many seconds there were errors encountered\n");
  print("sesdn.label SES\n");
  print("sesdn.type DERIVE\n");
  print("sesdn.min 0\n");
  print("sesdn.draw LINE2.0\n");
  print("sesdn.info The number of SES (Severely Errored Seconds) on the downstream\n");
  print("lossdn.label LOSS\n");
  print("lossdn.type DERIVE\n");
  print("lossdn.min 0\n");
  print("lossdn.draw LINE2.0\n");
  print("lossdn.info The number of LOSS (Loss Of Signal Seconds) on the downstream\n");
  print("uasdn.label UAS\n");
  print("uasdn.type DERIVE\n");
  print("uasdn.min 0\n");
  print("uasdn.draw LINE2.0\n");
  print("uasdn.info The number of UAS (UnAvailable Seconds) on the downstream\n");
  
  print("multigraph vig130_errors1_up\n");
  print("graph_category VDSL\n");
  print("graph_title VDSL Errors Upstream\n");
  print("graph_vlabel n\n");
  print("crcerrsup.label CRC errors\n");
  print("crcerrsup.type DERIVE\n");
  print("crcerrsup.min 0\n");
  print("crcerrsup.draw LINE2.0\n");
  print("crcerrsup.info The number of CRC (Cyclic Redundancy Check) errors on the upstream.\n");
  print("fecsup.label FECS\n");
  print("fecsup.type DERIVE\n");
  print("fecsup.min 0\n");
  print("fecsup.draw LINE2.0\n");
  print("fecsup.info The number of FECS (Forward Error Correction Seconds) on" .
        " the upstream.\n");
  print("esup.label ES\n");
  print("esup.type DERIVE\n");
  print("esup.min 0\n");
  print("esup.draw LINE2.0\n");
  print("esup.info The number of ES (Errored Seconds) on the upstream\n");
  print("sesup.label SES\n");
  print("sesup.type DERIVE\n");
  print("sesup.min 0\n");
  print("sesup.draw LINE2.0\n");
  print("sesup.info The number of SES (Severely Errored Seconds) on the upstream\n");
  print("lossup.label LOSS\n");
  print("lossup.type DERIVE\n");
  print("lossup.min 0\n");
  print("lossup.draw LINE2.0\n");
  print("lossup.info The number of LOSS (Loss Of Signal Seconds) on the upstream\n");
  print("uasup.label UAS\n");
  print("uasup.type DERIVE\n");
  print("uasup.min 0\n");
  print("uasup.draw LINE2.0\n");
  print("uasup.info The number of UAS (UnAvailable Seconds) on the upstream\n");

  # PSD should be constant unless the profile on the DSLAM is changed.
  # It also isn't clear how this value is calculated, as it has to be an average
  # over a lot of values? Lets not draw it for now.
  #print("snrmargindn.info PSD is the power spectrum density\n");
  
  # NFEC: Actual Size of Reed-Solomon Codeword
  # RFEC: Actual number of Reed-Solomon redundancy bytes.
  
  exit(0);
}

$dslsp = getdslstatuspage($hostname, $username, $password);
unless (defined($dslsp)) {
  exit(1);
}
#print($dslsp);
# Remove non-tables, colors, table attributes and all that useless stuff
$dslsp =~ s/(<[a-zA-Z]*) (.*?)>/$1>/sg;
$dslsp =~ s|.*?<table>(.*)</table>.*|$1|sgi;
$dslsp =~ s|</{0,1}font>||g;
if (defined($ENV{'VERBOSE'}) && ($ENV{'VERBOSE'} eq '1')) {
  print("$dslsp\n");
}
my $curdnrate = 'U';
my $curuprate = 'U';
my $attdnrate = 'U';
my $attuprate = 'U';
my $snrmargindn = 'U';
my $snrmarginup = 'U';
my $attenuationdn = 'U';
my $attenuationup = 'U';
my $crcerrsdn = 'U';
my $crcerrsup = 'U';
my $fecsdn = 'U';
my $fecsup = 'U';
my $esdn = 'U';
my $esup = 'U';
my $sesdn = 'U';
my $sesup = 'U';
my $lossdn = 'U';
my $lossup = 'U';
my $uasdn = 'U';
my $uasup = 'U';
if ($dslsp =~ m!\s*DS Attainable Rate\s*:\s*(\d+) bps\s*US Attainable Rate\s*:\s*(\d+) bps!) {
  $attdnrate = int($1);
  $attuprate = int($2);
}
if ($dslsp =~ m!\s*DS Actual Rate\s*:\s*(\d+) bps\s*US Actual Rate\s*:\s*(\d+) bps!) {
  $curdnrate = int($1);
  $curuprate = int($2);
}
if ($dslsp =~ m!\s*NE Current Attenuation\s*:\s*(\d+) dB\s*Cur SNR Margin\s*:\s*(\d+)\s+dB!) {
  $attenuationdn = $1;
  $snrmargindn = $2;
}
if ($dslsp =~ m!\s*Far Current Attenuation\s*:\s*(\d+) dB\s*Far SNR Margin\s*:\s*(\d+)\s+dB!) {
  $attenuationup = $1;
  $snrmarginup = $2;
}
if ($dslsp =~ m! CRC\s*:\s*(\d+)\s+(\d+)!) {
  $crcerrsdn = int($1);
  $crcerrsup = int($2);
}
if ($dslsp =~ m! FECS\s*:\s*(\d+)\s+(\d+)!) {
  $fecsdn = int($1);
  $fecsup = int($2);
}
if ($dslsp =~ m! ES\s*:\s*(\d+)\s+(\d+)!) {
  $esdn = int($1);
  $esup = int($2);
}
if ($dslsp =~ m! SES\s*:\s*(\d+)\s+(\d+)!) {
  $sesdn = int($1);
  $sesup = int($2);
}
if ($dslsp =~ m! LOSS\s*:\s*(\d+)\s+(\d+)!) {
  $lossdn = int($1);
  $lossup = int($2);
}
if ($dslsp =~ m! UAS\s*:\s*(\d+)\s+(\d+)!) {
  $uasdn = int($1);
  $uasup = int($2);
}
if (length($fakehost) > 0) { print("host_name $fakehost\n"); }
print("multigraph vig130_datarates\n");
print("attdnrate.value $attdnrate\n");
print("attuprate.value $attuprate\n");
print("curdnrate.value $curdnrate\n");
print("curuprate.value $curuprate\n");
print("multigraph vig130_snrmargins\n");
print("snrmargindn.value $snrmargindn\n");
print("snrmarginup.value $snrmarginup\n");
print("multigraph vig130_attenuation\n");
print("attenuationdn.value $attenuationdn\n");
print("attenuationup.value $attenuationup\n");
print("multigraph vig130_errors1_dn\n");
print("crcerrsdn.value $crcerrsdn\n");
print("fecsdn.value $fecsdn\n");
print("esdn.value $esdn\n");
print("sesdn.value $sesdn\n");
print("lossdn.value $lossdn\n");
print("uasdn.value $uasdn\n");
print("multigraph vig130_errors1_up\n");
print("crcerrsup.value $crcerrsup\n");
print("fecsup.value $fecsup\n");
print("esup.value $esup\n");
print("sesup.value $sesup\n");
print("lossup.value $lossup\n");
print("uasup.value $uasup\n");
