package Dist::Zilla::Plugin::Dpkg;
use Moose;

# Skipped:
# * copyright
# * docs
# * files
# * manpage.1
# * manpage.sgml
# * manpage.xml
# * menu
# * preinst
# * prerm
# * cron.d
# * doc-base
# * substvars
# * templates
# * watch

use Dist::Zilla::File::InMemory;
use Text::Template;

with 'Dist::Zilla::Role::InstallTool';

=begin :prelude

=head2 Templates

This plugin uses L<Text::Template>.  The following variables will be passed
to any templates that are processed, using attributes as values.

=over 4

=item architecture

=item author (first in authors list)

=item name

=item package_binary_depends

=item package_depends

=item package_description

=item package_name

=item package_section

=item version

=back

=end :prelude

=attr architecture

The architecture of the package we're building. Defaults to C<any>.

=cut

has 'architecture' => (
    is => 'ro',
    isa => 'Str',
    default => 'any'
);

=attr compat

Contents of the C<compat> file. Defaults to 7.

=cut

has 'compat' => (
    is => 'ro',
    isa => 'Str',
    default => 7
);

=attr conffiles_template

If set, the specified file is used as a template for the C<conffiles> file.

=cut

has 'conffiles_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_conffiles_template'
);

=attr config_template

If set, the specified file is used as a template for the C<config> file.

=cut

has 'config_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_config_template'
);

=attr control_template

If set, the specified file is used as a template for the C<control> file.
If not set uses an internal default.

=cut

has 'control_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_control_template'
);

=attr default_template

If set, the specified file is used as a template for the C<default> file.

=cut

has 'default_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_default_template'
);

=attr init_template

If set, the specified file is used as a template for the C<init> file.

=cut

has 'init_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_init_template'
);

=attr install_template

If set, the specified file is used as a template for the C<install> file.

=cut

has 'install_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_install_template'
);

=attr package_depends

Source binary dependencies. Defaults to C<debhelper (>= 7.0.50~)>.

http://www.debian.org/doc/debian-policy/ch-relationships.html#s-sourcebinarydeps

=cut

has 'package_depends' => (
    is => 'ro',
    isa => 'Str',
    default => 'debhelper (>= 7.0.50~)'
);

=attr package_binary_depends

Binary dependencies. Defaults to <C${misc:Depends}, ${shlibs:Depends}, ${perl:Depends}>.

http://www.debian.org/doc/debian-policy/ch-relationships.html#s-binarydeps

=cut

has 'package_binary_depends' => (
    is => 'ro',
    isa => 'Str',
    default => '${misc:Depends}, ${shlibs:Depends}, ${perl:Depends}'
);

=attr package_description

The description of the package we're making. Should use the form of:

Synopsis
Multi-line description
tacked on the end

L<http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-f-Description>.

=cut

has 'package_description' => (
    is => 'ro',
    isa => 'Str',
    default => '<single line synopsis>
 <extended description over several lines>'
);

=attr package_name

The name of the package we're making.  Defaults to the lowercased version of
the package name. Uses Dist::Zilla's C<name> attribute.

=cut

has 'package_name' => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        return lc($self->zilla->name)
    }
);

=attr package_priority

The priority of the package we're making. Defaults to C<extra>.

L<http://www.debian.org/doc/debian-policy/ch-archive.html#s-priorities>.

=cut

has 'package_priority' => (
    is => 'ro',
    isa => 'Str',
    default => 'extra'
);

=attr

The section of the package we're making. Defaults to C<lib>.

L<http://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections>.

=cut

has 'package_section' => (
    is => 'ro',
    isa => 'Str',
    default => 'lib'
);

=attr postinst_template

If set, the specified file is used as a template for the C<postinst> file.

=cut

has 'postinst_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_postinst_template'
);

=attr postrm_template

If set, the specified file is used as a template for the C<postrm> file.

=cut

has 'postrm_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_postrm_template'
);

=attr rules_template

If set, the specified file is used as a template for the C<rules> file.

=cut

has 'rules_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_rules_template'
);

has '_control_file' => (
    is => 'ro',
    isa => 'Str',
    default => 'Source: {$package_name}
Section: {$package_section}
Priority: {$package_priority}
Maintainer: {$author}
Build-Depends: {$package_depends}
Standards-Version: 3.8.4

Package: {$package_name}
Architecture: {$architecture}
Depends: {$package_binary_depends}
Description: {$package_description}
'
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
    my %vars = (
        architecture    => $self->architecture,
        author          => $self->zilla->authors->[0],
        name            => $self->zilla->name,
        package_binary_depends => $self->package_binary_depends,
        package_depends => $self->package_depends,
        package_description => $self->package_description,
        package_name    => $self->package_name,
        package_priority=> $self->package_priority,
        package_section  => $self->package_section,
        version         => $self->zilla->version
    );
    
    # conffiles file
    if($self->has_conffiles_template) {
        die "Can't find file: ".$self->conffiles_template unless -e $self->conffiles_template;
        my $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->conffiles_template);
        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/conffiles'
        }));
    }

    # config file
    if($self->has_config_template) {
        die "Can't find file: ".$self->config_template unless -e $self->config_template;
        my $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->config_template);

        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/config'
        }));
    }

    # control file
    if($self->has_control_template) {
        die "Can't find file: ".$self->control_template unless -e $self->control_template;
        my $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->control_template);

        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/control'
        }));
    } else {
        my $template = Text::Template->new(TYPE => 'STRING', SOURCE => $self->_control_file);

        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/control'
        }));
    }

    # default file
    if($self->has_default_template) {
        die "Can't find file: ".$self->default_template unless -e $self->default_template;
        my $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->default_template);

        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/default'
        }));
    }

    # init file
    if($self->has_init_template) {
        die "Can't find file: ".$self->init_template unless -e $self->init_template;
        my $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->init_template);

        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/init'
        }));
    }

    # install file
    if($self->has_install_template) {
        die "Can't find file: ".$self->install_template unless -e $self->install_template;
        my $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->install_template);

        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/install'
        }));
    }

    # postinst file
    if($self->has_postinst_template) {
        die "Can't find file: ".$self->postinst_template unless -e $self->postinst_template;
        my $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->postinst_template);

        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/postinst'
        }));
    }

    # postrm file
    if($self->has_postrm_template) {
        die "Can't find file: ".$self->postrm_template unless -e $self->postrm_template;
        my $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->postrm_template);

        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/postrm'
        }));
    }

    # rules file
    if($self->has_rules_template) {
        die "Can't find file: ".$self->rules_template unless -e $self->rules_template;
        my $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->rules_template);

        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => \%vars),
            name => 'debian/rules'
        }));
    }
}

1;
