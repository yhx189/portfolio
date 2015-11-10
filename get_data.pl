#!/usr/bin/perl -w

use Getopt::Long;
use Time::ParseDate;
use Time::CTime;
use FileHandle;

use stock_data_access;

$close=1;

$notime=0;
$open=0;
$high=0;
$low=0;
$close=0;
$vol=0;
$from=0;
$to=0;
$plot=0;
$nohistorical=0;
$current=0;
$predicted=0;

&GetOptions( "notime"=>\$notime,
             "open" => \$open,
       "high" => \$high,
       "low" => \$low,
       "close" => \$close,
       "vol" => \$vol,
       "from=s" => \$from,
       "to=s" => \$to, 
       "plot" => \$plot,
       "nohistorical" => \$nohistorical,
       "current" => \$current,
       "predicted" => \$predicted);

if (defined $from) { $from=parsedate($from); }
if (defined $to) { $to=parsedate($to); }

#print "FROM: $from";

$usage = "usage: get_data.pl [--open] [--high] [--low] [--close] [--vol] [--from=time] [--to=time] [--plot] [--nohistorical] [--current] [--predicted] SYMBOL\n";

$#ARGV == 0 or die $usage;

$symbol = shift;

push @fields, "timestamp" if !$notime;
push @fields, "open" if $open;
push @fields, "high" if $high;
push @fields, "low" if $low;
push @fields, "close" if $close;
push @fields, "volume" if $vol;


my $sql;

if(!$nohistorical){
  $sql = "select " . join(",",@fields) . " from ".GetStockPrefix()."StocksDaily";
  $sql.= " where symbol = '$symbol'";
  $sql.= " and timestamp IS NOT NULL";
  $sql.= " and timestamp >= $from" if $from;
  $sql.= " and timestamp <= $to" if $to;
}
if (!$nohistorical && $current){
  $sql .= " union all ";
}
if($current){
  $sql .= "select " . join(",",@fields) . " from newStockData";
  $sql.= " where symbol = '$symbol'";
  $sql.= " and timestamp IS NOT NULL";
  $sql.= " and timestamp >= $from" if $from;
  $sql.= " and timestamp <= $to" if $to;
}

#if ($current && $predicted){
#  $sql .= " union all ";
# }
# if($predicted){
#   $sql .= "select " . join(",",@fields) . " from predictedStockData";
#   $sql.= " where symbol = '$symbol'";
#   $sql.= " and timestamp >= $from" if $from;
#   $sql.= " and timestamp <= $to" if $to;
# }
if((!$nohistorical || $current) && !$notime){
  $sql.= " order by timestamp";
}


my $data = ExecStockSQL("TEXT",$sql);

if (!$plot) { 
  print $data;
}


