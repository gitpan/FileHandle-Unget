use strict;
use lib 'lib';
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test;

plan (tests => 7);

my $filename = catfile('t','temp', 'output.txt');

{
  print "Writing file\n";

  mkdir catfile('t','temp'), 0700;
  unlink $filename;

  my $fh = new FileHandle(">$filename");
  print $fh "first line\n";
  print $fh "second line\n";
  print $fh "third line\n";
  close $fh;
}

# Test normal semantics for input record separators
{
  my $fh1 = new FileHandle::Unget($filename);

  local $/ = "\n";
  my $line1 = <$fh1>;

  # 1
  ok($line1, "first line\n");

  local $/ = undef;
  my $line2 = <$fh1>;

  # 2
  ok($line2, "second line\nthird line\n");

  $fh1->close;
}

# Test per-filehandle input record separator for 1 filehandle
{
  my $fh1 = new FileHandle::Unget($filename);

  local $/ = "\n";
  my $line1 = <$fh1>;

  # 3
  ok($line1, "first line\n");

  $fh1->input_record_separator("\n");

  local $/ = undef;
  my $line2 = <$fh1>;

  # 4
  ok($line2, "second line\n");

  $fh1->ungets($line2);
  $fh1->clear_input_record_separator();
  my $line3 = <$fh1>;

  #5
  ok($line3, "second line\nthird line\n");

  $fh1->close;
}


# Test per-filehandle input record separator for 2 filehandles
{
  my $fh1 = new FileHandle::Unget($filename);
  my $fh2 = new FileHandle::Unget($filename);

  local $/ = ' ';

  $fh1->input_record_separator("\n");
  $fh2->input_record_separator(undef);

  my $line1 = <$fh1>;
  my $line2 = <$fh2>;

  # 6
  ok($line1, "first line\n");
  # 7
  ok($line2, "first line\nsecond line\nthird line\n");

  $fh1->close;
  $fh2->close;
}

