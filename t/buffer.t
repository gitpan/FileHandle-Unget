# Test ungetc

use lib 'lib';
use FileHandle;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 3);

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

# Test ungetc'ing and reading a line of data
{
  my $fh = new FileHandle::Unget($filename);

  my $line = <$fh>;

  $fh->ungetc(ord("\n"));
  $fh->ungetc(ord("d"));
  $fh->ungetc(ord("e"));
  $fh->ungetc(ord("t"));
  $fh->ungetc(ord("r"));
  $fh->buffer("inse" . $fh->buffer);

  # 1
  ok($fh->buffer, "inserted\n");

  $line = <$fh>;

  # 2
  ok($line, "inserted\n");

  $line = <$fh>;
  # 3
  ok($line, "second line\n");

  $fh->close;
}

