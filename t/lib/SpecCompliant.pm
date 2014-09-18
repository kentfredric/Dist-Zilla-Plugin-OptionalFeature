use strict;
use warnings;
package SpecCompliant;

use Exporter 'import';
our @EXPORT = ('is_valid_spec');

use YAML::Tiny;
use JSON::MaybeXS;
use Test::CPAN::Meta::YAML::Version;
use Test::CPAN::Meta::JSON::Version;
use Test::More;
use Path::Tiny;

sub is_valid_spec
{
    my $tzil = shift;

    local $TODO = $::TODO;

    subtest is_valid_spec => sub
    {
        # note - YAML::Tiny wants characters, not octets
        my $yaml = $tzil->slurp_file('build/META.yml');
        my $data = eval { YAML::Tiny->read_string($yaml)->[0] };
        if (!ok($data, 'YAML is valid'))
        {
            diag(YAML::Tiny->errstr);
        }
        else
        {
            my $meta_yaml_spec = Test::CPAN::Meta::YAML::Version->new(data => $data);
            ok(!$meta_yaml_spec->parse(), 'no spec errors in META.yml')
                or diag($_) foreach $meta_yaml_spec->errors;
        }

        # note - decode_json wants octets, not characters
        my $json = path($tzil->tempdir, qw(build META.json))->slurp_raw;
        my $meta_json_spec = Test::CPAN::Meta::JSON::Version->new(data => decode_json($json));
        ok(!$meta_json_spec->parse(), 'no spec errors in META.json')
            or do { diag($_) foreach $meta_json_spec->errors };
    };
}

1;
