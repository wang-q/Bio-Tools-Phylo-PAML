package Bio::Installer::PAML;

use vars qw(@ISA %DEFAULTS);
use strict;

use Bio::Root::Root;
use Bio::Installer::Generic;

@ISA = qw(Bio::Installer::Generic );

# ABSTRACT: DESCRIPTION of Object
# AUTHOR: Albert Vilella <avilella@gmail.com>
# OWNER: Albert Vilella <avilella@gmail.com>
# LICENSE: Perl_5

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=cut

BEGIN {
    %DEFAULTS = ( 'ORIGIN_DOWNLOAD_DIR' => 'http://abacus.gene.ucl.ac.uk/software/',
                  'BIN_FOLDER' => 'src',
                  'DESTINATION_DOWNLOAD_DIR' => '/tmp',
                  'DESTINATION_INSTALL_DIR' => "$ENV{'HOME'}",
                  'PACKAGE_NAME' => 'paml4a.tar.gz',
                  'DIRECTORY_NAME' => 'paml4',
                  'ENV_NAME' => 'PAMLDIR',
                );
}


=method get_default

 Title   : get_default
 Usage   :
 Function:
 Example :
 Returns :
 Args    :


=cut

sub get_default {
    my $self = shift;
    my $param = shift;
    return $DEFAULTS{$param};
}


=method install

 Title   : install
 Usage   : $installer->install();
 Function:
 Example :
 Returns :
 Args    :


=cut

sub install{
   my ($self,@args) = @_;
   $self->_decompress;
   $self->_tweak_paml_makefile;
   $self->_execute_paml_makefile;
   $self->_remember_env;
}


=internal _execute_paml_makefile

 Title   : _execute_paml_makefile
 Usage   :
 Function:
 Example :
 Returns :
 Args    :


=cut

sub _execute_paml_makefile{
   my ($self,@args) = @_;
   my $call;

   my $destination = $self->destination_install_dir . "/" . $self->directory_name . "/src";
   chdir $destination or $self->throw("Cant cd to $destination");
   print "\n\nCompiling now... (this might take a while)\n\n";
   if (($^O =~ /dec_osf|linux|unix|bsd|solaris|darwin/i)) {
       $call = "make";
       system("$call") == 0 or $self->throw("Error when trying to run make");
   } else {
       $self->throw("_execute_paml_makefile not yet implemented in this platform");
   }
}


=internal _tweak_paml_makefile

 Title   : _tweak_paml_makefile
 Usage   :
 Function:
 Example :
 Returns :
 Args    :


=cut

sub _tweak_paml_makefile{
    my ($self,@args) = @_;
    my $gcc3;
    my $return = qx/gcc -v 2>&1/;
    if ($return =~ /version 3/) {
        $return = `cat /proc/cpuinfo`;
        if( ($return =~ /mmx/) || ($return =~ /3dnow/)) {
            my $destination = $self->destination_install_dir . "/" . $self->directory_name . "/src";
            chdir $destination or $self->throw("Cant cd to $destination");
            my $new = "Makefile";
            open(OLD, "< Makefile.UNIX")         or  $self->throw("can't open Makefile.UNIX");
            open(NEW, "> $new")         or $self->throw("can't open $new");
            while (<OLD>) {
                # change $_, then...
                $_ =~ s/CFLAGS = -O3/\# CFLAGS = -O3/g;
                if( $return =~ /3dnow/ ) {
                    $_ =~ s/#CFLAGS = -march=athlon -mcpu=athlon -O4 -funroll-loops -fomit-frame-pointer -finline-functions/CFLAGS = -march=athlon -mcpu=athlon -O4 -funroll-loops -fomit-frame-pointer -finline-functions/g;
                } elsif( $return =~ /mmx/ ) {
                    $_ =~ s/#CFLAGS = -march=pentiumpro -mcpu=pentiumpro -O4 -funroll-loops -fomit-frame-pointer -finline-functions/CFLAGS = -march=pentiumpro -mcpu=pentiumpro -O4 -funroll-loops -fomit-frame-pointer -finline-functions/g;
                }
                print NEW $_ or $self->throw("can't write $new");
            }
            close(OLD)                  or $self->throw("can't close Makefile.UNIX");
            close(NEW)                  or $self->throw("can't close $new");
        }
    }


}


1;
