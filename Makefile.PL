#!/usr/bin/perl

use strict;
use inc::Module::Install;

name            ('FileHandle-Unget');
author          ('David Coppit <david@coppit.org>');
abstract_from   ('lib/FileHandle/Unget.pm');
version_from    ('lib/FileHandle/Unget.pm');
license         ('gpl');

build_requires  (
                  'Test::More' => 0,
                  'File::Spec::Functions' => 0,
                );

requires        (
                  'perl' => '5.004',
                  'Scalar::Util' => '1.14',
                );

clean_files     ('t/temp');

include         ('ExtUtils/AutoInstall.pm');

auto_include_deps ( );
auto_install    ( );
WriteAll();

print "\n", '-'x78, "\n\n";

exit;
