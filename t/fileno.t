use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 1;

my $filename = catfile('t','temp', 'output.txt');

# Test "print" and "syswrite" to write/append a file, close $fh
{
  mkdir catfile('t','temp'), 0700;
  unlink $filename;

  my $fh = new FileHandle::Unget(">$filename");
  print $fh "first line\n";

  # 1
  like(fileno($fh), qr/^\d+$/, 'fileno()');

  close $fh;
}

