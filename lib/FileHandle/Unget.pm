package FileHandle::Unget;

use strict;
use Symbol;
use FileHandle;
use Exporter;
use bytes;

use 5.000;

use vars qw( @ISA $VERSION $AUTOLOAD @EXPORT @EXPORT_OK );

@ISA = qw( Exporter FileHandle );

$VERSION = '0.13';

@EXPORT = @FileHandle::EXPORT;
@EXPORT_OK = @FileHandle::EXPORT_OK;

# Based on dump_methods from this most helpful post by MJD:
# http://groups.google.com/groups?selm=20020621182734.15920.qmail%40plover.com
# We can't just use AUTOLOAD because AUTOLOAD is not called for inherited
# methods
sub wrap_methods
{
  no strict 'refs';

  my $class = shift or return;
  my $seen = shift || {};

  # Locate methods in this class
  my $symtab = \%{"$class\::"};
  my @names = keys %$symtab;
  for my $method (keys %$symtab) 
  { 
    my $fullname = "$class\::$method";

    next unless defined &$fullname;
    next if defined &{__PACKAGE__ . "::$method"};
    next if $method eq 'import';

    unless ($seen->{$method})
    {
      $seen->{$method} = $fullname;

      *{$method} = sub
        {
          my $self = $_[0];

          if (ref $self eq __PACKAGE__)
          {
            shift @_;
            my $super = "SUPER::$method";
            $self->$super(@_);
          }
          else
          {
            $method = "FileHandle::$method";
            &$method(@_);
          }
        };
    }
  }

  # Traverse parent classes of this one
  my @ISA = @{"$class\::ISA"};
  for my $class (@ISA)
  {
    wrap_methods($class, $seen);
  }
}

wrap_methods('FileHandle');

#-------------------------------------------------------------------------------

sub DESTROY
{
}

#-------------------------------------------------------------------------------

sub new
{
  my $class = shift;

  my $self;

  if (defined $_[0] && defined fileno $_[0])
  {
    $self = shift;
  }
  else
  {
    $self = $class->SUPER::new(@_);
    return undef unless defined $self;
  }

  tie *$self, "${class}::Tie", $self;

  ${*$self}{'filehandle_unget_buffer'} = '';

  ${*$self}{'eof_called'} = 0;

  bless $self, $class;
  return $self;
}

#-------------------------------------------------------------------------------

sub read
{
  my $self = shift;

  tied(*$self)->read(@_);
}

#-------------------------------------------------------------------------------

sub ungetc
{
  my $self = shift;
  my $ord = shift;

  substr(${*$self}{'filehandle_unget_buffer'},0,0) = chr($ord);
}

#-------------------------------------------------------------------------------

sub ungets
{
  my $self = shift;
  my $string = shift;

  substr(${*$self}{'filehandle_unget_buffer'},0,0) = $string;
}

#-------------------------------------------------------------------------------

sub buffer
{
  my $self = shift;

  ${*$self}{'filehandle_unget_buffer'} = shift if @_;
  return ${*$self}{'filehandle_unget_buffer'};
}

###############################################################################

package FileHandle::Unget::Tie;

use strict;
use FileHandle;
use bytes;
use English '-no_match_vars';

use 5.000;

use vars qw( $VERSION $AUTOLOAD @ISA );

@ISA = qw( IO::Handle );

$VERSION = '0.10';

#-------------------------------------------------------------------------------

my %tie_mapping = (
  PRINT => 'print', PRINTF => 'printf', WRITE => 'syswrite',
  READLINE => 'getline', GETC => 'getc', READ => 'read', CLOSE => 'close',
  BINMODE => 'binmode', OPEN => 'open', EOF => 'eof', FILENO => 'fileno',
  SEEK => 'seek', TELL => 'tell',
);

#-------------------------------------------------------------------------------

