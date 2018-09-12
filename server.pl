#!/usr/bin/perl

use strict;
use IO::Socket::UNIX;
use Carp;
use Time::HiRes qw(time alarm);
use Data::Dumper;

# tuned for quick transactions
my $TIMEOUT_SECS = 0.001;

# unbufferred, line oriented, nl terminated ascii stream, with request, empty_line, and response
$|=1;

$SIG{PIPE}='IGNORE';

my $SOCK_PATH = "/tmp/foo";
my $listener;

sub start {
    print tm() . " intializing socket\n";
    unlink $SOCK_PATH or die;
    $listener = IO::Socket::UNIX->new(
        Type => SOCK_STREAM(),
        Local => $SOCK_PATH,
        Listen => 5,
    ) or die;
    listener();
    print tm() . " the end\n";
}

sub tm {
    sprintf "%.6f", time();
}

my $count = 1;
sub listener {
    print tm() . " starting listener\n";
    while (my $conn = $listener->accept()) {
        print tm() . " $count read begin\n";
        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            alarm $TIMEOUT_SECS;
            comms($conn);
            alarm 0;
        };
        if ($@) { print tm() . " $count closing slow connection\n"; close $conn; }
        alarm 0;
        print tm() . " $count write end\n";
        $count++;
    }
    print $@;
}

sub comms {
    my $conn = shift;
    my $error=1;

    my $lines = 0;
    my $bytes = 0;
    while(my $received_data = <$conn>) {
        $lines++; $bytes+=length $received_data;
        if($received_data =~ /^\s*$/) { $error=0; print tm() . " $count read end\n"; last; }
        print tm() . " $count data: " . $received_data;
    }
    if(!$error) {
        my $msg = tm() . " Request $count, received $lines lines and $bytes bytes\n";
        print $conn $msg or warn;
    }
    else {
        print tm() . " Request $count, recv failed, bad message?, stopped at $lines lines and $bytes bytes\n";
    }
}

start();

