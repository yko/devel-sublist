#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan skip_all => "POD needs to be written for this test.";
all_pod_coverage_ok();
