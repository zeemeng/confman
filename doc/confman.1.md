# NAME
confman - manage and configure packages

# SYNOPSIS
**confman** [**-iIcb**] [**-m** *pkg_mgr*] [**-d** *config_dest*] [**-r** *config_repo*] [**-p** *prompt_lvl*] [**-f** *pkg_list*] [package...]\
**confman** [**-uUxb**] [**-m** *pkg_mgr*] [**-d** *config_dest*] [**-r** *config_repo*] [**-p** *prompt_lvl*] [**-f** *pkg_list*] [package...]\
**confman** [**-l**] [**-f** *pkg_list*] [package...]\
**confman** [**-vhH**]\
**confman** [**-m** *pkg_mgr*] [**-d** *config_dest*] [**-r** *config_repo*] [**-p** *prompt_lvl*] **-D** *default_op* [package]\
**confman** **-L** *log_lvl* log_msg...\

# DESCRIPTION
**confman** can be used to install, uninstall, configure, and remove configuration for a list of selected packages. Selected packages must be defined in a target package repository (see *ENVIRONMENT*). If no selected package is specified, **confman** selects all packages defined in the repository. If no *Operation* option is provided, **confman** installs and configures the selected package(s) (same effect as option **-I**). Management operations for each package can be redefined via user scripts (see *FILES*). Package names must conform to certain requirements as specified in the *NOTES* section.

# OPTIONS

## Operation
**-c**
:   Configure the selected packages.

**-D** *default_op*
:   Only perform the operation specified by *default_op* on the (optional) single package given as operand, or if the latter is unspecified, on the package defined by the environment variable *PKG*. This option is useful in user scripts (see *FILES*) when the *default_op* is desired as part of the custom workflow. *default_op* shall be one of: *update*, *install*, *uninstall*, *configure*, *unconfigure*.

**-h**
:   Print a brief help message and exit.

**-H**
:   Show the manpage for **confman**.

**-i**
:   Install the selected packages.

**-I**
:   Install and configure the selected packages. Implies both the **-i** and **-s** options.

**-l**
:   List and show information about selected packages.

**-L** *log_lvl*
:   Produce a formatted log output using the operands as message then exit. This is option is useful in user scripts (see *FILES*) to output confman-themed log messages. Option argument *log_lvl* designates the nature of the log message and shall have of the following values: *info*, *success*, *warning*, *error*. *warning* and *error* messages are directed to stderr but **confman** will exit with status 0 if these messages are output successfully.

**-u**
:   Uninstall the selected packages. Package configurations are NOT implicitly removed.

**-U**
:   Uninstall and remove configuration for the selected packages.

**-v**
:   Print version information and exit.

**-x**
:   Remove configuration for the selected packages.

## Configuration
**-b**
:   Operate in bootstrap mode. The directory containing the **confman** executable will be prepended to the PATH variable in the environment of the **confman** process. This value of PATH would be inherited by child processes including user scripts (see FILES). This would allow user scripts which invoke **confman** with options **-D** and **-L** to locate the executable even when it has not been installed permanently on the local host.

**-d** *config_dest*
:   Specify the destination where symlinks of package data and configuration files are created at by the default package configuration operation. The value of *config_dest* overrides that of the CONFMAN_DEST variable (see *ENVIRONMENT*), and would be assigned to it if valid. If neither *config_dest* nor CONFMAN_DEST are specified, the value of the HOME environment variable is used by default.

**-f** *pkg_list*
:   Read newline-separated package names from file *pkg_list* and add them to the list of selected packages.

