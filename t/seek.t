# Some tests for FileHandle compatibility

use strict;
use lib 'lib';
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 3);

my $filename = catfile('t','temp', 'output.txt');

# Test "print" and "syswrite" to write/append a file, close $fh
{
  mkdir catfile('t','temp'), 0700;
  unlink $filename;

  my $fh = new FileHandle(">$filename");
  binmode $fh;
  print $fh "first line\n";
  print $fh "second line\n";
  close $fh;
}

# Test seek($fh,###,0) and ungets
{
  my $fh = new FileHandle::Unget($filename);

  seek($fh,11,0);
  my $line = <$fh>;

  # 1
  ok($line,"second line\n");

  $fh->ungets('1234567890');

  seek($fh,0,0);
  $line = <$fh>;

  # 2
  ok($line,"first line\n");

  seek($fh,0,0);
  $fh->ungets("1234567890\n");

  seek($fh,-11,0);
  $line = <$fh>;

  # 3
  ok($line,"1234567890\n");

  $fh->close;
}