sub AUTOLOAD
{
  my $name = $AUTOLOAD;
  $name =~ s/.*://;

  die "Unhandled function $name!" unless exists $tie_mapping{$name};

  my $sub = $tie_mapping{$name};

  # Alias the anonymous subroutine to the name of the sub we want ...
  no strict 'refs';
  *{$name} = sub
    {
      my $self = shift;

      $sub = 'getlines' if $sub eq 'getline' && wantarray;

      if (defined &$sub)
      {
        &$sub($self,@_);
      }
      else
      {
        # Prevent recursion
        # Temporarily disable warnings so that we don't get "untie attempted
        # while 1 inner references still exist". Not sure what's the "right
        # thing" to do here.
        {
          local $^W = 0;
          untie *{$self->{'fh'}};
        }

        $self->{'fh'}->$sub(@_);

        tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};
      }
    };

  # ... and go to it.
  goto &$name;
}

#-------------------------------------------------------------------------------

sub DESTROY
{
}

#-------------------------------------------------------------------------------

sub TIEHANDLE
{
  my $class = shift;

  my $self;

  $self = bless({}, $class);

  $self->{'fh'} = $_[0];
  
  return $self;
}

#-------------------------------------------------------------------------------

sub binmode
{
  my $self = shift;

  warn "Under windows, calling binmode after eof exposes a bug that exists in some versions of Perl.\n"
    if ${*{$self->{'fh'}}}{'eof_called'};

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  if (@_)
  {
    binmode $self->{'fh'}, @_;
  }
  else
  {
    binmode $self->{'fh'};
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};
}

#-------------------------------------------------------------------------------

sub fileno
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $fileno = fileno $self->{'fh'};

  tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};

  return $fileno;
}

#-------------------------------------------------------------------------------

sub getline
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $line;

  if (defined $INPUT_RECORD_SEPARATOR &&
      ${*{$self->{'fh'}}}{'filehandle_unget_buffer'} =~
        /(.*?$INPUT_RECORD_SEPARATOR)/)
  {
    $line = $1;
    substr(${*{$self->{'fh'}}}{'filehandle_unget_buffer'},0,length $line) = '';
  }
  else
  {
    $line = ${*{$self->{'fh'}}}{'filehandle_unget_buffer'};
    ${*{$self->{'fh'}}}{'filehandle_unget_buffer'} = '';
    my $templine = $self->{'fh'}->getline(@_);

    if ($line eq '' && !defined $templine)
    {
      $line = undef;
    }
    else
    {
      $line .= $templine;
    }
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};

  return $line;
}

#-------------------------------------------------------------------------------

sub getlines
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my @buffer_lines;

  if (defined $INPUT_RECORD_SEPARATOR)
  {
    ${*{$self->{'fh'}}}{'filehandle_unget_buffer'} =~
      s/^(.*$INPUT_RECORD_SEPARATOR)/push @buffer_lines, $1;''/mge;

    my @other_lines = $self->{'fh'}->getlines(@_);

    if (@other_lines)
    {
      if (defined $other_lines[0])
      {
        substr($other_lines[0],0,0) = ${*{$self->{'fh'}}}{'filehandle_unget_buffer'};
      }
    }
    else
    {
      if (${*{$self->{'fh'}}}{'filehandle_unget_buffer'} ne '')
      {
        unshift @other_lines, ${*{$self->{'fh'}}}{'filehandle_unget_buffer'};
      }
    }

    ${*{$self->{'fh'}}}{'filehandle_unget_buffer'} = '';

    push @buffer_lines, @other_lines;
  }
  else
  {
    $buffer_lines[0] = ${*{$self->{'fh'}}}{'filehandle_unget_buffer'};
    my $templine = ($self->{'fh'}->getlines(@_))[0];

    if ($buffer_lines[0] eq '' && !defined $templine)
    {
      $buffer_lines[0] = undef;
    }
    else
    {
      $buffer_lines[0] .= $templine;
    }
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};

  return @buffer_lines;
}

#-------------------------------------------------------------------------------

