% SETDOTS(1) setdots 0.1
%
% November 2023

# NAME
setdots - manage and configure packages

# SYNOPSIS
**setdots** [**-iIs**] [**-f** *package_list*] [**-m** *manager*] [**-p** *n*] [*package* *...*]\
**setdots** [**-uUr**] [**-f** *package_list*] [**-m** *manager*] [**-p** *n*] [*package* *...*]\
**setdots** [**-l**] [**-f** *package_list*] [*package* *...*]\
**setdots** [**-vhH**] 

# DESCRIPTION
**setdots** can be used to install, uninstall, configure, and remove configuration for a list of selected packages. Selected packages must be defined in a target package repository (see *ENVIRONMENT*). If no selected package is specified, **setdots** selects all packages defined in the repository. If no *Operation* option is provided, **setdots** installs and configures the selected package(s) (same effect as option **-I**). Management operations for each package can be redefined via custom scripts (see *FILES*). Package names must conform to certain requirements as specified in the *NOTES* section.

# OPTIONS

## Operation
**-h**
:   Print a brief help message and exit.

**-H**
:   Show the manpage for **setdots**.

**-i**
:   Install the selected packages.

**-I**
:   Install and configure the selected packages. Implies both the **-i** and **-s** options.

**-l**
:   List and show information about selected packages.

**-s**
:   Set up / configure the selected packages.

**-r**
:   Remove configuration for the selected packages.

**-u**
:   Uninstall the selected packages. Package configurations are NOT implicitly removed.

**-U**
:   Uninstall and remove configuration for the selected packages.

**-v**
:   Print version information and exit.

## Configuration
**-f** *package_list*
:   Read newline-separated package names from a file and add them to the list of selected packages.

**-m** *manager*
:   The back-end package manager to use for installation and uninstallation. Can be an absolute path to an executable or a program name if it can be found in PATH. If both this option and the PKG_MANAGER (see *ENVIRONMENT*) variable are set when this program is invoked, the value of the option argument *manager* overrides that of the variable, and PKG_MANAGER will be reassigned to the value of *manager*. If both are not provided when this program is invoked, **setdots** will automatically attempt to select and use an appropriate package manager command, which is then assigned to PKG_MANAGER.

    **setdots** sets the *export* variable attribute on PKG_MANAGER, therefore this variable is available in the execution environment of package-specific custom scripts (see *FILES*).

**-p** *n*
:   Set the amount/level of prompts presented by **setdots**. The argument *n* may be one of three values: *0*, *1*, or *2*. If *0* is specified, no prompt or interactive inquiry is generated for all default operations performed by **setdots**. If *1* is specified, minimal prompting is presented (default behaviour). For example, a prompt is presented to validate the set of packages on which to perform certain actions. If *2* is specified, extensive prompting is enable for default operations. In which case, a confirmation prompt is presented before any operation is performed by the selected back-end package manager for every target package. Any invalid value of *n* is ignored.

    If a valid value of *n* is specified, it is assigned to the variable SETDOTS_PROMPT. If both the **-p** option and the SETDOTS_PROMPT variable is set when this program is invoked, a valid value of *n* overrides the value of the variable. Since **setdots** sets the *export* variable attribute on SETDOTS_PROMPT, this variable is available in the execution environment of package-specific custom scripts (see *FILES*).

# ENVIRONMENT
**setdots** sets the *export* attribute on the following shell variables, therefore these are available in the execution environment of package-specific custom scripts (see *FILES*) when such scripts are invoked by **setdots**.

PKG_CONFIG_DEST
:   The destination where symlinks of package data and configuration files are created at by the default package configuration operation. By default, it is set to the value of the HOME environment variable.

PKG_MANAGER
:   The back-end package manager to use for installation and uninstallation. Can be an absolute path to an executable or a program name if it can be found in PATH. Its value is overriden be the **-m** option's argument if the later is specified. If both this variable and the **-m** option are not provided when this program is invoked, **setdots** will automatically attempt to select and use an appropriate package manager command, which is then assigned to PKG_MANAGER.

