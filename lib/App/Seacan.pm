package App::Seacan;
use strict;
use warnings;
use constant { 'EXEC_MODE' => '0755' };

# Semantic Vesioning: http://semver.org/
# Not sure if I want to use v-string, but I do want to follow
# semvar as a convention.
our $VERSION = "0.1.0";

use English qw<-no_match_vars>;
use Mo qw<required coerce>;
use File::Path qw<make_path>;
use TOML qw<from_toml>;
use Path::Tiny qw<path>;

has config => (
    required => 1,
    coerce   => sub {
        my $c = $_[0];

        if ( !ref($c) && -f $c ) {
            $c = from_toml( path($c)->slurp_utf8 );
        }

        $c->{perl}{installed_as} //= "seacan";

        return $c;
    }
);

sub seacan_perlbrew_root {
    my $self = shift;
    return path($self->config->{seacan}{output}, "perlbrew");
}

sub seacan_perl {
    my $self = shift;
    return $self->seacan_perlbrew_root->child(
        'perls',
        $self->config->{perl}{installed_as},
        'bin',
        'perl',
   );
}

sub perl_is_installed {
    my $self = shift;

    my $perlbrew_root_path
        = path( $self->config->{seacan}{output}, 'perlbrew' );

    $perlbrew_root_path->is_dir
        or return 0;

    my $perl_executable = $perlbrew_root_path->child(
        'perls',
        $self->config->{perl}{installed_as},
        'bin',
        'perl',
    );

    if ( $perl_executable->is_file ) {
        print STDERR "perl is installed: $perl_executable\n";
        return 1;
    }

    return 0;
}

sub install_perl {
    my $self = shift;

    my $perlbrew_root_path = $self->seacan_perlbrew_root;
    make_path( $perlbrew_root_path ) unless -d $perlbrew_root_path;

    for (keys %ENV) {
        delete $ENV{$_} if /\APERLBREW_/;
    }
    delete $ENV{PERL_CPANM_OPT};
    delete $ENV{PERL_LOCAL_LIB_ROOT};
    delete $ENV{PERL_MB_OPT};
    delete $ENV{PERL_MM_OPT};
    delete $ENV{PERL5LIB};

    $ENV{PERLBREW_ROOT} = $perlbrew_root_path;

    system("curl -L https://install.perlbrew.pl | bash") == 0 or die $!;
    my $perlbrew_command = path($perlbrew_root_path, "bin", "perlbrew")->stringify;

    my @perl_install_cmd = (
        $perlbrew_command,
        "install", $self->config->{perl}{version},
        "--as",    $self->config->{perl}{installed_as},

        $self->config->{perl}{relocatable_INC}
            ? ("-Duserelocatableinc")
            : (),

        $self->config->{perl}{noman}
            ? ("--noman")
            : (),

        $self->config->{perl}{notest}
            ? ("--notest")
            : (),

        $self->config->{perl}{parallel}
            ? ("-j", $self->config->{perl}{parallel})
            : (),
    );
    system(@perl_install_cmd) == 0 or die $!;

    system($perlbrew_command, "install-cpanm", "--force");

    system($perlbrew_command, "clean");
}

sub install_cpan {
    my $self = shift;
    my $cpanm_command = $self->seacan_perlbrew_root->child( "bin", "cpanm");
    my $perl_command = $self->seacan_perl;

    local $OUTPUT_FIELD_SEPARATOR = q{ };
    system($perl_command, $cpanm_command, "--notest", "-L", path($self->config->{seacan}{output}, "local"), "--installdeps", $self->config->{seacan}{app} ) == 0 or die $!;
}

sub copy_app {
    my $self = shift;
    my $target_directory = path($self->config->{seacan}{output}, "app", $self->config->{seacan}{app_name})->stringify;
    my $source_directory = $self->config->{seacan}{app};

    make_path($target_directory);

    unless ( $source_directory =~ m{/$} ) {
        # this is telling rsync to copy the contents of $source_directory
        # instead of $source_directory itself
        $source_directory .= "/";
    }

    system("rsync", "-8vPa", $source_directory, $target_directory) == 0 or die;
}

sub create_launcher {
    # Instead of giving a very long command to the user
    # a launcher script is generated.
    # app_name and main_script could be added to the configuration
    # so we can add the info directly instead of "guessing" it
    # through a regex.

    my $self = shift;
    my $output = $self->config->{seacan}{output};

    # The launcher script goes into bin of the target directory
    my $target_directory = path($output, 'bin')->stringify;

    my $app_name = $self->config->{seacan}{app_name};
    if ( !$app_name ) {
        # This is a hack to determine the application name from the
        # output value of the config in case it wasn't provided

        $app_name = $output;
        $app_name =~ s/^.+\/(.+?)$/$1/;
    }

    # Apps following the CPAN guidelines have a lib directory with the
    # modules. Adding this to the PERL5LIB allows to run this distributions
    # without installing them.
    my $launcher = path($target_directory, $app_name)->stringify;
    make_path($target_directory);
    my $launcher_path = path($luncher);

    $launcher_path->spew_utf8(
        "#!/bin/bash\n",
        'CURRDIR=$(dirname $(readlink -f $0))' . "\n",
        "PERL5LIB=\$CURRDIR/../local/lib/perl5:\$CURRDIR/../app/$app_name/lib\n",
        "export PERL5LIB\n",

        # String "app" shouldn't be hardcoded and be part of the config
        # app.pl will not be the likely name of the main script.
        "\$CURRDIR/../perlbrew/perls/seacan/bin/perl \$CURRDIR/../app/$app_name/bin/$app_name \$@\n",
    );

    $launcher_path->chmod( EXEC_MODE() );
}

sub run {
    my $self = shift;
    $self->install_perl unless $self->perl_is_installed;
    $self->install_cpan;
    $self->copy_app;
    $self->create_launcher;
}

1;

=encoding utf-8

=head1 NAME

Seacan - A tool to prepare a self-contained app directory.

=head1 DESCRIPTION

Read the README file for now. L<https://github.com/gugod/Seacan/blob/master/README.md>

=head1 COPYRIGHT

Copyright (c) 2016 Kang-min Liu C<< <gugod@gugod.org> >>.

=head1 LICENCE

The MIT License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
