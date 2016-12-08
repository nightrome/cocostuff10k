function[cellArray] = flattenCellArray(cellArray)
% [cellArray] = flattenCellArray(cellArray)
%
% Flattens a cell array of cell arrays into a simple cell array.
%
% Copyright by Holger Caesar, 2014

cellArray = cat(1, cellArray{:});