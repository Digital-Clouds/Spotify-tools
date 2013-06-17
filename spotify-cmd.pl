#!/usr/bin/perl -T
#
#  Author: Hari Sekhon
#  Date: 2013-06-16 23:42:48 +0100 (Sun, 16 Jun 2013)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#

$DESCRIPTION = "Command line interface to Spotify on Mac that leverages AppleScript

Useful for automation that Mac HotKeys don't help with,
such as auto skipping through a playlist after x secs";

$VERSION = "0.2";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/lib";
}
use HariSekhonUtils qw/:DEFAULT :time/;

$usage_line = "$progname <cmd>

cmds:

play            Play
pause / stop    Pause
playpause       Toggle Play/Pause
previous        Previous Track and print previous track information
next [secs]     Next Track and print next track information.
                Specifying optional secs will skip to next track
                every [secs] seconds. Handy for skipping through a playlist
                every 60 secs automatically and grabbing the good songs. Prints
                track information every time it skips to the next track

status          Show current track details

vol up          Turn volume up
vol down        Turn volume down
vol <1-100>     Set volume to number <1-100>

exit / quit     Exit Spotify";

my $quiet;
%options = (
    "q|quiet"   => [ \$quiet, "Quiet mode. Do not print track information or volume after completing action" ],
);

get_options();

my $cmd = $ARGV[0] || usage;
my $arg = $ARGV[1] if $ARGV[1];

$cmd = lc $cmd;
$arg = lc $arg if $arg;

mac_only();

$cmd = isAlNum($cmd) || usage "invalid cmd";
if(defined($arg)){
    $arg = isAlNum($arg) || usage "invalid arg";
}

my %cmds = (
    "play"            => "play",
    "pause"           => "pause",
    "stop"            => "pause",
    "playpause"       => "playpause",
    "next"            => "next track",
    "prev"            => "previous track",
    "quit"            => "quit",
    "exit"            => "quit",
);

vlog2;
set_timeout();

my $osascript = which("osascript");
my $spotify_app = "Spotify";
my $cmdline = "$osascript -e 'tell applications \"$spotify_app\" to ";

my %state;
sub get_state(){
    # TODO: make this more efficient, return all at once if possible, check on this later
    $state{"status"}       = `$cmdline player state as string'`                     || die "failed to get Spotify status\n";
    $state{"artist"}       = `$cmdline artist of current track as string'`          || die "failed to get current artist\n";
    $state{"album"}        = `$cmdline album of current track as string'`           || die "failed to get current album\n";
    $state{"starred"}      = `$cmdline starred of current track as string'`         || die "failed to get current starred status\n";
    $state{"track"}        = `$cmdline name of current track as string'`            || die "failed to get current track\n";
    $state{"duration"}     = `$cmdline duration of current track as string'`        || die "failed to get duration of current track\n";
    $state{"position"}     = `$cmdline player position as string'` || die "failed to get position of current track\n";
    $state{"popularity"}   = `$cmdline popularity of current track as string'`      || die "failed to get popularity of current track\n";
    $state{"played count"} = `$cmdline played count of current track as string'`    || die "failed to get played count of current track\n";
    $state{"duration"} = sec2min($state{"duration"}) . "\n" if $state{"duration"};
    $state{"position"} = sec2min($state{"position"}) . "\n" if $state{"position"};
}


sub print_state(){
    get_state();
    foreach((qw/status starred artist album track duration position popularity/, "played count")){
        $state{$_} = "Unknown (external track?)\n" unless $state{$_};
        printf "%-14s %s", ucfirst("$_:"), $state{$_};
    }
}

sub get_vol(){
    my $current_vol = `$cmdline sound volume as integer'`;
    $current_vol =~ /^(\d+)$/ || die "failed to determine current volume\n";
    return $1;
}

if($cmd eq "status"){
    print_state();
} elsif($cmd eq "vol"){
    my $new_vol;
    if(defined($arg)){
        if($arg eq "up" or $arg eq "down"){
            my $current_vol = get_vol();
            vlog "Old Volume: $current_vol" unless $quiet;
            if($arg eq "up"){
                $new_vol = $current_vol + 10;
            } elsif($arg eq "down"){
                $new_vol = $current_vol - 10;
            }
        } elsif(isInt($arg)){
            $new_vol = $arg;
        } else {
            usage "vol arg must be an integer";
        }
    } else {
        print "Volume: " . get_vol() . "%\n";
        exit 0;
    }
    $new_vol = 0 if $new_vol < 0;
    $new_vol = 100 if $new_vol > 100;
    print cmd($cmdline . "set sound volume to $new_vol'");
    print "Volume: " . get_vol() . "%\n" unless $quiet;
} else {
    if(grep $cmd, keys %cmds){
        my $cmdline2 = "$cmdline $cmds{$cmd}'";
        if($cmd eq "next" and $arg){
            isInt($arg) or usage "arg to next must be an integer representing seconds before skipping to the next track";
            while(1){
                # reset timeout so we can stay in infinite loop and iterate over playlist
                alarm 0;
                sleep $arg;
                print "\n";
                set_timeout();
                print cmd($cmdline2);
                print_state() unless $quiet;
            }
        } elsif($cmd eq "prev" or
                $cmd eq "next"){
            print cmd($cmdline2);
            print_state() unless $quiet;
        } else {
            print cmd($cmdline2);
        }
    } else {
        usage "unknown command given";
    }
}
