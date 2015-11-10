#!/usr/bin/perl
=comment
use strict;
use warnings;

use Proc::Daemon;
use Proc::PID::File;
use Time::ParseDate;
use DBI;
use stock_data_access;
MAIN:
{
    # Daemonize
    Proc::Daemon::Init();

    # If already running, then exit
    if (Proc::PID::File->running()) {
        exit(0);
    }

    # Perform initializes here

    # Enter loop to do work
        # Do whatcha gotta do
	my($day, $month, $year)=(localtime)[3,4,5];
        my $today = "$day/".($month+1)."/".($year+1900);
	my @output = `./quotehist.pl --open --high --low --close --vol --from=\"1/1/2015\" --to=\"$today\" NKE`;
          #print "query : ./quotehist.pl --open --high --low --close --vol --from=\"$from\" --to=\"$today\" $symbol";
          foreach my $newDataEntry (@output) { 
              my @splitString = split(' ', $newDataEntry);
              my $timestamp =$splitString[0];
              my $open = $splitString[1];
              my $high = $splitString[2];
              my $low = $splitString[3];
              my $close = $splitString[4];
              my $volume = $splitString[5];

              my $error;
              $error=AddStockInfo("NKE", $timestamp, $open, $high, $low, $close, $volume);
              if ($error) { 
                print "Can't add stock info because: $error";
              } else {
                print "Added stock info for $symbol\n";
              }
         # print "Hello"
    }
}
