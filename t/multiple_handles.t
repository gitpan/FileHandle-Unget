use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 4;

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
  is($line, "inserted 1\n", 'Unget 1');

  $line = <$fh2>;
  # 2
  is($line, "inserted 2\n", 'Unget 2');

  $line = <$fh1>;
  # 3
  is($line, "second line\n", 'Get 1');

  $line = <$fh2>;
  # 4
  is($line, "second line\n", 'Get 2');

  $fh1->close;
  $fh2->close;
}

