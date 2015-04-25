#!/usr/bin/perl
#
# This find the seconds for midday today then takes 86400 off that
# because if we're near midnight on a DST boundary
# we would fall into the wrong day by doing now -24hr
#
use strict;
use warnings;

use Time::Local;
my $store_dir = './pool/retention/store';
my $error_dir = './pool/retention/error';

my ($sec, $min, $hrs) = (0, 0, 12);
my ($t_yr,$t_mon,$t_day) = (localtime(time))[5,4,3];

my $today = timelocal $sec, $min, $hrs, $t_day, $t_mon, $t_yr;    

my ($year,$mon,$day) = (localtime($today - 86400))[5,4,3];
my $yest = sprintf "%4d%02d%02d", $year + 1900, $mon + 1, $day;

#
#
#
my $yest_dir = "$store_dir/$yest";

opendir(my $dir_fh, $yest_dir) || die "Can't opendir '$yest_dir': $!\n";
my @files = grep { /^./ && -f "$yest_dir/$_" } readdir($dir_fh);
closedir $dir_fh;

my $total = 0;
my %type_count;
for my $file ( @files ) {

    if ( $file =~ /^(.*)_($yest)_(\d+)\.txn$/ ) {
        # print "$file\n";
        $type_count{$1}++;
        $total++;
    }

}

print "DATE : $yest\n";
my ($a,$b);
for my $pair ( "FILE TYPE:NUMBER", "---------:------" ) {
    ($a,$b) = split(/:/, $pair);
    printf "%-40s  %-6s\n", $a, $b;
}

my $dt = 0;
for my $type ( sort keys %type_count ) {
    printf "%-40s  %-6d\n", $type, $type_count{$type};
    $dt++;
}

printf "%-40s  %-6s\n", $a, $b;

printf "Distinct Types: %-18d Total: %d\n", $dt, $total;


my $yest_err_dir = "$error_dir/$yest";

opendir(my $dir_fh, $yest_err_dir) || die "Can't opendir '$yest_err_dir': $!\n";
my @err_files = grep { /^./ && -f "$yest_err_dir/$_" } readdir($dir_fh);
closedir $dir_fh;

my $err_tot = $#err_files+1;

print $/;

if ( $err_tot == 0 ) {
    print "GOOD: No files in the ERROR directory\n";
} else {
    print "ERRORS: There are $err_tot files in the ERROR directory:\n";
    for my $err_file ( @err_files ) {
        my $file = "$yest_err_dir/$err_file";
        my $size = (stat($file))[7] or die "Can't stat '$file': $!\n";
        printf "  $err_file ($size bytes)\n";
    }
}

