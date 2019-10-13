## 3DS devkitARM C development template

**Note: this repo isn't quite ready yet. It still needs some minor fixes and testing.**

This is a template for developing new 3DS games and applications in C. It's based on the standard template from [devkitPro](https://devkitpro.org/) with a number of changes. The following features are included:

* Project configuration via `project.cfg`
* Builds `3dsx`, `elf`, `smdh` and `cia` files
* Support for RomFS
* Generates a C file with build-time information such as the Git repo state (for easy version indication)
* Testing commands (for [Citra](https://citra-emu.org/) and real hardware)

### Template structure

This file structure has been kept as simple as possible. A brief overview:

* `assets/` - icon and banner files, plus some build-related files
* `source/` - all project source code
* `romfs/` - contents of the read-only ROM filesystem
* `target/` - all output files such as `3dsx` and `cia` *(created on build)*
* `tmp/` - temporary files used during the build process *(created on build)*
* `project.cfg` - project metadata and configuration

The source directory contains some very basic examples and the generated `version.c` file ([see below]()).

### `project.cfg` file

The `project.cfg` file contains your project's metadata, such as its title, author name and release date. The `cfg` filetype was chosen since it's easy to parse and manually edit.

To run the makefile, the following items are **required** to be specified: `title`, `code`, `cia_id`, `cia_audio`, `cia_banner`, `cia_icon`.

Check if your **CIA ID** (also called **title ID**) and **product code** aren't already in use through the [3DS DB](http://www.3dsdb.com/) website. The CIA ID is 6-digit hexadecimal number, and a product code usually contains "CTR" and a 4-length alphanumeric string (like our default value of `CTR-APPT`). Accidentally reusing a code will cause the other program to be removed when installing.

### Building the project

To build, all you need to do is run **`make`**. This will generate all target files, including `3dsx` ([Homebrew Launcher](https://github.com/fincs/new-hbmenu) executable) and `cia` (installable app via [FBI](https://github.com/Steveice10/FBI) under [Luma3DS](https://github.com/AuroraWright/Luma3DS/wiki); this will show up on your 3DS's home screen). The script will check whether you have all necessary prerequisites installed.

Removing generated files is done with **`make clean`**, as usual.

If you have [Citra](https://citra-emu.org/) installed, running **`make test`** will run it with the generated `3dsx` file for local testing.

For testing on a 3DS, first open the Homebrew Launcher and press Y to listen for network programs. Then run **`make 3ds`** to launch your `3dsx` file on your 3DS.

### Displaying build info in-app

It's useful for your users (especially testers) to be able to see a version indicator in your application for bug reporting and to ensure they're on the latest version.

To this end, the makefile will generate a **`version.c`** file (and its header) containing functions that return version information mostly generated from the Git repository state. The filename can be changed by editing the `VERSION_FN` variable in the makefile.

The version file will contain functions that return a string, such as this:

```c
/** Returns a formatted short version string. */
const char *get_repo_version() {
    return REPO_VERSION;
}
```

The following variables will be passed on to the file as defines:

| Name | Example | Description |
|:-----|:--------|:------------|
| `HASH` | 7e54431 | Build commit hash. |
| `BRANCH` | master | Build commit branch. |
| `COUNT` | 123 | Number of commits preceding this build commit. |
| `DATE` | 2019-06-08 | Build date. |
| `DATETIME` | 2019-06-08 22:26:08 | Build date and time. |
| `BUILDTIME` | 2019-06-08T22:26:27+0200 | ISO 8601 timestamp with timezone of the build date. |
| `UNIXTIME` | 1560025615 | Unix time number of the build date (as a string). |
| `OSINFO` | Linux L1 4.4.0-24-generic … | OS/kernel info string during build time. |
| `VERSION`* | 1.0.0 | Version number set in `project.cfg`. |
| `REPO_VERSION` | 123-master | Formatted short version string. |
| `REPO_LONG_VERSION` | 123-master [7e54431; 2019-06-08] | Formatted full version string. |
| `CFLAGS`* | -march=armv6k -mtune=mpcore … | `CFLAGS` variables used to compile the code. |

Most useful are the preformatted **`APP_REPO_VERSION`** and **`APP_REPO_LONG_VERSION`** variables. The `APP_VERSION` variable is the only one that's passed on from the `project.cfg` file rather than determined by the current commit; you may wish to use this for your own subjective version numbering in any format you like.

Since all information is passed on in the compile command and ends up only in the object file, this file only needs to be generated once and can then be committed to the repository.

### Lua development

If you prefer, it's possible to develop 3DS applications using [Lua](https://en.wikipedia.org/wiki/Lua_(programming_language)) instead. 

Have a look at the **[3DS Lua development template]()** for more information.

### 3DS development resources

* **[3DBrew](https://3dbrew.org/)** - see their guide on [setting up a dev environment](https://3dbrew.org/wiki/Setting_up_Development_Environment)
* **[devkitPro](https://devkitpro.org/)** - the ARM cross compiling toolchain software
* **[libctru](http://smealum.github.io/ctrulib/)** - CTR User Library documentation
    * See their [code example repository](https://github.com/devkitPro/3ds-examples)
* **[m3diaLib-CTR](https://github.com/m3diaLib-Team/m3diaLib-CTR)** - C++ library for easier 3DS homebrew development
* **[GBATEMP](https://gbatemp.net/)** - the largest and most active console hacking and homebrew community
    * See their [forum](https://gbatemp.net/forums/3ds-homebrew-development-and-emulators.275/) and [wiki page on 3DS homebrew development](https://wiki.gbatemp.net/wiki/3DS_Homebrew_Development)

### Copyright

© 2019. [MIT licensed.](https://opensource.org/licenses/MIT)

There's no need to credit this template in anything you make with it.
