# libhelper

Library for assisting my other projects. Includes / will include support for parsing ASN1 and MachO files, reading and writing files, an error system etc.

libhelper is designed for my own projects, but can easily be used by anyone else. It's design is modular, so add as a git submodule and compile whatever parts are required for your project.

Any issues tweet @h3adsh0tzz, or submit an issue and i'll get back to you!

## Mach-O

Currently, the main feature of libhelper is the Mach-O handling and parsing. The code for the parser can be found at `src/macho` and the `tests/main.c` file has testing for whatever part I'm currently working on.

I'll update this file gradually with documentation as the lib becomes more stable, as at the moment I'm changing things often.