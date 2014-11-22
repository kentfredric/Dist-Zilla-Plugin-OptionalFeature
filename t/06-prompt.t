use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;

use lib 't/lib';
use SpecCompliant;

# need a simple feature with two runtime prereqs, defaulting to y
# observe that Makefile.PL is munged with correct content

# now use a feature with one test prereq, defaulting to n

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ MakeMaker => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description',
                            -phase => 'runtime',
                            -relationship => 'requires',
                            -prompt => 1,
                            -default => 1,
                            'Foo' => '1.0', 'Bar' => '2.0',
                        },
                    ],
                ),
            },
        },
    );

    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 1,
            optional_features => {
                FeatureName => {
                    x_default => 1,
                    description => 'feature description',
                    prereqs => {
                        runtime => { requires => {
                            'Foo' => '1.0',
                            'Bar' => '2.0',
                        } },
                    },
                },
            },
            prereqs => {
                configure => { requires => { 'ExtUtils::MakeMaker' => ignore } },
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => {
                    'Foo' => '1.0',
                    'Bar' => '2.0',
                } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class   => 'Dist::Zilla::Plugin::OptionalFeature',
                        name    => 'FeatureName',
                        version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                        config => {
                            'Dist::Zilla::Plugin::OptionalFeature' => {
                                name => 'FeatureName',
                                description => 'feature description',
                                always_recommend => 0,
                                require_develop => 1,
                                prompt => 1,
                                default => 1,
                                phase => 'runtime',
                                type => 'requires',
                                prereqs => {
                                    'Foo' => '1.0',
                                    'Bar' => '2.0',
                                },
                            },
                        },
                    },
                    superhashof({
                        class   => 'Dist::Zilla::Plugin::DynamicPrereqs',
                        name    => 'via OptionalFeature (FeatureName)',
                        version => Dist::Zilla::Plugin::DynamicPrereqs->VERSION,
                    }),
                ),
            }),
        }),
        'metadata correct when minimal config provided',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    TODO: {
        local $TODO = 'x_ keys should be valid everywhere!';
        is_valid_spec($tzil);
    }

    my $content = $tzil->slurp_file('build/Makefile.PL');

    like(
        $content,
        qr!\Qif (prompt('install FeatureName (feature description)? [Y/n]', 'Y') =~ /^y/i) {\E
\s*\$\QWriteMakefileArgs{PREREQ_PM}{'Bar'} = \E\$\QFallbackPrereqs{'Bar'} = '2.0';\E
\s*\$\QWriteMakefileArgs{PREREQ_PM}{'Foo'} = \E\$\QFallbackPrereqs{'Foo'} = '1.0';\E
\}!,
        'Makefile.PL contains the correct code for runtime prereqs with -default = 1',
    );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ MakeMaker => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description',
                            -phase => 'test',
                            -relationship => 'requires',
                            -prompt => 1,
                            -default => 0,
                            'Foo' => '1.0', 'Bar' => '2.0',
                        },
                    ],
                ),
            },
        },
    );

    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 1,
            optional_features => {
                FeatureName => {
                    x_default => 0,
                    description => 'feature description',
                    prereqs => {
                        test => { requires => {
                            'Foo' => '1.0',
                            'Bar' => '2.0',
                        } },
                    },
                },
            },
            prereqs => {
                configure => { requires => { 'ExtUtils::MakeMaker' => ignore } },
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => {
                    'Foo' => '1.0',
                    'Bar' => '2.0',
                } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class   => 'Dist::Zilla::Plugin::OptionalFeature',
                        name    => 'FeatureName',
                        version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                        config => {
                            'Dist::Zilla::Plugin::OptionalFeature' => {
                                name => 'FeatureName',
                                description => 'feature description',
                                always_recommend => 0,
                                require_develop => 1,
                                prompt => 1,
                                default => 0,
                                phase => 'test',
                                type => 'requires',
                                prereqs => {
                                    'Foo' => '1.0',
                                    'Bar' => '2.0',
                                },
                            },
                        },
                    },
                    superhashof({
                        class   => 'Dist::Zilla::Plugin::DynamicPrereqs',
                        name    => 'via OptionalFeature (FeatureName)',
                        version => Dist::Zilla::Plugin::DynamicPrereqs->VERSION,
                    }),
                ),
            }),
        }),
        'metadata correct when minimal config provided',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    TODO: {
        local $TODO = 'x_ keys should be valid everywhere!';
        is_valid_spec($tzil);
    }

    my $content = $tzil->slurp_file('build/Makefile.PL');

    like(
        $content,
        qr!\Qif (prompt('install FeatureName (feature description)? [y/N]', 'N') =~ /^y/i) {\E
\s*\$\QWriteMakefileArgs{TEST_REQUIRES}{'Bar'} = \E\$\QFallbackPrereqs{'Bar'} = '2.0';\E
\s*\$\QWriteMakefileArgs{TEST_REQUIRES}{'Foo'} = \E\$\QFallbackPrereqs{'Foo'} = '1.0';\E
!,
        'Makefile.PL contains the correct code for runtime prereqs with -default = 1',
    );
}

{
    like( exception {
        Builder->from_config(
            { dist_root => 't/does_not_exist' },
            {
                add_files => {
                    path(qw(source dist.ini)) => simple_ini(
                        [ GatherDir => ],
                        [ MetaConfig => ],
                        [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                        [ OptionalFeature => FeatureName => {
                                -description => 'feature description',
                                -phase => 'runtime',
                                -relationship => 'recommends',
                                -prompt => 1,
                                'Foo' => '1.0', 'Bar' => '2.0',
                            },
                        ],
                    ),
                },
            },
        ) },
        qr/prompts are only used for the 'requires' type/,
        'prompting cannot be combined with the recommends or suggests prereq type',
    );
}

done_testing;
