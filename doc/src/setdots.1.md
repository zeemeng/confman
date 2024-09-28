# NAME
setdots - manage and configure packages

# SYNOPSIS
**setdots** [**-iIs**] [**-m** *pkg_mgr*] [**-d** *config_dest*] [**-g** *config_repo*] [**-p** *prompt_lvl*] [**-f** *pkg_list*] [*package ...*]\
**setdots** [**-uUr**] [**-m** *pkg_mgr*] [**-d** *config_dest*] [**-g** *config_repo*] [**-p** *prompt_lvl*] [**-f** *pkg_list*] [*package ...*]\
**setdots** [**-l**] [**-f** *pkg_list*] [*package ...*]\
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
**-d** *config_dest*
:   Specify the destination where symlinks of package data and configuration files are created at by the default package configuration operation. The value of *config_dest* overrides that of the SETDOTS_DIR variable (see *ENVIRONMENT*), and would be assigned to it if valid. If neither *config_dest* nor SETDOTS_DEST are specified, the value of the HOME environment variable is used by default.

**-f** *pkg_list*
:   Read newline-separated package names from file *pkg_list* and add them to the list of selected packages.

**-g** *config_repo*
:   Specify the directory corresponding to the package configurations repository. The value of *config_repo* overrides that of the SETDOTS_REPO variable (see *ENVIRONMENT*), and would be assigned to it if valid. If neither *config_repo* nor SETDOTS_REPO are specified, *packages/* within the parent directory of the **setdots** executable is used by default. The repository shall contain a child directory for each package that could be provided to **setdots** as a selected package. Such a directory must have the same name as its associated package, and may contain custom installation scripts, configuration scripts, and data (see **FILES**). Its value is overriden by that of option **-g**'s argument if the latter is specified

**-m** *pkg_mgr*
:   The back-end package manager to use for installation and uninstallation. Can be an absolute path to an executable or a program name if it can be found in PATH. If both this option and the SETDOTS_MGR variable (see *ENVIRONMENT*) are set when this program is invoked, the value of the option argument *pkg_mgr* overrides that of the variable, and SETDOTS_MGR will be reassigned to the value of *pkg_mgr*. If both are not provided when this program is invoked, **setdots** will automatically attempt to select and use an appropriate package manager command, which is then assigned to SETDOTS_MGR.

    **setdots** sets the *export* variable attribute on SETDOTS_MGR, therefore this variable is available in the execution environment of package-specific custom scripts (see *FILES*).

**-p** *prompt_lvl*
:   Set the amount/level of prompts presented by **setdots**. The argument *prompt_lvl* may be one of three values: *0*, *1*, or *2*. If *0* is specified, no prompt or interactive inquiry is generated for all default operations performed by **setdots**. If *1* is specified, minimal prompting is presented (default behaviour). For example, a prompt is presented to validate the set of packages on which to perform certain actions. If *2* is specified, extensive prompting is enable for default operations. In which case, a confirmation prompt is presented before any operation is performed by the selected back-end package manager for every target package. Any invalid value of *prompt_lvl* is ignored.

    If a valid value of *prompt_lvl* is specified, it is assigned to the variable SETDOTS_PROMPT. If both the **-p** option and the SETDOTS_PROMPT variable is set when this program is invoked, a valid value of *prompt_lvl* overrides the value of the variable. Since **setdots** sets the *export* variable attribute on SETDOTS_PROMPT, this variable is available in the execution environment of package-specific custom scripts (see *FILES*).

# ENVIRONMENT
**setdots** sets the *export* attribute on the following shell variables, therefore these are available in the execution environment of package-specific custom scripts (see *FILES*) when such scripts are invoked by **setdots**.

PKG
:   The name of the package currently being processed by **setdots**.

SETDOTS_DEST
:   The destination where symlinks of package data and configuration files are created at by the default package configuration operation. By default, it is set to the value of the HOME environment variable. Its value is overriden by that of option **-d**'s argument if the latter is specified.

SETDOTS_MGR
:   The back-end package manager to use for installation and uninstallation. Can be an absolute path to an executable or a program name if it can be found in PATH. Its value is overriden by that of option **-m**'s argument if the latter is specified. If both this variable and the **-m** option are not provided when this program is invoked, **setdots** will automatically attempt to select and use an appropriate package manager command, which is then assigned to SETDOTS_MGR.

SETDOTS_REPO
:   The directory corresponding to the package configurations repository. By default, it is set to *packages/* within the parent directory of the **setdots** executable. Its value is overriden by that of option **-g**'s argument if the latter is specified. The repository shall contain a child directory for each package that could be provided to **setdots** as a selected package. Such a directory must have the same name as its associated package, and may contain custom installation scripts, configuration scripts, and data (see **FILES**). Its value is overriden by that of option **-g**'s argument if the latter is specified

SETDOTS_PROMPT
:   The amount/level of prompts presented by **setdots**. It may take one of three values: *0*, *1*, or *2*. If set to *0*, no prompt or interactive inquiry is generated for all default operations performed by **setdots**. If set to *1* (the default value), minimal prompting is presented. For example, a prompt is presented to validate the set of packages on which to perform certain actions. If set to *2*, extensive prompting is enable for default operations. In which case, a confirmation prompt is presented before any operation is performed by the selected back-end package manager for every target package. Any invalid value is replaced with *1*.

    If the option **-p** is specified and has a valid argument *prompt_lvl*, it overrides the value set for this variable. SETDOTS_PROMPT would then be reassigned to the value of *prompt_lvl*.

SETDOTS_DIR
:   The directory portion of the canonicalized pathname (as returned by the **realpath** utility) for the **setdots** executable.

# FILES
*$SETDOTS_REPO/\<package_name\>/*
:   Each directory immediately below the package repository (path given by the environment variable SETDOTS_REPO) shall be associated with a package and may contain installation and configuration scripts, as well as configuration data for that package. The name of such a directory MUST match the name of a package that could be provided to **setdots** as a selected package. Furthermore, during the default installation and uninstallation operations, this name is provided as the target to the selected package manager (see option **-m**). If this name cannot be reliably used as the target for all supported package managers, then custom installation scripts (see below) should be created.

*$SETDOTS_REPO/\<package_name\>/data/*
:   Optional. Directory which contains package configuration files and data. If setup scripts (see below) for the associated package are not provided, by default when the package is set up / configured, all files within this directory are symlinked to the location specified by the SETDOTS_DEST environment variable. Similarly, if setup scripts for the associated package are not provided, by default when the package configuration is removed / unset by **setdots**, those symlinks are removed.

*$SETDOTS_REPO/\<package_name\>/platform*
:   Optional. If this file exists, its content shall be a newline-separated list of case insensitive BRE patterns that may match any part of the *uname -s* command's output on platforms/operating systems for which the package is compatible with. Packages which designate such a platform compatibility list will *ONLY* be subject to any operation on its supported platforms.

*$SETDOTS_REPO/\<package_name\>/noinstall*
:   Optional. If this file exists, installation for this package is ALWAYS skipped.

*$SETDOTS_REPO/\<package_name\>/preinstall*
:   Optional. Pre-installation script that is executed before its associated package undergoes default installation, or before the *$SETDOTS_REPO/\<package_name\>/install* script if it exists.

*$SETDOTS_REPO/\<package_name\>/install*
:   Optional. Installation script that replaces the default package installation operation. The default package installation operation simply involves installing a selected package using the selected package manager.

*$SETDOTS_REPO/\<package_name\>/postinstall*
:   Optional. Post-installation script that is executed after its associated package undergoes default installation, or after the *$SETDOTS_REPO/\<package_name\>/install* script if it exists.

*$SETDOTS_REPO/\<package_name\>/uninstall*
:   Optional. Uninstallation script that replaces the default package uninstallation operation. The default package uninstallation operation simply involves uninstalling a selected package using the selected package manager.

*$SETDOTS_REPO/\<package_name\>/nosetup*
:   Optional. If this file exists, setup / configuration for this package is ALWAYS skipped.

*$SETDOTS_REPO/\<package_name\>/presetup*
:   Optional. Pre-configuration script that is executed before its associated packages undergoes default setup / configuration, or before the *$SETDOTS_REPO/\<package_name\>/setup* script if it exists.

*$SETDOTS_REPO/\<package_name\>/setup*
:   Optional. Configuration script that replaces the default package setup / configuration operation (see *$SETDOTS_REPO/\<package_name\>/data/* above).

*$SETDOTS_REPO/\<package_name\>/postsetup*
:   Optional. Post-configuration script that is executed after its associated packages undergoes default setup / configuration, or after the *$SETDOTS_REPO/\<package_name\>/setup* script if it exists.

*$SETDOTS_REPO/\<package_name\>/unset*
:   Optional. Configuration removal script that replaces the default package configuration removal operation (see *$SETDOTS_REPO/\<package_name\>/data/* above).

# NOTES
A valid package name shall not consist strictly of whitespace characters as defined by the **space** character class of the shell environment locale. A valid package name shall also not contain any occurance of the \<newline\> character which is reserved for use as a delimiter by **setdots**.

To be recognizable / selectable by **setdots**, each *package* specified as command operand, or specified within a *pkg_list* file as required by the **-f** option, must have an associated sub-directory of the same name within the targeted package repository (see variable SETDOTS_REPO).

