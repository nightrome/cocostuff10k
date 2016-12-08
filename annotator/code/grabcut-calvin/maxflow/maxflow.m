function [flow,labels] = maxflow(A,T)

%MAXFLOW    Max-flow/min-cut calculation using the
%   Boykov-Kolmogorov's algorithm. Let G=(V,E) be
%   a directed graph with |V| vertices and |E| edges.
%   w:(i,j)-->R, (i,j) in E, a weight function on the graph's
%   edges.
%
%   A (smoothness term) - a sparse matrix of size |V|x|V| containing, where
%   A(i,j) = w(i,j). Typically, for a grid graph, the node 
%   indices would be taken in column-major order, but it is not assumed.
%   T (data term) - a sparse matrix of size |V|x|L|, where |L| is the number
%   of labels (The library currently supports |L|=2 only).
%   T(i,j) = the cost of assigning label j to node i.
%   
%   flow - the calculated maximum flow value
%   labels - a vector of size |V|, where labels(i) is 0 or 1 if
%   node i belongs to S (source) or T (sink) respectively.
%
%   Also refer to the following link for tips on creating large
%   sparse matrices efficiently.
%   In case of a dense adjacency matrix B, simply wrap it in a 
%   sparse structure before passing it to this function:
%   A = sparse(B);
%   [flow,labels] = maxflow(A,T);
%
%   This library can be used for reseatch purposes only, and is
%   supplied with no guarantees.
%
%   (c) 2008 Michael Rubinstein, WDI R&D and IDC
%   $Revision: 140 $
%   $Date: 2008-09-15 15:35:01 -0700 (Mon, 15 Sep 2008) $
%

[flow,labels] = maxflow_mex(A,T);

% release the dll
clear maxflow_mex

end