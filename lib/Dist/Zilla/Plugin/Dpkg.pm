package Dist::Zilla::Plugin::Dpkg;
use Moose;

use Dist::Zilla::File::InMemory;
use Text::Template;

with 'Dist::Zilla::Role::InstallTool';

=attr compat

Contents of the C<compat> file. Defaults to 7.

=cut

has 'compat' => (
    is => 'ro',
    isa => 'Str',
    default => 7
);

has 'conf_files' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_conf_files'
);

has 'default' => (
    is => 'ro',
    isa => 'Str'
);

has 'install' => (
    is => 'ro',
    isa => 'Str'
);

sub setup_installer {
    my ($self, $arg) = @_;

    # Compat file
    my $compat = Dist::Zilla::File::InMemory->new({
        content => $self->compat."\n",
        name => 'debian/compat'
    });
    $self->add_file($compat);
    
    # Now for the templates
    my %vars = (foo => 'bar');
    
    # config files
    if($self->has_conf_files) {
        my $template = Text::Template->new(SOURCE => $self->conf_files );
        my $guts = $template->fill_in(HASH => \%vars);

        my $file = Dist::Zilla::File::InMemory->new({
            content => $guts,
            name => 'debian/conffiles'
        });
        $self->add_file($file);
    }
}

1;
