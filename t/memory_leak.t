use strict;
use lib 'lib';
use FileHandle::Unget;
use Test;

plan (tests => 1);

eval 'require Devel::Leak';

# For initial memory allocation
new FileHandle::Unget();

# Check for memory leaks.
if (defined $Devel::Leak::VERSION)
{
  my $fhu_handle;

  my $start_fhu = Devel::Leak::NoteSV($fhu_handle);

  my $fhu = new FileHandle::Unget();
  undef $fhu;

  my $end_fhu = Devel::Leak::NoteSV($fhu_handle);

  # 1
  ok($end_fhu - $start_fhu,0);
}
else
{
  skip('Devel::Leak not installed',1);
}