**-g** *config_repo*
:   Specify the directory corresponding to the package configurations repository. The value of *config_repo* overrides that of the CONFMAN_REPO variable (see *ENVIRONMENT*), and would be assigned to it if valid. If neither *config_repo* nor CONFMAN_REPO are specified, *packages/* within the parent directory of the **confman** executable is used by default. The repository shall contain a child directory for each package that could be provided to **confman** as a selected package. Such a directory must have the same name as its associated package, and may contain custom installation scripts, configuration scripts, and data (see **FILES**). Its value is overriden by that of option **-g**'s argument if the latter is specified

**-m** *pkg_mgr*
:   The back-end package manager to use for installation and uninstallation. Can be an absolute path to an executable or a program name if it can be found in PATH. If both this option and the CONFMAN_MGR variable (see *ENVIRONMENT*) are set when this program is invoked, the value of the option argument *pkg_mgr* overrides that of the variable, and CONFMAN_MGR will be reassigned to the value of *pkg_mgr*. If both are not provided when this program is invoked, **confman** will automatically attempt to select and use an appropriate package manager command, which is then assigned to CONFMAN_MGR.

    **confman** sets the *export* variable attribute on CONFMAN_MGR, therefore this variable is available in the execution environment of package-specific custom scripts (see *FILES*).

**-p** *prompt_lvl*
:   Set the amount/level of prompts presented by **confman**. The argument *prompt_lvl* may be one of three values: *0*, *1*, or *2*. If *0* is specified, no prompt or interactive inquiry is generated for all default operations performed by **confman**. If *1* is specified, minimal prompting is presented (default behaviour). For example, a prompt is presented to validate the set of packages on which to perform certain actions. If *2* is specified, extensive prompting is enable for default operations. In which case, a confirmation prompt is presented before any operation is performed by the selected back-end package manager for every target package. Any invalid value of *prompt_lvl* is ignored.

    If a valid value of *prompt_lvl* is specified, it is assigned to the variable CONFMAN_PROMPT. If both the **-p** option and the CONFMAN_PROMPT variable is set when this program is invoked, a valid value of *prompt_lvl* overrides the value of the variable. Since **confman** sets the *export* variable attribute on CONFMAN_PROMPT, this variable is available in the execution environment of package-specific custom scripts (see *FILES*).

# ENVIRONMENT
**confman** sets the *export* attribute on the following shell variables, therefore these are available in the execution environment of package-specific custom scripts (see *FILES*) when such scripts are invoked by **confman**.

PKG
:   The name of the package currently being processed by **confman**.

CONFMAN_DEST
:   The destination where symlinks of package data and configuration files are created at by the default package configuration operation. By default, it is set to the value of the HOME environment variable. Its value is overriden by that of option **-d**'s argument if the latter is specified.

CONFMAN_MGR
:   The back-end package manager to use for installation and uninstallation. Can be an absolute path to an executable or a program name if it can be found in PATH. Its value is overriden by that of option **-m**'s argument if the latter is specified. If both this variable and the **-m** option are not provided when this program is invoked, **confman** will automatically attempt to select and use an appropriate package manager command, which is then assigned to CONFMAN_MGR.

CONFMAN_REPO
:   The directory corresponding to the package configurations repository. By default, it is set to *packages/* within the parent directory of the **confman** executable. Its value is overriden by that of option **-g**'s argument if the latter is specified. The repository shall contain a child directory for each package that could be provided to **confman** as a selected package. Such a directory must have the same name as its associated package, and may contain custom installation scripts, configuration scripts, and data (see **FILES**). Its value is overriden by that of option **-g**'s argument if the latter is specified

CONFMAN_PROMPT
:   The amount/level of prompts presented by **confman**. It may take one of three values: *0*, *1*, or *2*. If set to *0*, no prompt or interactive inquiry is generated for all default operations performed by **confman**. If set to *1* (the default value), minimal prompting is presented. For example, a prompt is presented to validate the set of packages on which to perform certain actions. If set to *2*, extensive prompting is enable for default operations. In which case, a confirmation prompt is presented before any operation is performed by the selected back-end package manager for every target package. Any invalid value is replaced with *1*.

    If the option **-p** is specified and has a valid argument *prompt_lvl*, it overrides the value set for this variable. CONFMAN_PROMPT would then be reassigned to the value of *prompt_lvl*.

# FILES
*\<pkg_conf_root\>/*
:   Each directory immediately below the package configurations repository (path given by the environment variable CONFMAN_REPO or the argument to option **-r**) shall be associated with a package and may contain installation and configuration scripts, as well as configuration data for that package. The name of such a directory *MUST* match the name of a package that could be provided to **confman** as a selected package. Furthermore, during the default installation and uninstallation operations, this name is provided as the target to the selected package manager (see option **-m**). If this name cannot be reliably used as the target for all supported package managers, then custom installation scripts (see below) should be created.

*\<pkg_conf_root\>/data/*
:   Optional. Directory which contains package configuration files and data. If setup scripts (see below) for the associated package are not provided, by default when the package is set up / configured, all files within this directory are symlinked to the location specified by the CONFMAN_DEST environment variable. Similarly, if setup scripts for the associated package are not provided, by default when the package configuration is removed by **confman**, those symlinks are removed.

*\<pkg_conf_root\>/platform*
:   Optional. If this file exists, its content shall be a newline-separated list of case insensitive BRE patterns that may match any part of the *uname -s* command's output on platforms/operating systems for which the package is compatible with. Packages which designate such a platform compatibility list will *ONLY* be subject to any operation on its supported platforms.

*\<pkg_conf_root\>/noinstall*
:   Optional. If this file exists, installation for this package is ALWAYS skipped.

*\<pkg_conf_root\>/preinstall*
:   Optional. Pre-installation script that is executed before its associated package undergoes default installation, or before the *\<pkg_conf_root\>/install* script if it exists.

*\<pkg_conf_root\>/install*
:   Optional. Installation script that replaces the default package installation operation. The default package installation operation simply involves installing a selected package using the selected package manager.

*\<pkg_conf_root\>/postinstall*
:   Optional. Post-installation script that is executed after its associated package undergoes default installation, or after the *\<pkg_conf_root\>/install* script if it exists.

*\<pkg_conf_root\>/uninstall*
:   Optional. Uninstallation script that replaces the default package uninstallation operation. The default package uninstallation operation simply involves uninstalling a selected package using the selected package manager.

*\<pkg_conf_root\>/noconfigure*
:   Optional. If this file exists, setup / configuration for this package is ALWAYS skipped.

*\<pkg_conf_root\>/preconfigure*
:   Optional. Pre-configuration script that is executed before its associated packages undergoes default setup / configuration, or before the *\<pkg_conf_root\>/setup* script if it exists.

*\<pkg_conf_root\>/configure*
:   Optional. Configuration script that replaces the default package setup / configuration operation (see *\<pkg_conf_root\>/data/* above).

*\<pkg_conf_root\>/postconfigure*
:   Optional. Post-configuration script that is executed after its associated packages undergoes default setup / configuration, or after the *\<pkg_conf_root\>/setup* script if it exists.

*\<pkg_conf_root\>/unconfigure*
:   Optional. Configuration removal script that replaces the default package configuration removal operation (see *\<pkg_conf_root\>/data/* above).

# NOTES
A valid package name shall not consist strictly of whitespace characters as defined by the **space** character class of the shell environment locale. A valid package name shall also not contain any occurance of the \<newline\> character which is reserved for use as a delimiter by **confman**.

To be recognizable / selectable by **confman**, each *package* specified as command operand, or specified within a *pkg_list* file as required by the **-f** option, must have an associated sub-directory of the same name within the targeted package repository (see variable CONFMAN_REPO).

