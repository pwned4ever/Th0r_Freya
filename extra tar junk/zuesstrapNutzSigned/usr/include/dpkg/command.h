/*
 * libdpkg - Debian packaging suite library routines
 * command.h - command execution support
 *
 * Copyright © 2010, 2012, 2015 Guillem Jover <guillem@debian.org>
 *
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef LIBDPKG_COMMAND_H
#define LIBDPKG_COMMAND_H

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup command Command execution
 * @ingroup dpkg-internal
 * @{
 */

/**
 * Describe a command to execute.
 */
struct command {
	/** Descriptive name of the command, used when printing. */
	const char *name;
	/** Filename to execute; either a path or the progname. */
	const char *filename;
	int argc;
	int argv_size;
	const char **argv;
};

void command_init(struct command *cmd, const char *filename, const char *name);
void command_destroy(struct command *cmd);

void command_add_arg(struct command *cmd, const char *arg);
void command_add_argl(struct command *cmd, const char **argv);
void command_add_argv(struct command *cmd, va_list args);
void command_add_args(struct command *cmd, ...) DPKG_ATTR_SENTINEL;

void command_exec(struct command *cmd) DPKG_ATTR_NORET;

void command_shell(const char *cmd, const char *name) DPKG_ATTR_NORET;

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_COMMAND_H */
