use strict;
use warnings;
package Dist::Zilla::Plugin::OptionalFeature;
# ABSTRACT: Specify prerequisites for optional features in your distribution
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with
    'Dist::Zilla::Role::MetaProvider',
    'Dist::Zilla::Role::PrereqSource';

use MooseX::Types::Moose qw(HashRef Bool);
use MooseX::Types::Common::String 'NonEmptySimpleStr';
use Carp 'confess';
use Module::Runtime 'use_module';
use namespace::autoclean;

has name => (
    is => 'ro', isa => NonEmptySimpleStr,
    required => 1,
);
has description => (
    is => 'ro', isa => NonEmptySimpleStr,
    lazy => 1,
    default => sub { shift->name }
);

has always_recommend => (
    is => 'ro', isa => Bool,
    default => 0,
);

has require_develop => (
    is => 'ro', isa => Bool,
    default => 1,
);

has prompt => (
    is => 'ro', isa => Bool,
    lazy => 1,
    default => sub { shift->_prereq_type eq 'requires' ? 1 : 0 },
);

has default => (
    is => 'ro', isa => Bool,
    predicate => '_has_default',
    # NO DEFAULT
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
    traits => ['Hash'],
    handles => { _prereq_modules => 'keys', _prereq_version => 'get' },
);

sub mvp_aliases { +{ -relationship => '-type' } }

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    my @private = grep { /^_/ } keys %$args;
    confess "Invalid options: @private" if @private;

    # pull these out so they don't become part of our prereq list
    my ($zilla, $plugin_name) = delete @{$args}{qw(zilla plugin_name)};

    my ($feature_name, $description, $always_recommend, $require_develop, $prompt, $default, $phase) =
        delete @{$args}{qw(-name -description -always_recommend -require_develop -prompt -default -phase)};
    my ($type) = grep { defined } delete @{$args}{qw(-type -relationship)};

    my @other_options = grep { /^-/ } keys %$args;
    delete @{$args}{@other_options};
    warn "[OptionalFeature] warning: unrecognized option(s): @other_options" if @other_options;

    # handle magic plugin names
    if ((not $feature_name or not $phase or not $type)
            # plugin comes from a bundle
        and $plugin_name !~ m! (?: \A | / ) OptionalFeature \z !x)
    {
        $feature_name ||= $plugin_name;

        if ($feature_name =~ / -
                (Build|Test|Runtime|Configure|Develop)
                (Requires|Recommends|Suggests|Conflicts)?
            \z/xp)
        {
            $feature_name = ${^PREMATCH};
            $phase ||= lc($1) if $1;
            $type = lc($2) if $2;
        }
    }

    confess 'optional features may not use the configure phase'
        if $phase and $phase eq 'configure';

    return {
        zilla => $zilla,
        plugin_name => $plugin_name,
        defined $feature_name ? ( name => $feature_name ) : (),
        defined $description ? ( description => $description ) : (),
        defined $always_recommend ? ( always_recommend => $always_recommend ) : (),
        defined $require_develop ? ( require_develop => $require_develop ) : (),
        defined $prompt ? ( prompt => $prompt ) : (),
        defined $default ? ( default => $default ) : (),
        defined $phase ? ( _prereq_phase => $phase ) : (),
        defined $type ? ( _prereq_type => $type ) : (),
        _prereqs => $args,
    };
};

sub BUILD
{
    my $self = shift;

    if ($self->prompt)
    {
        my $phase = $self->_prereq_phase;
        my $mm_key = $phase eq 'runtime' ? 'PREREQ_PM'
            : $phase eq 'test' ? 'TEST_REQUIRES'
            : $phase eq 'build' ? 'BUILD_REQUIRES'
            : $self->log_fatal("illegal phase $phase");
        $self->log_fatal('prompts are only used for the \'requires\' type')
            if $self->_prereq_type ne 'requires';

        my $plugin = use_module('Dist::Zilla::Plugin::DynamicPrereqs', '0.007')->new(
            zilla => $self->zilla,
            plugin_name => 'via OptionalFeature (' . ($self->plugin_name || $self->name) . ')',
            delimiter => '|',
            raw => [
                "if (prompt('install " . $self->name . ' (' . $self->description . ')? '
                    . ($self->default ? "[Y/n]', 'Y'" : "[y/N]', 'N'" )
                    . ') =~ /^y/i) {',
                (map {
                    qq!|  \$WriteMakefileArgs{$mm_key}{'$_'} = \$FallbackPrereqs{'$_'} = '${ \$self->_prereq_version($_) }';!
                } sort $self->_prereq_modules),
                '}',
            ],
        );
        push @{ $self->zilla->plugins }, $plugin;
    }
}

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        (map { $_ => $self->$_ }
            qw(name description always_recommend require_develop prompt)),
        # FIXME: YAML::Tiny does not handle leading - properly yet
        # (map { defined $self->$_ ? ( '-' . $_ => $self->$_ ) : () }
        (map { defined $self->$_ ? ( $_ => $self->$_ ) : () } qw(default)),
        phase => $self->_prereq_phase,
        type => $self->_prereq_type,
        prereqs => $self->_prereqs,
    };

    return $config;
};

