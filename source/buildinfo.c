/* This file was automatically generated using 'assets/version_tpl.c' and should not be directly edited. */

/** Returns the build commit hash. */
const char *get_hash() {
    return HASH;
}

/** Returns the build commit branch. */
const char *get_branch() {
    return BRANCH;
}

/** Returns the number of commits preceding this build commit. */
const char *get_count() {
    return COUNT;
}

/** Returns the build date. */
const char *get_date() {
    return DATE;
}

/** Returns the build date and time. */
const char *get_datetime() {
    return DATETIME;
}

/** Returns a Unix time number of the build date (as a string). */
const char *get_unixtime() {
    return UNIXTIME;
}

/** Returns an ISO 8601 timestamp with timezone of the build date. */
const char *get_buildtime() {
    return BUILDTIME;
}

/** Returns OS/kernel info string during build time. */
const char *get_osinfo() {
    return OSINFO;
}

/** Returns the version number set in project.cfg. */
const char *get_version() {
    return VERSION;
}

/** Returns a formatted short version string. */
const char *get_repo_version() {
    return REPO_VERSION;
}

/** Returns a formatted full version string. */
const char *get_repo_long_version() {
    return REPO_LONG_VERSION;
}

/** Returns the CFLAGS variables used to compile the code. */
const char *get_cflags() {
    return CFLAGS;
}

