#!/usr/bin/env perl

require Test::More;
eval 'require Test::Perl::Critic';

if ($@) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

Test::More::plan(skip_all => "It's too early for perlcritic");

Test::Perl::Critic::all_critic_ok();
