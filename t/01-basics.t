#!perl

use 5.010;
use strict;
use warnings;
use Log::Any '$log';
use Test::More 0.96;

use Sub::Spec::ConvertArgs::Array qw(convert_args_to_array);

my $spec;

$spec = {
    args => {
        arg1 => ['str*' => {}],
    },
};
test_convertargs(
    name=>'empty -> ok',
    spec=>$spec, args=>{},
    status=>200, array=>[],
);
test_convertargs(
    name=>'no spec -> error',
    spec=>$spec, args=>{arg2=>1},
    status=>412,
);

$spec = {
    args => {
        arg1 => ['str*' => {arg_pos=>0}],
        arg2 => ['str*' => {arg_pos=>1}],
    },
};
test_convertargs(
    name=>'arg1 only',
    spec=>$spec, args=>{arg1=>1},
    status=>200, array=>[1],
);
test_convertargs(
    name=>'arg2 only',
    spec=>$spec, args=>{arg2=>2},
    status=>200, array=>[undef, 2],
);
test_convertargs(
    name=>'arg1 & arg2 (1)',
    spec=>$spec, args=>{arg1=>1, arg2=>2},
    status=>200, array=>[1,2],
);
test_convertargs(
    name=>'arg1 & arg2 (2)',
    spec=>$spec, args=>{arg1=>2, arg2=>1},
    status=>200, array=>[2, 1],
);

$spec = {
    args => {
        arg1 => ['array*' => {of=>'str*', arg_pos=>0, arg_greedy=>1}],
    },
};
test_convertargs(
    name=>'arg_greedy (1a)',
    spec=>$spec, args=>{arg1=>[1, 2, 3]},
    status=>200, array=>[1, 2, 3],
);
test_convertargs(
    name=>'arg_greedy (1b)',
    spec=>$spec, args=>{arg1=>2},
    status=>200, array=>[2],
);

$spec = {
    args => {
        arg1 => ['str*' => {arg_pos=>0}],
        arg2 => ['array*' => {of=>'str*', arg_pos=>1, arg_greedy=>1}],
    },
};
test_convertargs(
    name=>'arg_greedy (2)',
    spec=>$spec, args=>{arg1=>1, arg2=>[2, 3, 4]},
    status=>200, array=>[1, 2, 3, 4],
);

DONE_TESTING:
done_testing();

sub test_convertargs {
    my (%args) = @_;

    subtest $args{name} => sub {
        my %input_args = (args=>$args{args}, spec=>$args{spec});
        my $res = convert_args_to_array(%input_args);

        is($res->[0], $args{status}, "status=$args{status}")
            or diag explain $res;

        if ($args{array}) {
            is_deeply($res->[2], $args{array}, "result")
                or diag explain $res->[2];
        }
        #if ($args{post_test}) {
        #    $args{post_test}->();
        #}
    };
}

