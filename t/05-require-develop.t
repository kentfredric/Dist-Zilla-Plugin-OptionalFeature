use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;

use lib 't/lib';
use SpecCompliant;

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
                            -require_develop => 0,
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
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
                plugins => supersetof({
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
        }),
        'metadata correct when extracting feature name, phase and relationship from name',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    is_valid_spec($tzil);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
