# Test ungetc

use lib 'lib';
use FileHandle;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 8);

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
  $fh->ungetc(ord("e"));
  $fh->ungetc(ord("s"));
  $fh->ungetc(ord("n"));
  $fh->ungetc(ord("i"));

  $line = <$fh>;

  # 1
  ok($line, "inserted\n");

  $line = <$fh>;
  # 2
  ok($line, "second line\n");

  $fh->close;
}

# Test ungetc'ing and read'ing some bytes of data
{
  my $fh = new FileHandle::Unget($filename);

  my $line = <$fh>;

  $fh->ungetc(ord("\n"));
  $fh->ungetc(ord("d"));
  $fh->ungetc(ord("e"));
  $fh->ungetc(ord("t"));
  $fh->ungetc(ord("r"));
  $fh->ungetc(ord("e"));
  $fh->ungetc(ord("s"));
  $fh->ungetc(ord("n"));
  $fh->ungetc(ord("i"));

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


# Test ungetc'ing and ->read'ing some bytes of data
{
  my $fh = new FileHandle::Unget($filename);

  my $line = <$fh>;

  $fh->ungetc(ord("\n"));
  $fh->ungetc(ord("d"));
  $fh->ungetc(ord("e"));
  $fh->ungetc(ord("t"));
  $fh->ungetc(ord("r"));
  $fh->ungetc(ord("e"));
  $fh->ungetc(ord("s"));
  $fh->ungetc(ord("n"));
  $fh->ungetc(ord("i"));

  $fh->read($line, 6);
  # 6
  ok($line, "insert");

  $line = <$fh>;
  # 7
  ok($line, "ed\n");

  $line = <$fh>;
  # 8
  ok($line, "second line\n");

  $fh->close;
}

