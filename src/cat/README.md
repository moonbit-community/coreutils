# cat

## specification

The Open Group Base Specifications Issue 8
IEEE Std 1003.1-2024
Copyright © 2001-2024 The IEEE and The Open Group

<https://pubs.opengroup.org/onlinepubs/9799919799/utilities/cat.html>

```txt
cat [-u] [file...]

The cat utility shall conform to XBD 12.2 Utility Syntax Guidelines .

The following option shall be supported:

-u
    Write bytes from the input file to the standard output without delay as each is read.

file
    A pathname of an input file. If no file operands are specified, the standard input shall be used. If a file is '-', the cat utility shall read from the standard input at that point in the sequence. The cat utility shall not close and reopen standard input when it is referenced in this way, but shall accept multiple occurrences of '-' as a file operand.

The standard input shall be used only if no file operands are specified, or if a file operand is '-'. See the INPUT FILES section.
```
