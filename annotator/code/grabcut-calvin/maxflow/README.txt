


*** I got it from http://www.mathworks.com/matlabcentral/fileexchange/21310-maxflow



Yuri Boykov's and Vladimir Kolmogorov's work on graph cuts and MRF optimization has been extensively
cited in the academia, and their maximum flow implementation is widely used in computer vision and
image processing research.

This is a MEX library that wraps their code, so that it could be easily accessed from MATLAB, using
a sparse matrix graph representation. Typical usage:

[flow,labels] = maxflow(A,T);

Where A is the (sparse) adjacency matrix representation of the graph (smoothness term), and T contains
the terminal connections (data term). Refer to maxflow.m for further details.

This library currently supports maximum flow calculation for the case of binary partition, based on
their work:

Yuri Boykov and Vladimir Kolmogorov, 'An Experimental Comparison of Min-Cut/Max-Flow Algorithms for
Energy Minimization in Vision', IEEE Transactions on Pattern Analysis and Machine Intelligence, vol.
26, no. 9, pp. 1124-1137, Sept. 2004.

It has been created on a Windows machine and tested with MATLAB R2007a. For licensing reasons, neither 
their code nor the binary distribution of this library are supplied. Boyokov and Kolmogorov's code can 
be downloaded for research purposes, and per the authors discretion, from the following link:

http://vision.csd.uwo.ca/code/

The MEX library can then be built using the supplied make.m script.

Please report any issues.


Future Steps:
=============
1. Extend this wrapper to support reusing of search trees
2. Add support for their multi-label optimization algorithm
Both of these are rather straightforward and I expect to do them in the near future.


Build Instructions:
===================
1. Extract the library to some directory (denote <lib_home>)
2. Place the maxflow source code (downloaded from the link above) under <lib_home>/maxflow-v3.0
directory
3. run make.m
5. Optional: run test1.m test2.m


MEX-related Issues:
===================

Compiling MEX projects from MSVS (already implemented in the supplied solution file):

1) Create a new C++ Win32 console application.
1) Add mexversion.rc from the MATLAB include directory, matlab\extern\include, to the project.
2) Create a .def file with the following text, and add it to the Solution. Note: change myFileName
to
yours.

LIBRARY myFileName
EXPORTS mexFunction

3) Under C/C++ General Additional Include Directories, add matlab\extern\include
4) Under C/C++ Preprocessor properties, add MATLAB_MEX_FILE as a preprocessor definition.
5) Under Linker General Output File, change to .mexw32
6) Under Linker General Additional Library Directories, add matlab\extern\lib\win32\microsoft
7) Under Linker Input Additional Dependencies, add libmx.lib, libmex.lib, and libmat.lib as
additional dependencies.
8) Under Linker Input Module Definition File, add the (.def) file you created.
9) Under General Configuration Type, choose .dll
10) Add more links to includes and libraries that you will need for your program. In my case I also
added
the \include and \lib dependencies for the laser gyroscope.









