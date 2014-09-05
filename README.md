CQLCL
=====

A Common Lisp client to Cassandra using the native protocol (V2)

Installation
============
[QuickLisp](http://quicklisp.org) is probably the most sane way to
install CL libraries. Ensure you have this set up and working.


```shell
cd $QUICKLISP_HOME/local-projects
git clone https://github.com/AeroNotix/cqlcl.git
sbcl --eval "(ql:quickload :cqlcl)"
```

This will install all required dependencies.

Status
------

Supports making connections and executing synchronous queries. Most
types are implemented but not the collection column types.

Preparing queries works, but not executing prepared statements.
