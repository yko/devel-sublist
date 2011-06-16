use inc::Module::Install;

name 'devel-sublist';
all_from 'lib/Devel/Sublist.pm';
author q{Yaroslav Korshak <yko@cpan.org>};
license 'perl';

build_requires 'Test::More';

requires 'Carp';
requires 'List::Util';
requires 'B';

resources license => "http://dev.perl.org/licenses";

auto_install;

WriteAll;
