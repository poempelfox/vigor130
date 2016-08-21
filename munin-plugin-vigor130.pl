#!/usr/bin/perl -w

# Some tuneables:
# Timeout for requests.
my $timeout = 15; # the LWP default of 180 secs would be way too long


use LWP::UserAgent;
use HTTP::Cookies;
use MIME::Base64 qw/encode_base64/;
use HTML::TableExtract;

# Par. 0: Hostname/IP
# Par. 1: Username
# Par. 2: Password
# Returns: The contents of the website
sub getdslstatuspage($$$) {
  my $hn = shift();
  my $un = shift();
  my $pw = shift();

  my $ua = LWP::UserAgent->new();
  $ua->agent($0);
  $ua->timeout($timeout);
  # Create a request
  my %frm = ( 'aa' => encode_base64($un, ''), 'ab' => encode_base64($pw, '') );
  # Pass request to the user agent and get a response back
  my $res = $ua->post("http://${hn}/cgi-bin/wlogin.cgi", \%frm);
  # Check the outcome of the response. It has to be a redirect to /
  # If it's not a redirect or redirects elsewhere, then the login failed.
  unless ($res->is_redirect()) {
    print("# ERROR logging into modem webinterface (1)\n");
    return undef;
  }
  unless ($res->header('Location') eq '/') {
    print("# ERROR logging into modem webinterface (2)\n");
    return undef;
  }
  unless (defined($res->header('Set-Cookie'))) {
    print("# ERROR logging into modem webinterface (3)\n");
    return undef;
  }
  unless ($res->header('Set-Cookie') =~ m/SESSION_ID_VIGOR=([a-zA-Z0-9]+)/) {
    print("# ERROR logging into modem webinterface (4)\n");
    return undef;
  }
  my $authcookie = $1;
  #print("Obtained auth cookie $authcookie\n");
  $res = $ua->get("http://${hn}/doc/dslstatus.sht",
                  "Cookie" => "SESSION_ID_VIGOR=${authcookie}");
  unless ($res->is_success()) {
    print("# ERROR fetching status info (1)\n");
    return undef;
  }
  my $rv = $res->content();
  # Now try to log out. We don't really care if it succeeds or not, we just
  # try not to leave session ids behind that might take up memory on the modem.
  # FIXME: doesn't work, probably because we would need to send sFormAuthStr
  #$res = $ua->get("http://${hn}/cgi-bin/wlogout.cgi",
  #                "Cookie" => "SESSION_ID_VIGOR=${authcookie}");
  #unless (defined($res->header('Set-Cookie'))) {
  #  print("# WARNING failed to log out of modem webinterface (1)\n");
  #  print($res->content());
  #}
  return $rv;
}

if ((@ARGV > 0) && ($ARGV[0] eq "autoconf")) {
  print("No\n");
  exit(0);
}
my $progname = $0;
my $hostname = '192.168.1.1';  # These are the factory defaults of the Vigor 130
my $username = 'admin';
my $password = 'admin';
if ($progname =~ m/.+_(.+)/) {
  $hostname = $1;
}
if (defined($ENV{'hostname'})) { $hostname = $ENV{'hostname'} }
if (defined($ENV{'username'})) { $username = $ENV{'username'} }
if (defined($ENV{'password'})) { $password = $ENV{'password'} }
if ((@ARGV > 0) && ($ARGV[0] eq "config")) {
  
  print("multigraph vig130_datarates\n");
  print("graph_category network\n");
  print("graph_title VDSL Data Rate\n");
  print("graph_args --lower-limit 0\n");
  print("graph_vlabel kbps\n");
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
  print("graph_category network\n");
  print("graph_title SNR margins\n");
  print("graph_vlabel dB\n");
  print("snrmargindn.label downstream snr margin\n");
  print("snrmargindn.type GAUGE\n");
  print("snrmargindn.draw LINE1.5\n");
  print("snrmargindn.info The current SNR margin for the downstream. SNR margin is the difference between the current SNR value and the minimum SNR value required to sync, so a higher value means a more stable connection.\n");
  print("snrmarginup.label upstream snr margin\n");
  print("snrmarginup.type GAUGE\n");
  print("snrmarginup.draw LINE1.5\n");
  print("snrmarginup.info The current SNR margin for the upstream.\n");
  
  print("multigraph vig130_attenuation\n");
  print("graph_category network\n");
  print("graph_title attenuation\n");
  print("graph_vlabel dB\n");
  print("attenuationdn.label attenuation downstream\n");
  print("attenuationdn.type GAUGE\n");
  print("attenuationdn.draw LINE1.5\n");
  print("attenuationdn.info The attenuation on the downstream. Attenuation is how much signal strength is lost on the line, lower is better.\n");
  print("attenuationup.label attenuation upstream\n");
  print("attenuationup.type GAUGE\n");
  print("attenuationup.draw LINE1.5\n");
  print("attenuationup.info The attenuation on the upstream.\n");
  
  #print("snrmargindn.info PSD is the power spectrum density but si\n");
  
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
my $curdnrate = 'U';
my $curuprate = 'U';
my $attdnrate = 'U';
my $attuprate = 'U';
my $snrmargindn = 'U';
my $snrmarginup = 'U';
my $attenuationdn = 'U';
my $attenuationup = 'U';
if ($dslsp =~ m!Attainable Rate</td><td>(.*?)</td><td>.*?</td><td>(.*?)</td>!) {
  $attdnrate = int($1);
  $attuprate = int($2);
}
if ($dslsp =~ m!Actual Rate</td><td>(.*?)</td><td>.*?</td><td>(.*?)</td>!) {
  $curdnrate = int($1);
  $curuprate = int($2);
}
if ($dslsp =~ m!SNR Margin</td><td>(.*?)</td><td>.*?</td><td>(.*?)</td>!) {
  $snrmargindn = $1;
  $snrmarginup = $2;
}
if ($dslsp =~ m!Attenuation</td><td>(.*?)</td><td>.*?</td><td>(.*?)</td>!) {
  $attenuationdn = $1;
  $attenuationup = $2;
}
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
