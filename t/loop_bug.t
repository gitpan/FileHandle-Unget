# Some tests for FileHandle compatibility

use strict;
use lib 'lib';
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 1);

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

  binmode $fh;

  my $string;
  read($fh,$string,5);
  $fh->ungets($string);

  my $line;

  my $bytes_read = 0;
  
  while($line = <$fh>)
  {
    $bytes_read += length $line;

    last if $bytes_read > -s $filename;
  }

  # 1
  ok($bytes_read,-s $filename);

  $fh->close;
}
