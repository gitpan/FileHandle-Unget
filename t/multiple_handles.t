use strict;
use lib 'lib';
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 4);

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
  my $fh1 = new FileHandle::Unget($filename);
  my $fh2 = new FileHandle::Unget($filename);

  my $line = <$fh1>;
  $line = <$fh2>;

  $fh1->ungets("inserted 1\n");
  $fh2->ungets("inserted 2\n");

  $line = <$fh1>;
  # 1
  ok($line, "inserted 1\n");

  $line = <$fh2>;
  # 2
  ok($line, "inserted 2\n");

  $line = <$fh1>;
  # 3
  ok($line, "second line\n");

  $line = <$fh2>;
  # 4
  ok($line, "second line\n");

  $fh1->close;
  $fh2->close;
}

