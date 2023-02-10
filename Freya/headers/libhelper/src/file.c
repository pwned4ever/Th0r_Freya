//===---------------------------- file -----------------------------===//
//
//                        The Libhelper Project
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  Copyright (C) 2019, Is This On?, @h3adsh0tzz
//  me@h3adsh0tzz.com.
//
//
//===------------------------------------------------------------------===//

#include "libhelper/file.h"


file_t *file_create ()
{
	file_t *file = malloc (sizeof (file_t));
	memset (file, '\0', sizeof (file_t));
	return file;
}


file_t *file_load (const char *path)
{
	/* Create the new file structure */
	file_t *file = file_create ();

	/* Set the file path */
	if (!path) {
		errorf ("File path not valid.\n");
		return NULL;
	}
	file->path = (char *) path;

	/* Load the file */
	file->desc = fopen (file->path, "rb");
	if (!file->desc) {
		errorf ("File could not be loaded.\n");
		return NULL;
	}

	/* Calculate the size of the file */
	fseek (file->desc, 0, SEEK_END);
	file->size = ftell (file->desc);
	fseek (file->desc, 0, SEEK_SET);

	/* Return the file */
	return file;
}


void file_close (file_t *file)
{
	fclose (file->desc);
	file_free (file);
}


void file_free (file_t *file)
{
	file = NULL;
	free (file);
}


int file_write_new (char *filename, unsigned char *buf, size_t size)
{
	FILE *f = fopen (filename, "wb");
	if (!f)
		return LH_FILE_FAILURE;
	
	size_t res = fwrite (buf, sizeof (char), size, f);
	fclose (f);

	return res;
}


char *file_load_bytes (file_t *f, size_t size, uint32_t offset)
{
	char *buf = malloc (size);

	fseek (f->desc, offset, SEEK_SET);
	fread (buf, size, 1, f->desc);

	return buf;
}