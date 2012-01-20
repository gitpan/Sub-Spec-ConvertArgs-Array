package Sub::Spec::ConvertArgs::Array;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use Data::Sah;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(convert_args_to_array);

our $VERSION = '0.03'; # VERSION

our %SPEC;

sub _parse_schema {
    Data::Sah::normalize_schema(@_);
}

$SPEC{convert_args_to_array} = {
    summary => 'Convert hash arguments to array',
    description_fmt => 'org',
    description => <<'_',

Using information in sub spec's ~args~ clause (particularly the ~arg_pos~ and
~arg_greedy~ arg type clauses), convert hash arguments to array.

Example:

: my $spec = {
:     summary => 'Multiply 2 numbers (a & b)',
:     args_as => 'array',
      args => {
:         a => ['num*' => {arg_pos=>0}],
:         b => ['num*' => {arg_pos=>1}],
:     }
: }

then ~convert_args_to_array(args=>{a=>2, b=>3}, spec=>$spec)~ will produce:

: [200, "OK", [2, 3]]

_
    args => {
        args => ['hash*' => {
        }],
        spec => ['hash*' => {
        }],
    },
};
sub convert_args_to_array {
    my %input_args = @_;
    my $args       = $input_args{args} or return [400, "Please specify args"];
    my $sub_spec   = $input_args{spec};
    my $args_spec  = $input_args{_args_spec}; # use cache of normalized schema
    if (!$args_spec) {
        $args_spec = $sub_spec->{args} // {};
        $args_spec = { map { $_ => _parse_schema($args_spec->{$_}) }
                           keys %$args_spec };
    }
    return [400, "Please specify spec"] if !$sub_spec && !$args_spec;
    #$log->tracef("-> convert_args_to_array(), args=%s", $args);

    my @array;

    while (my ($k, $v) = each %$args) {
        my $as = $args_spec->{$k};
        return [412, "Argument $k: No spec"] unless $as;
        my $ac = $as->{clause_sets}[0];
        my $pos = $ac->{arg_pos};
        return [412, "Argument $k: Spec doesn't specify arg_pos"]
            unless defined $pos;
        if ($ac->{arg_greedy}) {
            $v = [$v] if ref($v) ne 'ARRAY';
            # splice can't work if $pos is beyond array's length
            for (@array .. $pos-1) {
                $array[$_] = undef;
            }
            splice @array, $pos, 0, @$v;
        } else {
            $array[$pos] = $v;
        }
    }
    [200, "OK", \@array];
}

1;
#ABSTRACT: Convert hash arguments to array


=pod

=head1 NAME

Sub::Spec::ConvertArgs::Array - Convert hash arguments to array

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Sub::Spec::ConvertArgs::Array;

 my $res = convert_args_to_array(args=>\%args, spec=>$spec, ...);

=head1 DESCRIPTION

B<NOTICE>: This module and the L<Sub::Spec> standard is deprecated as of Jan
2012. L<Rinci> is the new specification to replace Sub::Spec, it is about 95%
compatible with Sub::Spec, but corrects a few issues and is more generic.
C<Perinci::*> is the Perl implementation for Rinci and many of its modules can
handle existing Sub::Spec sub specs.

This module provides convert_args_to_array() (and
gencode_convert_args_to_array(), upcoming). This module is used by, among
others, L<Sub::Spec::Wrapper>.

This module's functions has L<Sub::Spec> specs.

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 convert_args_to_array(%args) -> [STATUS_CODE, ERR_MSG, RESULT]


Convert hash arguments to array.

Using information in sub spec's ~args~ clause (particularly the ~arg_pos~ and
~arg_greedy~ arg type clauses), convert hash arguments to array.

Example:

: my $spec = {
:     summary => 'Multiply 2 numbers (a & b)',
:     args_as => 'array',
      args => {
:         a => ['num*' => {arg_pos=>0}],
:         b => ['num*' => {arg_pos=>1}],
:     }
: }

then ~convert_args_to_array(args=>{a=>2, b=>3}, spec=>$spec)~ will produce:

: [200, "OK", [2, 3]]

Returns a 3-element arrayref. STATUS_CODE is 200 on success, or an error code
between 3xx-5xx (just like in HTTP). ERR_MSG is a string containing error
message, RESULT is the actual result.

Arguments (C<*> denotes required arguments):

=over 4

=item * B<args>* => I<hash>

=item * B<spec>* => I<hash>

=back

=head1 SEE ALSO

L<Sub::Spec>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

