use strict;
use FileHandle;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 3;

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
  is($fh->buffer, "inserted\n");

  $line = <$fh>;

  # 2
  is($line, "inserted\n");

  $line = <$fh>;
  # 3
  is($line, "second line\n");

  $fh->close;
}

