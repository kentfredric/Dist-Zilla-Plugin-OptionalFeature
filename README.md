# NAME

Dist::Zilla::Plugin::OptionalFeature - Specify prerequisites for optional features in your dist

# VERSION

version 0.008

# SYNOPSIS

In your `dist.ini`:

    [OptionalFeature / XS Support]
    -description = XS implementation (faster, requires a compiler)
    Foo::Bar::XS = 1.002

# DESCRIPTION

This plugin provides a mechanism for specifying prerequisites for optional
features in metadata, which should cause CPAN clients to interactively prompt
you regarding these features at install time (assuming interactivity is turned
on: e.g. `cpanm --interactive Foo::Bar`).

The feature _name_ and _description_ are required. The name can be extracted
from the plugin name.

You can specify requirements for different phases and relationships with:

    [OptionalFeature / Feature name]
    -description = description
    -phase = test
    -relationship = requires
    Fitz::Fotz    = 1.23
    Text::SoundEx = 3

If not provided, `-phase` defaults to `runtime`, and `-relationship` to
`requires`.

To specify feature requirements for multiple phases, provide them as separate
plugin configurations (keeping the feature name and description constant):

    [OptionalFeature / Feature name]
    -description = description
    -phase = runtime
    Foo::Bar = 0

    [OptionalFeature / Feature name]
    -description = description
    -phase = test
    Foo::Baz = 0

It is possible that future versions of this plugin may allow a more compact
way of providing sophisticated prerequisite specifications.

If the plugin name is the CamelCase concatenation of a phase and relationship
(or just a relationship), it will set those parameters implicitly.  If you use
a custom name, but it does not specify the relationship, and you didn't
specify either or both of `-phase` or `-relationship`, these values default
to `runtime` and `requires` respectively.

The example below is equivalent to the synopsis example above, except for the
name of the resulting plugin:

    [OptionalFeature]
    -name = XS Support
    -description = XS implementation (faster, requires a compiler)
    -phase = runtime
    -relationship = requires
    Foo::Bar::XS = 1.002

# CONFIG OPTIONS

This is mostly a restating of the information above.

- `-name`

    The name of the optional feature, to be presented to the user. Can also be
    extracted from the plugin name.

- `-description`

    The description of the optional feature, to be presented to the user.
    Defaults to the feature name, if not provided.

- `-always_recommend`

    If set with a true value, the prerequisites are added to the distribution's
    metadata as recommended prerequisites (e.g. [cpanminus](https://metacpan.org/pod/cpanminus) will install
    recommendations with `--with-recommends`, even when running
    non-interactively). Defaults to 0, but I recommend you turn this on.

- `-default`

    If set with a true value, compliant CPAN clients will behave as if the user
    opted to install the feature's prerequisites when running non-interactively
    (when there is no opportunity to prompt the user).

    Note that at the time of this feature's creation (September 2013), there is no
    compliant CPAN client yet, as it invents a new `x_default` field in metadata
    under `optional_feature` (thanks, miyagawa!)

- `-phase`

    The phase of the prequisite(s). Should be one of: build, test, runtime,
    or develop.

- `-relationship` (or `-type`)

    The relationship of the prequisite(s). Should be one of: requires, recommends,
    suggests, or conflicts.

# SUPPORT

Bugs may be submitted through [the RT bug tracker](https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-OptionalFeature)
(or [bug-Dist-Zilla-Plugin-OptionalFeature@rt.cpan.org](mailto:bug-Dist-Zilla-Plugin-OptionalFeature@rt.cpan.org)).
I am also usually active on irc, as 'ether' at `irc.perl.org`.

# SEE ALSO

- ["optional_features" in CPAN::Meta::Spec](https://metacpan.org/pod/CPAN::Meta::Spec#optional_features)
- ["features, feature (Module::Install::Metadata)" in Module::Install::API](https://metacpan.org/pod/Module::Install::API#features-feature-Module::Install::Metadata)

# AUTHOR

Karen Etheridge <ether@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
