use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 5;

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
  is(tell($fh),11,'Tell 1');

  $line = <$fh>;
  # 2
  is(tell($fh),23,'Tell 2');

  $fh->close;
}

# Test tell($fh) and ungets
{
  my $fh = new FileHandle::Unget($filename);

  my $line = <$fh>;
  # 3
  is(tell($fh),11,'Tell 3');

  $fh->ungets('12345');
  # 4
  is(tell($fh),6,'Tell 4');

  $fh->ungets('1234567890');
  # 5
  is(tell($fh),-4,'Tell 5');

  $fh->close;
}

