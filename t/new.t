use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 12;

my $filename = catfile('t','temp', 'output.txt');

# Test "print" and "syswrite" to write/append a file, close $fh
{
  mkdir catfile('t','temp'), 0700;
  unlink $filename;

  my $fh1 = new FileHandle(">$filename");
  my $fh = new FileHandle::Unget($fh1);
  print $fh "first line\n";
  close $fh;

  $fh1 = new FileHandle(">>$filename");
  $fh = new FileHandle::Unget($fh1);
  syswrite $fh, "second line\n";
  FileHandle::Unget::close($fh);

  $fh = new FileHandle($filename);
  local $/ = undef;
  my $results = <$fh>;
  close $fh;

  # 1
  is($results, "first line\nsecond line\n", 'syswrite()');
}

# Test input_line_number and scalar line reading, $fh->close
{
  my $fh1 = new FileHandle($filename);
  my $fh = new FileHandle::Unget($fh1);

  # 2
  is($fh->input_line_number(),0,'input_line_number()');

  my $line = <$fh>;
  # 3
  is($line,"first line\n",'First line');

  $line = <$fh>;
  # 4
  is($fh->input_line_number(),2,'Second line');

  $fh->close;
}

# Test array line reading, eof $fh
{
  my $fh1 = new FileHandle($filename);
  my $fh = new FileHandle::Unget($fh1);

  my @lines = <$fh>;
  # 5
  is($#lines,1,'getlines()');
  # 6
  is($lines[0],"first line\n",'First line');
  # 7
  is($lines[1],"second line\n",'Second line');

  # 8
  ok(eof $fh,'EOF');

  $fh->close;
}

# Test byte reading
{
  my $fh1 = new FileHandle($filename);
  my $fh = new FileHandle::Unget($fh1);

  my $buf;
  my $result = read($fh, $buf, 8);

  # 9
  is($buf,'first li','read() function (filehandle)');
  # 10
  is($result,8,'Number of bytes read (filehandle)');

  $fh->close;
}

# Test byte ->reading
{
  my $fh1 = new FileHandle($filename);
  my $fh = new FileHandle::Unget($fh1);

  my $buf;
  my $result = $fh->read($buf, 8);

  # 11
  is($buf,'first li','read() method (filehandle)');
  # 12
  is($result,8,'Number of bytes read (filehandle)');

  $fh->close;
}
