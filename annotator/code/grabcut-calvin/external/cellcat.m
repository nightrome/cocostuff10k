function c = cellcat(d,c)
% Concatenates the elements of a cell c following dimension d.

c = cat(d,c{:});
