use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 3;

# -------------------------------------------------------------------------------

use vars qw( %PROGRAMS $single_quote $command_separator $set_env );

if ($^O eq 'MSWin32')
{
  $set_env = 'set';
  $single_quote = '"';
  $command_separator = '&';
}
else
{
  $set_env = '';
  $single_quote = "'";
  $command_separator = '';
}

# -------------------------------------------------------------------------------

my $test_program = catfile 't','temp', 'test_program.pl';

mkdir catfile('t','temp'), 0700;
Write_Test_Program($test_program);

my $test = "echo hello | $test_program";
my $expected_stdout = qr/Starting at position (-1|0)\ngot: hello\ngot: world\n/;
my $expected_stderr = '';

{
  my @standard_inc = split /###/, `perl -e '\$" = "###";print "\@INC"'`;
  my @extra_inc;
  foreach my $inc (@INC)
  {
    push @extra_inc, "$single_quote$inc$single_quote"
      unless grep { /^$inc$/ } @standard_inc;
  }

  local $" = ' -I';
  if (@extra_inc)
  {
    $test =~ s#\b$test_program\b#$^X -I@extra_inc $test_program#g;
  }
  else
  {
    $test =~ s#\b$test_program\b#$^X $test_program#g;
  }
}

my $test_stdout = catfile('t','temp',"test_program.stdout");
my $test_stderr = catfile('t','temp',"test_program.stderr");

system "$test 1>$test_stdout 2>$test_stderr";

ok(!$?,'Executing external program');

local $/ = undef;
my $actual_stdout;
open ACTUAL_STDOUT, $test_stdout;
$actual_stdout = <ACTUAL_STDOUT>;
close ACTUAL_STDOUT;

my $actual_stderr;
open ACTUAL_STDERR, $test_stderr;
$actual_stderr = <ACTUAL_STDERR>;
close ACTUAL_STDERR;

like($actual_stdout,$expected_stdout,'Output matches');

is($actual_stderr,$expected_stderr,'Stderr matches');

# -------------------------------------------------------------------------------

sub Write_Test_Program
{
  my $filename = shift;

  local $/ = undef;

  my $program = <DATA>;

  open PROGRAM, ">$filename";
  print PROGRAM $program;
  close PROGRAM;
}

# -------------------------------------------------------------------------------

__DATA__
use strict;
use FileHandle::Unget;

my $fh = new FileHandle::Unget(\*STDIN);

print 'Starting at position ', tell($fh), "\n";

# 1
print "got: ", scalar <$fh>;

$fh->ungets("world\n");

# 2
print "got: ", scalar <$fh>;
