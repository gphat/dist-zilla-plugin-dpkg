package Dist::Zilla::Plugin::Dpkg;
use Moose;

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

# ABSTRACT: Generate Dpkg files for your perl module

=head1 SYNOPSIS

  #  [Dpkg]
  #  architecture = amd64
  #  default_template = package/debian/default

=head1 DESCRIPTION

Dist::Zilla::Plugin::Dpkg generates Debian' controls files that you can use
with debhelper to generate packages of your perl module.

There are a handful of tools that provide similar functionality. Most of
them expect your perl module to have a standard installation mechanism.  This
module was born of a need for customization. It's projects used per-package
perlbrews and all manner of custom bits.

=cut

use Dist::Zilla::File::InMemory;
use Text::Template;

with 'Dist::Zilla::Role::InstallTool';

=begin :prelude

=head1 TEMPLATES

This plugin uses L<Text::Template>.  The following variables will be passed
to any templates that are processed, using attributes as values:

=over 4

=item architecture

=item author (first in authors list)

=item name

=item package_binary_depends

=item package_depends

=item package_description

=item package_name

=item package_section

=item package_shell_name

=item version

=back

=head1 SUBCLASSING

Each of the aforementioned template methods has an accompanying method that
provides a default template.  Most of these are undefined and therefore
unused.  This subclassing behavior allows you to create subclasses of
Dist::Zilla::Plugin::Dpkg that provide default templates for many of the files.

The idea is to allow the easy creation of something like a
Dist::Zilla::Plugin::Dpkg::Starman that provides boilerplate code for a
L<Starman>-based application.

=end :prelude

=attr architecture

The architecture of the package we're building. Defaults to C<any>.

=cut

has 'architecture' => (
    is => 'ro',
    isa => 'Str',
    default => 'any'
);

=attr compat_template

If set, the specified file is used as a template for the C<compat> file.

=method has_compat_template

=cut

has 'compat_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_compat_template'
);

=attr compat_template_default

A default compat file template that will be used it a template isn't provided
to C<compat_template>.

=method has_compat_template_default

=cut

has 'compat_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_compat_template_default',
    default => "7\n"
);

=attr conffiles_template

If set, the specified file is used as a template for the C<conffiles> file.

=method has_conffiles_template

Predicate that is true if there is a conffiles_template

=cut

has 'conffiles_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_conffiles_template'
);

=attr conffiles_template_default

A default conffiles file template that will be used it a template isn't
provided to C<conffiles_template>.

=method has_conffiles_template_template

=cut

has 'conffiles_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_conffiles_template_default'
);

=attr config_template

If set, the specified file is used as a template for the C<config> file.

=method has_config_template

=cut

has 'config_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_config_template'
);

=attr config_template_default

A default config file template that will be used it a template isn't provided
to C<config_template>.

=method has_config_template_default

=cut

has 'config_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_config_template_default',
);

=attr control_template

If set, the specified file is used as a template for the C<control> file.
If not set uses an internal default.

=method has_control_template

=cut

has 'control_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_control_template'
);

=attr control_template_default

A default control file template that will be used it a template isn't provided
to C<control_template>.

=method has_control_template_default

=cut

has 'control_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_control_template_default',
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

=attr default_template

If set, the specified file is used as a template for the C<default> file.

=method has_default_template

=cut

has 'default_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_default_template'
);

=attr default_template_default

A default default file template that will be used it a template isn't provided
to C<default_template>.

=method has_default_template_default

=cut

has 'default_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_default_template_default'
);

=attr init_template

If set, the specified file is used as a template for the C<init> file.

=method has_init_template

=cut

has 'init_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_init_template'
);

=attr init_template_default

A default init file template that will be used it a template isn't provided
to C<init_template>.

=method has_init_template_default

=cut

has 'init_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_init_template_default'
);

=attr install_template

If set, the specified file is used as a template for the C<install> file.

=method has_install_template

=cut

has 'install_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_install_template'
);

=attr install_template_default

A default install file template that will be used it a template isn't provided
to C<install_template>.

=method has_install_template_default

=cut

has 'install_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_install_template_default'
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

=attr package_shell_name

The name of this package converted to a form suitable for environment variable
use. Foo-Bar becomes FOO_BAR.  Defaults to C<name> upper-cased with hyphens
converted to underscores.

=cut

has 'package_shell_name' => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $name = uc($self->zilla->name)
        $name =~ s/-/_/g;
        return $name;
    }
);

=attr postinst_template

If set, the specified file is used as a template for the C<postinst> file.

=method has_postinst_template

=cut

has 'postinst_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_postinst_template'
);

=attr postinst_template_default

A default postinst file template that will be used it a template isn't provided
to C<postinst_template>.

=method has_postinst_template_default

=cut

has 'postinst_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_postinst_template_default'
);

=attr postrm_template

If set, the specified file is used as a template for the C<postrm> file.

=method has_postrm_template

=cut

has 'postrm_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_postrm_template'
);

=attr postrm_template_default

A default postrm file template that will be used it a template isn't provided
to C<postrm_template>.

=method has_postrm_template_default

=cut

has 'postrm_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_postrm_template_default'
);

=attr rules_template

If set, the specified file is used as a template for the C<rules> file.

=method has_rules_template

=cut

has 'rules_template' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_rules_template'
);

=attr rules_template_default

A default rules file template that will be used it a template isn't provided
to C<rules_template>.

=method has_rules_template_default

=cut

has 'rules_template_default' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_rules_template_default'
);

sub setup_installer {
    my ($self, $arg) = @_;

    my @req_files = qw(compat control default install postinst postrm);
    my @opt_files = qw(conffiles config init rules);

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
        package_shell_name => $self->package_shell_name,
        version         => $self->zilla->version
    );
    
    foreach my $file (@req_files) {
        $self->_generate_file($file, 1, \%vars);
    }
    foreach my $file (@opt_files) {
        $self->_generate_file($file, 0, \%vars);
    }
}

sub _generate_file {
    my ($self, $file, $required, $vars) = @_;

    my $pred = 'has_'.$file.'_template';
    my $temp = $file.'_template';
    my $pred_def = 'has_'.$file.'_template_default';
    my $def = $file.'_template_default';

    my $template;
    if($self->$pred) {
        # We have a template, use it.
        die "Can't find file: ".$self->$temp unless -e $self->$temp;
        $template = Text::Template->new(TYPE => 'FILE', SOURCE => $self->$temp);
        $self->log("Used template for file '$file'");
    } elsif($self->$pred_def) {
        # We have a default, use it
        $template = Text::Template->new(TYPE => 'STRING', SOURCE => $self->$def);
        $self->log("Used default for file '$file'");
    } else {
        # Blow up, we ain't got shit
        $self->log("No template or default for '$file'");
        if($required) {
            die "No template or default provided for '$file'";
        }
    }

    if(defined($template)) {
        $self->log("Added file for '$file'");
        $self->add_file(Dist::Zilla::File::InMemory->new({
            content => $template->fill_in(HASH => $vars),
            name => "debian/$file"
        }));
    }
}

1;
