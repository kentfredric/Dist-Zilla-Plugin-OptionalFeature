use strict;
use warnings;
package Dist::Zilla::Plugin::OptionalFeature;
# ABSTRACT: ...

use Moose;
with
    'Dist::Zilla::Role::MetaProvider',
    'Dist::Zilla::Role::PrereqSource';

use MooseX::Types::Moose qw(HashRef Bool);
use MooseX::Types::Common::String 'NonEmptySimpleStr';
use namespace::autoclean;

has [ qw(name description) ] => (
    is => 'ro', isa => NonEmptySimpleStr,
    required => 1,
);

has always_recommend => (
    is => 'ro', isa => Bool,
    default => 0,
    predicate => '_has_always_recommend',
);

has _prereq_phase => (
    is => 'ro', isa => NonEmptySimpleStr,
    lazy => 1,
    default  => 'runtime',
);

has _prereq_type => (
    is => 'ro', isa => NonEmptySimpleStr,
    lazy => 1,
    default => 'requires',
);

has _prereqs => (
    is => 'ro', isa => HashRef[NonEmptySimpleStr],
    lazy => 1,
    default => sub { {} },
);

sub mvp_aliases { return { -relationship => '-type' } }

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    my ($zilla, $plugin_name, $feature_name, $description, $always_recommend) =
        delete @{$args}{qw(zilla plugin_name name description always_recommend)};

    my @private = grep { /^_/ } keys %$args;
    confess "Invalid options: @private" if @private;

    my %other;
    for my $dkey (grep { /^-/ } keys %$args)
    {
        (my $key = $dkey) =~ s/^-//;
        confess "invalid option: $dkey" if $dkey ne '-type' and $dkey ne '-phase';
        $other{$key} = delete $args->{$dkey};
    }
    my $phase = $other{phase};
    my $type = $other{type};

    # handle magic plugin names
    if ((not $feature_name or not $phase or not $type)
            # plugin comes from a bundle
        and $plugin_name !~ m! (?: \A | / ) OptionalFeature \z !x)
    {
        $feature_name ||= $plugin_name;

        if ($feature_name =~ / -
                (Build|Test|Runtime|Configure|Develop)
                (Requires|Recommends|Suggests|Conflicts)?
            \z/x)
        {
            $feature_name = $`;
            $phase ||= lc($1) if $1;
            $type = lc($2) if $2;
        }
    }

    return {
        zilla => $zilla,
        plugin_name => $plugin_name,
        defined $feature_name ? ( name => $feature_name ) : (),
        defined $description ? ( description => $description ) : (),
        always_recommend => $always_recommend,
        $phase ? ( _prereq_phase => $phase ) : (),
        $type ? ( _prereq_type => $type ) : (),
        _prereqs => $args,
    };
};

sub register_prereqs
{
    my $self = shift;

    return if not $self->always_recommend;

    $self->zilla->register_prereqs(
        {
            type  => 'recommends',
            phase => $self->_prereq_phase,
        },
        %{ $self->_prereqs },
    );
}

sub metadata
{
    my $self = shift;

    return {
        optional_features => {
            $self->name => {
                description => $self->description,
                prereqs => { $self->_prereq_phase => { $self->_prereq_type => $self->_prereqs } },
            },
        },
    };
}

1;
__END__

=pod

=head1 SYNOPSIS

    use Dist::Zilla::Plugin::OptionalFeature;

    ...

=head1 DESCRIPTION

...

=head1 FUNCTIONS/METHODS

=over 4

=item * C<foo>

...

=back

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-OptionalFeature>
(or L<bug-Dist-Zilla-Plugin-OptionalFeature@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-OptionalFeature@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

=begin :list

* L<foo>

=end :list

=cut
