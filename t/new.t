# Some tests for FileHandle compatibility

use strict;
use lib 'lib';
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 12);

my $filename = catfile('t','temp', 'output.txt');

# Test "print" and "syswrite" to write/append a file, close $fh
{
  mkdir catfile('t','temp'), 0700;
  unlink $filename;

  my $fh1 = new FileHandle(">$filename");
  my $fh = new FileHandle::Unget($fh1);
  print $fh "first line\n";
  close $fh;

  $fh1 = new FileHandle(">>$filename");
  $fh = new FileHandle::Unget($fh1);
  syswrite $fh, "second line\n";
  FileHandle::Unget::close($fh);

  $fh = new FileHandle($filename);
  local $/ = undef;
  my $results = <$fh>;
  close $fh;

  # 1
  ok($results, "first line\nsecond line\n");
}

# Test input_line_number and scalar line reading, $fh->close
{
  my $fh1 = new FileHandle($filename);
  my $fh = new FileHandle::Unget($fh1);

  # 2
  ok($fh->input_line_number(),0);

  my $line = <$fh>;
  # 3
  ok($line,"first line\n");

  $line = <$fh>;
  # 4
  ok($fh->input_line_number(),2);

  $fh->close;
}

# Test array line reading, eof $fh
{
  my $fh1 = new FileHandle($filename);
  my $fh = new FileHandle::Unget($fh1);

  my @lines = <$fh>;
  # 5
  ok($#lines,1);
  # 6
  ok($lines[0],"first line\n");
  # 7
  ok($lines[1],"second line\n");

  # 8
  ok(eof $fh,1);

  $fh->close;
}

# Test byte reading
{
  my $fh1 = new FileHandle($filename);
  my $fh = new FileHandle::Unget($fh1);

  my $buf;
  my $result = read($fh, $buf, 8);

  # 9
  ok($buf,'first li');
  # 10
  ok($result,8);

  $fh->close;
}

# Test byte ->reading
{
  my $fh1 = new FileHandle($filename);
  my $fh = new FileHandle::Unget($fh1);

  my $buf;
  my $result = $fh->read($buf, 8);

  # 11
  ok($buf,'first li');
  # 12
  ok($result,8);

  $fh->close;
}
