# Some tests for FileHandle compatibility

use strict;
use lib 'lib';
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 4);

my $filename = catfile('t','temp', 'output.txt');

{
  mkdir catfile('t','temp'), 0700;
  unlink $filename;

  my $fh = new FileHandle(">$filename");
  print $fh "first line\n";
  print $fh "second line\n";
  close $fh;
}

# Test getline on the end of the file
{
  my $fh = new FileHandle::Unget($filename);

  my $line;
  
  $line = <$fh>;
  # 1
  ok($line,"first line\n");

  $line = <$fh>;
  # 2
  ok($line,"second line\n");

  $line = <$fh>;
  # 3
  ok($line,undef);

  $fh->close;
}

# Test getlines on the end of the file
{
  my $fh = new FileHandle::Unget($filename);

  my $line;
  
  $line = <$fh>;
  $line = <$fh>;

  my @lines = $fh->getlines();
  # 4
  ok($lines[0],undef);

  $fh->close;
}
