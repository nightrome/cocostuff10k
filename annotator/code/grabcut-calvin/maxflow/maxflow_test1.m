function [flow,labels] = maxflow_test1()

% TEST1 Shows how to use the library to compute
%   a minimum cut on the following graph:
%
%                SOURCE
%		       /       \
%		     1/         \2
%		     /      3    \
%		   node0 -----> node1
%		     |   <-----   |
%		     |      4     |
%		     \            /
%		     5\          /6
%		       \        /
%		          SINK
%
%   (c) 2008 Michael Rubinstein, WDI R&D and IDC
%   $Revision: 140 $
%   $Date: 2008-09-15 15:35:01 -0700 (Mon, 15 Sep 2008) $
%

A = sparse(2,2);
A(1,2)=3;
A(2,1)=4;

T = sparse(2,2);
T(1,1)=9;
T(2,1)=2;
T(1,2)=5;
T(2,2)=6;

% T = sparse(T-100);

[flow,labels] = maxflow(A,T)
