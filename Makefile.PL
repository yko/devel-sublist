use inc::Module::Install;

name 'devel-sublist';
all_from 'lib/Devel/Sublist.pm';
author q{Yaroslav Korshak <yko@cpan.org>};
license 'perl';

build_requires 'Test::More';

requires 'B';
requires 'Carp';
requires 'File::Basename';
requires 'Getopt::Long';
requires 'List::Util';
requires 'Pod::Usage';

resources license => "http://dev.perl.org/licenses";

install_script('bin/sublist');

auto_install;

WriteAll;