sub register_prereqs
{
    my $self = shift;

    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        %{ $self->_prereqs },
    ) if $self->require_develop;

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

    # this might be relaxed in the future -- see
    # https://github.com/Perl-Toolchain-Gang/cpan-meta/issues/28
    # but this is the current v2.0 spec - regexp lifted from Test::CPAN::Meta::JSON::Version
    $self->log_fatal('invalid syntax for optional feature name \'' .  $self->name . '\'')
        if $self->name !~ /^([a-z][_a-z]+)$/i;

    return {
        # dynamic_config is NOT set, on purpose -- normally the CPAN client
        # does the user interrogation and merging of prereqs, not Makefile.PL/Build.PL
        optional_features => {
            $self->name => {
                description => $self->description,
                # we don't know which way this will/should default in the spec if omitted,
                # so we only include it if the user explicitly sets it
                $self->_has_default ? ( x_default => $self->default ) : (),
                prereqs => { $self->_prereq_phase => { $self->_prereq_type => $self->_prereqs } },
            },
        },
    };
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [OptionalFeature / XS_Support]
    -description = XS implementation (faster, requires a compiler)
    -prompt = 1
    Foo::Bar::XS = 1.002

=head1 DESCRIPTION

This plugin provides a mechanism for specifying prerequisites for optional
features in metadata, which should cause CPAN clients to interactively prompt
you regarding these features at install time (assuming interactivity is turned
on: e.g. C<< cpanm --interactive Foo::Bar >>).

The feature I<name> and I<description> are required. The name can be extracted
from the plugin name.

You can specify requirements for different phases and relationships with:

    [OptionalFeature / Feature_name]
    -description = description
    -phase = test
    -relationship = requires
    Fitz::Fotz    = 1.23
    Text::SoundEx = 3

If not provided, C<-phase> defaults to C<runtime>, and C<-relationship> to
C<requires>.

To specify feature requirements for multiple phases, provide them as separate
plugin configurations (keeping the feature name and description constant):

    [OptionalFeature / Feature_name]
    -description = description
    -phase = runtime
    Foo::Bar = 0

    [OptionalFeature / Feature_name]
    -description = description
    -phase = test
    Foo::Baz = 0

B<NOTE>: this doesn't seem to work properly with L<CPAN::Meta::Merge> (used in L<Dist::Zilla> since version 5.022).

It is possible that future versions of this plugin may allow a more compact
way of providing sophisticated prerequisite specifications.

If the plugin name is the CamelCase concatenation of a phase and relationship
(or just a relationship), it will set those parameters implicitly.  If you use
a custom name, but it does not specify the relationship, and you didn't
specify either or both of C<-phase> or C<-relationship>, these values default
to C<runtime> and C<requires> respectively.

The example below is equivalent to the synopsis example above, except for the
name of the resulting plugin:

    [OptionalFeature]
    -name = XS_Support
    -description = XS implementation (faster, requires a compiler)
    -phase = runtime
    -relationship = requires
    Foo::Bar::XS = 1.002

B<NOTE>: It is advised that you only specify I<one> prerequisite for a given
feature -- and if necessary, create a separate distribution to encapsulate the
code needed to make that feature work (along with all of its dependencies).
This allows external projects to declare a prerequisite not just on your
distribution, but also a particular feature of that distribution.

=for Pod::Coverage mvp_aliases BUILD metadata register_prereqs

=head1 PROMPTING

At the moment it doesn't appear that any CPAN clients properly support
C<optional_feature> metadata and interactively prompt the user with the
information therein.  Therefore, prompting is added directly to F<Makefile.PL>
when the C<-relationship> is C<requires>. (It doesn't make much sense to
prompt for C<recommends> or C<suggests> features, so prompting is omitted
here.)  You can also enable or disable this explicitly with the C<-prompt> option.
The prompt feature can only be used with F<Makefile.PL>. If a F<Build.PL> is
detected in the build and C<=prompt> is set, the build will fail.

As with any other interactive features, the installing user can bypass the
prompts with C<PERL_MM_USE_DEFAULT=1>.  You may want to set this when running
C<dzil build>.

=head1 CONFIGURATION OPTIONS

This is mostly a restating of the information above.

=over 4

=item * C<-name>

The name of the optional feature, to be presented to the user. Can also be
extracted from the plugin name.

=item * C<-description>

The description of the optional feature, to be presented to the user.
Defaults to the feature name, if not provided.

=item * C<-always_recommend>

If set with a true value, the prerequisites are added to the distribution's
metadata as recommended prerequisites (e.g. L<cpanminus> will install
recommendations with C<--with-recommends>, even when running
non-interactively). Defaults to false, but I recommend you turn this on.

=item * C<-require_develop>

If set with a true value, the prerequisites are added to the distribution's
metadata as develop requires prerequisites (e.g. L<cpanminus> will install
recommendations with C<--with-develop>, even when running
non-interactively).  Defaults to true.

=item * C<-prompt>

If set with a true value, F<Makefile.PL> is modified to include interactive
prompts.

=item * C<-default>

If set with a true value, non-interactive installs will automatically
fold the feature's prerequisites into the regular prerequisites.

=for stopwords miyagawa

Note that at the time of this feature's creation (September 2013), there is no
compliant CPAN client yet, as it invents a new C<x_default> field in metadata
under C<optional_feature> (thanks, miyagawa!)

=item * C<-phase>

The phase of the prequisite(s). Should be one of: build, test, runtime,
or develop.

=item * C<-relationship> (or C<-type>)

The relationship of the prequisite(s). Should be one of: requires, recommends,
suggests, or conflicts.

=back

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-OptionalFeature>
(or L<bug-Dist-Zilla-Plugin-OptionalFeature@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-OptionalFeature@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=for :list
* L<CPAN::Meta::Spec/optional_features>
* L<Module::Install::API/features, feature (Module::Install::Metadata)>

=cut