sub getc
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $char;

  if (${*{$self->{'fh'}}}{'filehandle_unget_buffer'} ne '')
  {
    $char = substr(${*{$self->{'fh'}}}{'filehandle_unget_buffer'},0,1);
    substr(${*{$self->{'fh'}}}{'filehandle_unget_buffer'},0,1) = '';
  }
  else
  {
    $char = $self->{'fh'}->getc(@_);
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};

  return $char;
}

#-------------------------------------------------------------------------------

sub read
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $scalar = \$_[0];
  my $length = $_[1];
  my $offset = $_[2];

  my $num_bytes_read = 0;

  if (${*{$self->{'fh'}}}{'filehandle_unget_buffer'} ne '')
  {
    my $read_string = substr(${*{$self->{'fh'}}}{'filehandle_unget_buffer'},0,$length);
    substr(${*{$self->{'fh'}}}{'filehandle_unget_buffer'},0,$length) = '';

    my $num_bytes_buffer = length $read_string;

    # Try to read the rest
    if (length($read_string) < $length)
    {
      $num_bytes_read = read($self->{'fh'}, $read_string,
        $length - $num_bytes_buffer, $num_bytes_buffer);
    }

    if (defined $offset)
    {
      $$scalar = '' unless defined $$scalar;
      substr($$scalar,$offset) = $read_string;
    }
    else
    {
      $$scalar = $read_string;
    }

    $num_bytes_read += $num_bytes_buffer;
  }
  else
  {
    if (defined $_[2])
    {
      $num_bytes_read = read($self->{'fh'},$_[0],$_[1],$_[2]);
    }
    else
    {
      $num_bytes_read = read($self->{'fh'},$_[0],$_[1]);
    }
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};

  return $num_bytes_read;
}

#-------------------------------------------------------------------------------

sub seek
{
  my $self = shift;
  my $position = $_[0];
  my $whence = $_[1];

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  if($whence != 0 && $whence != 1 && $whence != 2)
  {
    tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};
    return 0;
  }

  my $status;

  # First try to seek using the built-in seek
  if (seek($self->{'fh'},$position,$whence))
  {
    ${*{$self->{'fh'}}}{'filehandle_unget_buffer'} = '';
    $status = 1;
  }
  else
  {
    my $absolute_position;

    $absolute_position = $position if $whence == 0;
    $absolute_position = $self->tell + $position if $whence == 1;
    $absolute_position = -s $self->{'fh'} + $position if $whence == 2;

    if ($absolute_position <= tell $self->{'fh'})
    {
      if ($absolute_position >= $self->tell)
      {
        substr(${*{$self->{'fh'}}}{'filehandle_unget_buffer'}, 0,
          $absolute_position - $self->tell) = '';
        $status = 1;
      }
      else
      {
        # Can't seek backward!
        $status = 0;
      }
    }
    else
    {
      # Shouldn't the built-in seek handle this?!
      warn "Seeking forward is not yet implemented in " . __PACKAGE__ . "\n";
      $status = 0;
    }
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};

  return $status;
}

#-------------------------------------------------------------------------------

sub tell
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $file_position = tell $self->{'fh'};

  return -1 if $file_position == -1;

  $file_position -= length(${*{$self->{'fh'}}}{'filehandle_unget_buffer'});

  tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};

  return $file_position;
}

#-------------------------------------------------------------------------------

sub eof
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $eof;

  if (${*{$self->{'fh'}}}{'filehandle_unget_buffer'} ne '')
  {
    $eof = 0;
  }
  else
  {
    $eof = $self->{'fh'}->eof();
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self->{'fh'};

  ${*{$self->{'fh'}}}{'eof_called'} = 1;

  return $eof;
}

1;

__END__

# -----------------------------------------------------------------------------

=head1 NAME

FileHandle::Unget - FileHandle which supports multi-byte unget


