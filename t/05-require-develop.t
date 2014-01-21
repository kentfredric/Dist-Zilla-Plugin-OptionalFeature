use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::Deep::JSON;
use Test::DZil;

use lib 't/lib';
use SpecCompliant;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-BuildSuggests' => {
                            -description => 'desc',
                            -require_develop => 0,
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
                # no develop prereqs
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
                            always_recommend => 0,
                            require_develop => 0,
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

done_testing;
