# Some tests for FileHandle compatibility

use strict;
use lib 'lib';
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 5);

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

# Test tell($fh) and scalar line reading
{
  my $fh = new FileHandle::Unget($filename);

  my $line = <$fh>;
  # 1
  ok(tell($fh),11);

  $line = <$fh>;
  # 2
  ok(tell($fh),23);

  $fh->close;
}

# Test tell($fh) and ungets
{
  my $fh = new FileHandle::Unget($filename);

  my $line = <$fh>;
  # 3
  ok(tell($fh),11);

  $fh->ungets('12345');
  # 4
  ok(tell($fh),6);

  $fh->ungets('1234567890');
  # 5
  ok(tell($fh),-4);

  $fh->close;
}

