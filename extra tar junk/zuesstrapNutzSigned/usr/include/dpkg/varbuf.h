/*
 * libdpkg - Debian packaging suite library routines
 * varbuf.h - variable length expandable buffer handling
 *
 * Copyright © 1994, 1995 Ian Jackson <ijackson@chiark.greenend.org.uk>
 * Copyright © 2008-2015 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_VARBUF_H
#define LIBDPKG_VARBUF_H

#include <stddef.h>
#include <stdarg.h>
#include <string.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup varbuf Variable length buffers
 * @ingroup dpkg-public
 * @{
 */

/**
 * varbuf_init must be called exactly once before the use of each varbuf
 * (including before any call to varbuf_destroy), or the variable must be
 * initialized with VARBUF_INIT.
 *
 * However, varbufs allocated ‘static’ are properly initialized anyway and
 * do not need varbuf_init; multiple consecutive calls to varbuf_init before
 * any use are allowed.
 *
 * varbuf_destroy must be called after a varbuf is finished with, if anything
 * other than varbuf_init has been done. After this you are allowed but
 * not required to call varbuf_init again if you want to start using the
 * varbuf again.
 *
 * Callers using C++ need not worry about any of this.
 */
struct varbuf {
	size_t used, size;
	char *buf;

#ifdef __cplusplus
	varbuf(size_t _size = 0);
	~varbuf();
	void init(size_t _size = 0);
	void reset();
	void destroy();
	int fmt(const char *_fmt, ...) DPKG_ATTR_PRINTF(2);
	int vfmt(const char *_fmt, va_list va) DPKG_ATTR_VPRINTF(2);
	void operator()(int c);
	void operator()(const char *s);
	const char *string();
#endif
};

#define VARBUF_INIT { 0, 0, NULL }

struct varbuf *varbuf_new(size_t size);
void varbuf_init(struct varbuf *v, size_t size);
void varbuf_grow(struct varbuf *v, size_t need_size);
void varbuf_trunc(struct varbuf *v, size_t used_size);
char *varbuf_detach(struct varbuf *v);
void varbuf_reset(struct varbuf *v);
void varbuf_destroy(struct varbuf *v);
void varbuf_free(struct varbuf *v);

void varbuf_add_char(struct varbuf *v, int c);
void varbuf_dup_char(struct varbuf *v, int c, size_t n);
void varbuf_map_char(struct varbuf *v, int c_src, int c_dst);
#define varbuf_add_str(v, s) varbuf_add_buf(v, s, strlen(s))
void varbuf_add_buf(struct varbuf *v, const void *s, size_t size);
void varbuf_end_str(struct varbuf *v);
const char *varbuf_get_str(struct varbuf *v);

int varbuf_printf(struct varbuf *v, const char *fmt, ...) DPKG_ATTR_PRINTF(2);
int varbuf_vprintf(struct varbuf *v, const char *fmt, va_list va)
	DPKG_ATTR_VPRINTF(2);

struct varbuf_state {
	size_t used;
};

void varbuf_snapshot(struct varbuf *v, struct varbuf_state *vs);
void varbuf_rollback(struct varbuf *v, struct varbuf_state *vs);

/** @} */

DPKG_END_DECLS

#ifdef __cplusplus
inline
varbuf::varbuf(size_t _size)
{
	varbuf_init(this, _size);
}

inline
varbuf::~varbuf()
{
	varbuf_destroy(this);
}

inline void
varbuf::init(size_t _size)
{
	varbuf_init(this, _size);
}

inline void
varbuf::reset()
{
	used = 0;
}

inline void
varbuf::destroy()
{
	varbuf_destroy(this);
}

inline int
varbuf::fmt(const char *_fmt, ...)
{
	va_list args;
	int rc;

	va_start(args, _fmt);
	rc = varbuf_vprintf(this, _fmt, args);
	va_end(args);

	return rc;
}

inline int
varbuf::vfmt(const char *_fmt, va_list va)
{
	return varbuf_vprintf(this, _fmt, va);
}

inline void
varbuf::operator()(int c)
{
	varbuf_add_char(this, c);
}

inline void
varbuf::operator()(const char *s)
{
	varbuf_add_str(this, s);
}

inline const char *
varbuf::string()
{
	return varbuf_get_str(this);
}
#endif

#endif /* LIBDPKG_VARBUF_H */
