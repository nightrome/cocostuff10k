function flow = maxflow_test2()

% TEST2 Demonstrates gradient-based image
%   min-cut partitioning.
%
%   (c) 2008 Michael Rubinstein, WDI R&D and IDC
%   $Revision: 140 $
%   $Date: 2008-09-15 15:35:01 -0700 (Mon, 15 Sep 2008) $
%

im = imread('waterfall.bmp');

m = double(rgb2gray(im));
[height,width] = size(m);

disp('building graph');
N = height*width;

% construct graph
E = maxflow_edges4connected(height,width);
V = abs(m(E(:,1))-m(E(:,2)))+eps;
A = sparse(E(:,1),E(:,2),V,N,N,4*N);

% terminal weights
% connect source to leftmost column.
% connect rightmost column to target.
T = sparse([1:height;N-height+1:N]',[ones(height,1);ones(height,1)*2],ones(2*height,1)*9e9);

disp('calculating maximum flow');

[flow,labels] = maxflow(A,T);
labels = reshape(labels,[height width]);

imagesc(labels); title('labels');

