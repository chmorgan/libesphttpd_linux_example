# Introduction

An example of how you can build and run the libesphttpd http server under Linux.

# Why?

To provide a way to run Linux analysis tools against a libesphttpd server.

# Building

$ git submodule init
$ git submodule update
$ cd libesphttpd
$ git submodule init
$ git submodule update
$ cd ../
$ mkdir build
$ cd build
$ cmake ../
$ make

# Running

$ ./install/bin/httpd
