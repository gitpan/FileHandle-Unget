# Test ungets

use lib 'lib';
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 9);

my $filename = catfile('t','temp', 'output.txt');

{
  print "Writing file\n";

  mkdir catfile('t','temp'), 0700;
  unlink $filename;

  my $fh = new FileHandle(">$filename");
  print $fh "first line\n";
  print $fh "second line\n";
  close $fh;
}

# Test ungets'ing and reading a line of data
{
  my $fh = new FileHandle::Unget($filename);

  my $line = <$fh>;

  $fh->ungets("inserted\n");

  $line = <$fh>;

  # 1
  ok($line, "inserted\n");

  $line = <$fh>;
  # 2
  ok($line, "second line\n");

  $fh->close;
}

# Test ungets'ing and read'in some bytes of data
{
  my $fh = new FileHandle::Unget($filename);

  my $line = <$fh>;

  $fh->ungets("inserted\n");

  read($fh, $line, 6);
  # 3
  ok($line, "insert");

  $line = <$fh>;
  # 4
  ok($line, "ed\n");

  $line = <$fh>;
  # 5
  ok($line, "second line\n");

  $fh->close;
}


# Test ungets'ing and reading multiple lines of data
{
  my $fh = new FileHandle::Unget($filename);

  my $line = <$fh>;

  $fh->ungets("inserted1\ninserted2\n");

  read($fh, $line, 6);
  # 6
  ok($line, "insert");

  $line = <$fh>;
  # 7
  ok($line, "ed1\n");

  $line = <$fh>;
  # 8
  ok($line, "inserted2\n");

  $line = <$fh>;
  # 9
  ok($line, "second line\n");

  $fh->close;
}

