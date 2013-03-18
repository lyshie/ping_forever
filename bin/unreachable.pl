#!/usr/bin/env perl
#===============================================================================
#
#         FILE: unreachable.pl
#
#        USAGE: ./unreachable.pl www.google.com
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: SHIE, Li-Yi
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 2013/03/18 15:21:58
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use FindBin qw($RealBin);
use Digest::MD5 qw(md5_hex);
use File::Basename;

my $HASHED      = md5_hex( $ARGV[0] || die('ERROR: No given hostname') );
my $PF_PATH     = dirname($RealBin);
my $PF_LOG_PATH = "$PF_PATH/log";
my $PF_LOG_FILE = "$PF_LOG_PATH/$HASHED.log";

my $current = time();

open( FH, "<", $PF_LOG_FILE ) or die("ERROR: Can't open $PF_LOG_FILE");
while (<FH>) {
    if (m/unreachable/) {
        $current++;
        chomp;
        print scalar( localtime($current) ), " ($_)\n";
    }
    else {
        if (m/^\[(\d+)\.\d+\]/) {
            $current = $1;
        }
    }
}
close(FH);
