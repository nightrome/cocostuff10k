function[root] = cocoStuff_root()
% [root] = cocoStuff_root()
%
% Returns the absolute path to the root directory of COCO-Stuff.
%
% Copyright by Holger Caesar, 2016

root = fileparts(fileparts(mfilename('fullpath')));