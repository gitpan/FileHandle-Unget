use strict;
use lib 'lib';
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

if ($^O =~ /Win32/i)
{
  plan (tests => 2, todo => [1,2]);
}
else
{
  plan (tests => 2);
}

my $filename = catfile('t','temp', 'output.txt');

{
  mkdir catfile('t','temp'), 0700;
  unlink $filename;

  my $fh = new FileHandle(">$filename");
  binmode $fh;
  print $fh "first line\n";
  print $fh "second line\n";
  print $fh "a line\n" x 1000;
  close $fh;
}

# Test eof followed by binmode for streams (fails under Windows)
{
  my $fh = new FileHandle::Unget("$^X -e \"open F, '$filename';binmode STDOUT;print <F>\" |");

  print '' if eof($fh);
  binmode $fh;

  # 1
  ok(scalar <$fh>,"first line\n");

  # 2
  ok(scalar <$fh>,"second line\n");

  $fh->close;
}
