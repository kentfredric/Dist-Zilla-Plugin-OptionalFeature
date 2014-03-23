use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::Deep::JSON;
use Test::DZil;
use Path::Tiny;

use lib 't/lib';
use SpecCompliant;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            # use default description, phase, type
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'FeatureName',
                    prereqs => {
                        runtime => { requires => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => superbagof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'FeatureName',
                            always_recommend => 0,
                            require_develop => 1,
                            phase => 'runtime',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        })),
        'metadata correct when minimal config provided',
    );

    is_valid_spec($tzil);
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-BuildSuggests' => {
                            -description => 'desc',
                            -always_recommend => 1,
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {    # strip phase/type as it is extracted
                    description => 'desc',
                    prereqs => {
                        build => { suggests => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                build => { recommends => { A => 0 } },
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => superbagof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName-BuildSuggests',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'desc',
                            always_recommend => 1,
                            require_develop => 1,
                            phase => 'build',
                            type => 'suggests',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        })),
        'metadata correct when extracting feature name, phase and relationship from name',
    );

    is_valid_spec($tzil);
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-Test' => {
                            -description => 'desc',
                            -always_recommend => 1,
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'desc',
                    prereqs => {
                        test => { requires => { A => 0 } }
                    },
                },
            },
            prereqs => {
                test => {
                    requires => { Tester => 0 },
                    recommends => { A => 0 },
                },
                develop => { requires => { A => 0 } }
            },
            x_Dist_Zilla => superhashof({
                plugins => superbagof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName-Test',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'desc',
                            always_recommend => 1,
                            require_develop => 1,
                            phase => 'test',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        })),
        'metadata correct when extracting feature name and phase from name',
    );

    is_valid_spec($tzil);
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'desc',
                            -phase => 'test',
                            # use default relationship
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'desc',
                    prereqs => {
                        test => { requires => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => superbagof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'desc',
                            always_recommend => 0,
                            require_develop => 1,
                            phase => 'test',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        })),
        'metadata correct when given explicit phase',
    );

    is_valid_spec($tzil);
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'desc',
                            -phase => 'test',
                            -relationship => 'suggests',
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'desc',
                    prereqs => {
                        test => { suggests => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => superbagof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'desc',
                            always_recommend => 0,
                            require_develop => 1,
                            phase => 'test',
                            type => 'suggests',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        })),
        'metadata correct when given explicit phase and relationship',
    );

    is_valid_spec($tzil);
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-Test' => {
                            -description => 'desc',
                            A => 0,
                        }
                    ],
                    [ OptionalFeature => 'FeatureName-Runtime' => {
                            -description => 'desc',
                            B => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'desc',
                    prereqs => {
                        test => { requires => { A => 0 } },
                        runtime => { requires => { B => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => { A => 0, B => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => superbagof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName-Test',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'desc',
                            always_recommend => 0,
                            require_develop => 1,
                            phase => 'test',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                },
                {
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName-Runtime',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'desc',
                            always_recommend => 0,
                            require_develop => 1,
                            phase => 'runtime',
                            type => 'requires',
                            prereqs => { B => 0 },
                        },
                    },
                }),
            }),
        })),
        'metadata is merged from two plugins',
    );
}

{
    like( exception {
        Builder->from_config(
            { dist_root => 't/corpus/dist/DZT' },
            {
                add_files => {
                    path(qw(source dist.ini)) => simple_ini(
                        [ GatherDir => ],
                        [ MetaJSON  => ],
                        [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                        [ OptionalFeature => FeatureName => {
                                _prereq_phase => 'test',
                                -description => 'desc',
                                A => 0,
                            }
                        ],
                    ),
                },
            },
        ) },
        qr/^Invalid options: _prereq_phase/,
        'private attrs cannot be set directly',
    );
}

done_testing;
