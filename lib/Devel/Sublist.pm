package Devel::Sublist;

use warnings;
use strict;

use List::Util 'min', 'max';

require Carp;
require B;

our $VERSION = 0.01;

sub list {
    my $package = pop;

    eval "require $package";
    die $@ if $@;

    my %list;
    my @parents = ({package => $package, level => 1});
    my %checked;
    my $level = 1;

    while (my $p = shift @parents) {
        $checked{$p->{package}} = $p->{level};

        # List all subs in package
        no strict 'refs';
        my @sublist =
          grep { *{$p->{package} . "::" . $_}{CODE} }
          keys %{$p->{package} . "::"};
        use strict;

        # Package => Sub pairs
        foreach my $sub (@sublist) {
            my $elsewhere = defined_elsewhere($p->{package}, $sub);
            my $obj = {package => $p->{package}, origin => $elsewhere};

            if (@{$list{$sub} || []}) {
                no strict 'refs';
                my $first =
                  *{$list{$sub}->[0]->{package} . '::' . $sub}{CODE};
                my $current = *{$obj->{package} . '::' . $sub}{CODE};
                use strict;
                if ($first == $current) {
                    unshift @{$list{$sub}}, $obj;
                    next;
                }
            }
            push @{$list{$sub}}, $obj;

        }

        # Walk through all parents
        no strict 'refs';
        push @parents, map {
            { package => $_, level => $p->{level} + 1 }
        } grep !exists($checked{$_}), @{$p->{package} . "::ISA"};
        use strict;
    }

    return map { [$_ => $list{$_}] } sort {

        # Package level
        $checked{$list{$a}->[0]->{package}} <=>
          $checked{$list{$b}->[0]->{package}}
          or

          # Package name
          $list{$a}->[0] cmp $list{$a}->[0] or

          # Is public method?
          ($b =~ /^[a-z]/) <=> ($a =~ /^[a-z]/) or

          # Alphabetical
          $a cmp $b
    } keys %list;
}

sub dump_methods {
    my $package = shift;
    my $verbose;

    if (@_) {
        $verbose = shift;
    }
    elsif (my $hints = (caller(0))[10]) {
        $verbose = $hints->{'listsubs.verbose'};
    }

    my @list = list($package);
    @list = $verbose ? format_verbose(@list) : format_simple(@list);

    return wantarray ? @list : join "\n", @list;
}

sub _prepare_subnames {
    for (@_) {
        $_->[0] =~ s/^\(\)$/overload &/;
        $_->[0] =~ s/^\(&{}$/overload {}/;
        $_->[0] =~ s/^\(""$/overload ""/;
    }
}

sub format_simple {
    &_prepare_subnames;
    map { $_->[0] } @_;
}

sub _packages_names {
    my $obj = shift;
    join ',',
      map { $_->{origin} ? "$_->{package}($_->{origin})" : $_->{package} }
      @$obj;
}

sub format_verbose {
    &_prepare_subnames;
    my $maxlength = min 30, max map { length $_->[0] } @_;

    map {
            $_->[0] . ' '
          . (' ' x ($maxlength - length $_->[0])) . "["
          . _packages_names($_->[1]) . "]"
    } @_;
}

sub defined_elsewhere {
    my $name = join '::', @_;

    no strict 'refs';
    my $coderef = *{"$name"}{CODE};
    use strict;

    die "Not a subroutine: $name" unless $coderef;

    my $cv = B::svref_2object($coderef);

    die "$name - " . ref($cv) unless $cv->isa('B::CV');
    die if $cv->GV->isa('B::SPECIAL');

    my $realname = $cv->GV->NAME;
    my $fullname = join '::', $cv->GV->STASH->NAME, $realname;

    if ($realname eq '__ANON__') {
        $fullname = 'installed from ' . $cv->GV->STASH->NAME;
    }
    return if $fullname eq $name;

    wantarray ? ($cv->GV->STASH->NAME, $cv->GV->NAME) : $fullname;
}


sub import {
    my $class = shift;
    return unless @_;

    my $package;

    $package = shift unless $_[0] eq 'verbose';

    if ($_[0] && $_[0] eq 'verbose') {
        $^H{'listsubs.verbose'} = 1;
    }
    else {
        delete $^H{'listsubs.verbose'};
    }

    if ($package) {
        my $dump = dump_methods($package, $^H{'listsubs.verbose'});
        print "Subroutines available in package '$package':\n$dump\n";
        exit;
    }

    no strict 'refs';
    *{caller() . '::dump_methods'} = \&dump_methods;
    use strict;
}

1;

__END__

=head1 NAME

Devel::Sublist - Naive Perl extension to show package methods


=head1 SYNOPSIS

Oneliners:

    perl -MDevel::Sublist=Scalar::Util
    perl -MDevel::Sublist=Scalar::Util,verbose

Perl code:

    package Foo;
    use Devel::Sublist 'verbose';

    print Devel::Sublist


=head1 DESCRIPTION

Devel::Sublist is an easy way to see what methods package has and why

=head1 METHODS

L<Devel::Sublist> implements following methods:

TODO

=head1 SEE ALSO

L<B> L<Sub-Identify>


=head1 BUGS AND LIMITATIONS

This package should be considered as quick
and very naive way to look inside of package.

Due to interface limitations you can not list 'verbose' package from oneliner.

Please report any bugs or feature requests to
L<https://github.com/yko/devel-sublist/issues>.


=head1 AUTHOR

Yaroslav Korshak  C<< <yko@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) 2011, Yaroslav Korshak  C<< <yko@cpan.org> >>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
