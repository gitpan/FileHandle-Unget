#!/usr/bin/perl

use strict;
use inc::Module::Install;

Check_Custom_Installation();

print "\n", '-'x78, "\n\n";

name            ('FileHandle-Unget');
author          ('David Coppit <david@coppit.org>');
abstract_from   ('lib/FileHandle/Unget.pm');
version_from    ('lib/FileHandle/Unget.pm');
license         ('gpl');

requires        (
                  'Scalar::Util' => 0,
                );

clean_files     ('t/temp');

include         ('ExtUtils/AutoInstall.pm');

auto_install    ( );
WriteAll();

print "\n", '-'x78, "\n\n";

exit;
