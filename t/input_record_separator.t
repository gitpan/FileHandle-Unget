use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 7;

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
  is($line1, "first line\n", 'First line');

  local $/ = undef;
  my $line2 = <$fh1>;

  # 2
  is($line2, "second line\nthird line\n", 'No eol separator');

  $fh1->close;
}

# Test per-filehandle input record separator for 1 filehandle
{
  my $fh1 = new FileHandle::Unget($filename);

  local $/ = "\n";
  my $line1 = <$fh1>;

  # 3
  is($line1, "first line\n", 'First line');

  $fh1->input_record_separator("\n");

  local $/ = undef;
  my $line2 = <$fh1>;

  # 4
  is($line2, "second line\n", 'Second line');

  $fh1->ungets($line2);
  $fh1->clear_input_record_separator();
  my $line3 = <$fh1>;

  #5
  is($line3, "second line\nthird line\n", 'Newline end of file');

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
  is($line1, "first line\n", 'First line');
  # 7
  is($line2, "first line\nsecond line\nthird line\n", 'Undef end of line');

  $fh1->close;
  $fh2->close;
}