=head1 SYNOPSIS

    use FileHandle::Unget;
    
    # open file handle
    my $fh = FileHandle::Unget->new("file")
      or die "cannot open filehandle: $!";
    
    my $buffer;
    read($fh,$buffer,100);
    print $buffer;

    print <$fh>;
    
    $fh->close;


=head1 DESCRIPTION

FileHandle::Unget operates exactly the same as FileHandle, except that it
provides a version of ungetc that allows you to unget more than one character.
It also provides ungets to unget a string.

This module is useful if the filehandle refers to a stream for which you can't
just C<seek()> backwards. Some operating systems support multi-byte
C<ungetc()>, but this is not guaranteed. Use this module if you want a
portable solution. In addition, on some operating systems, eof() will not be
reset if you ungetc after having read to the end of the file.

NOTE: Using C<sysread()> with C<ungetc()> and other buffering functions is
still a bad idea.

=head1 METHODS

The methods for this package are the same as those of the FileHandle package,
with the following exceptions.

=over 4

=item new ( ARGS )

The constructor is exactly the same as that of FileHandle, except that you can
also call it with an existing IO::Handle object to "attach" unget semantics to
a pre-existing handle.


=item $fh->ungetc ( ORD )

Pushes a character with the given ordinal value back onto the given handle's
input stream. This method can be called more than once in a row to put
multiple values back on the stream. Memory usage is equal to the total number
of bytes pushed back.

=item $fh->ungets ( BUF )

Pushes a buffer back onto the given handle's input stream. This method can be
called more than once in a row to put multiple buffers of characters back on
the stream.  Memory usage is equal to the total number of bytes pushed back.

The buffer is not processed in any way--managing end-of-line characters and
whatnot is your responsibility.

=item $fh->buffer ( [BUF] )

Get or set the pushback buffer directly.

=item tell ( $fh )

C<tell> returns the actual file position minus the length of the unget buffer.
If you read three bytes, then unget three bytes, C<tell> will report a file
position of 0. 

Everything works as expected if you are careful to unget the exact same bytes
which you read.  However, things get tricky if you unget different bytes.
First, the next bytes you read won't be the actual bytes on the filehandle at
the position indicated by C<tell>.  Second, C<tell> will return a negative
number if you unget more bytes than you read. (This can be problematic since
this function returns -1 on error.)

=item seek ( $fh, [POSITION], [WHENCE] )

C<seek> defaults to the standard seek if possible, clearing the unget buffer
if it succeeds. If the standard seek fails, then C<seek> will attempt to seek
within the unget buffer. Note that in this case, you will not be able to seek
backward--FileHandle::Unget will only save a buffer for the next bytes to be
read.

For example, let's say you read 10 bytes from a pipe, then unget the 10 bytes.
If you seek 5 bytes forward, you won't be able to read the first five bytes.
(Otherwise this module would have to keep around a lot of probably useless
data!)

=back


=head1 COMPATIBILITY

To test that this module is indeed a drop-in replacement for FileHandle, the
following modules were modified to use FileHandle::Unget, and tested using
"make test". They have all passed.

CPAN-1.76


=head1 BUGS

There is a bug in Perl on Windows that is exposed if you open a stream, then
check for eof, then call binmode. For example:

  # First line
  # Second line

  open FH, "$^X -e \"open F, '$0';binmode STDOUT;print <F>\" |";

  eof(FH);
  binmode(FH);

  print "First line:", scalar <FH>, "\n";
  print "Second line:", scalar <FH>, "\n";

  close FH;

One solution is to make sure that you only call binmode immediately after
opening the filehandle. I'm not aware of any workaround for this bug that
FileHandle::Unget could implement. However, the module does detect this
situation and prints a warning.

Contact david@coppit.org for bug reports and suggestions.


=head1 AUTHOR

David Coppit <david@coppit.org>.


=head1 LICENSE

This software is distributed under the terms of the GPL. See the file
"LICENSE" for more information.


=head1 SEE ALSO

Mail::Mbox::MessageParser for an example of how to use this package.

=cut