PKG_REPO
:   The path to the package repository directory. By default, it is set to *packages/* within the directory where the **setdots** executable resides. The repository contains a child directory for each package that could be provided to **setdots** as a selected package. Such a directory must have the same name as its associated package, and may contain custom installation scripts, configuration scripts, and data (see **FILES**).

SETDOTS_PROMPT
:   The amount/level of prompts presented by **setdots**. It may take one of three values: *0*, *1*, or *2*. If set to *0*, no prompt or interactive inquiry is generated for all default operations performed by **setdots**. If set to *1* (the default value), minimal prompting is presented. For example, a prompt is presented to validate the set of packages on which to perform certain actions. If set to *2*, extensive prompting is enable for default operations. In which case, a confirmation prompt is presented before any operation is performed by the selected back-end package manager for every target package. Any invalid value is replaced with *1*.

    If the option **-p** is specified and has a valid argument *n*, it overrides the value set for this variable. SETDOTS_PROMPT would then be reassigned to the value of *n*.

# FILES
*$PKG_REPO/\<package_name\>/*
:   Each directory immediately below the package repository (path given by the environment variable PKG_REPO) shall be associated with a package and may contain installation and configuration scripts, as well as configuration data for that package. The name of such a directory MUST match the name of a package that could be provided to **setdots** as a selected package. Furthermore, during the default installation and uninstallation operations, this name is provided as the target to the selected package manager (see option **-m**). If this name cannot be reliably used as the target for all supported package managers, then custom installation scripts (see below) should be created.

*$PKG_REPO/\<package_name\>/data/*
:   Optional. Directory which contains package configuration files and data. If setup scripts (see below) for the associated package are not provided, by default when the package is set up / configured, all files within this directory are symlinked to the location specified by the PKG_CONFIG_DEST environment variable. Similarly, if setup scripts for the associated package are not provided, by default when the package configuration is removed / unset by **setdots**, those symlinks are removed.

*$PKG_REPO/\<package_name\>/noinstall*
:   Optional. If this file exists, installation for this package is ALWAYS skipped.

*$PKG_REPO/\<package_name\>/preinstall*
:   Optional. Pre-installation script that is executed before its associated package undergoes default installation, or before the *$PKG_REPO/\<package_name\>/install* script if it exists.

*$PKG_REPO/\<package_name\>/install*
:   Optional. Installation script that replaces the default package installation operation. The default package installation operation simply involves installing a selected package using the selected package manager.

*$PKG_REPO/\<package_name\>/postinstall*
:   Optional. Post-installation script that is executed after its associated package undergoes default installation, or after the *$PKG_REPO/\<package_name\>/install* script if it exists.

*$PKG_REPO/\<package_name\>/uninstall*
:   Optional. Uninstallation script that replaces the default package uninstallation operation. The default package uninstallation operation simply involves uninstalling a selected package using the selected package manager.

*$PKG_REPO/\<package_name\>/nosetup*
:   Optional. If this file exists, setup / configuration for this package is ALWAYS skipped.

*$PKG_REPO/\<package_name\>/presetup*
:   Optional. Pre-configuration script that is executed before its associated packages undergoes default setup / configuration, or before the *$PKG_REPO/\<package_name\>/setup* script if it exists.

*$PKG_REPO/\<package_name\>/setup*
:   Optional. Configuration script that replaces the default package setup / configuration operation (see *$PKG_REPO/\<package_name\>/data/* above).

*$PKG_REPO/\<package_name\>/postsetup*
:   Optional. Post-configuration script that is executed after its associated packages undergoes default setup / configuration, or after the *$PKG_REPO/\<package_name\>/setup* script if it exists.

*$PKG_REPO/\<package_name\>/unset*
:   Optional. Configuration removal script that replaces the default package configuration removal operation (see *$PKG_REPO/\<package_name\>/data/* above).

# NOTES
A valid package name shall not consist strictly of whitespace characters as defined by the **space** character class of the shell environment locale. A valid package name shall also not contain any occurance of the \<newline\> character which is reserved for use as a delimiter by **setdots**.

To be recognizable / selectable by **setdots**, each *package* specified as command operand, or specified within a *package-list* file as required by the **-f** option, must have an associated sub-directory of the same name witin the targeted package repository (see variable PKG_REPO).

