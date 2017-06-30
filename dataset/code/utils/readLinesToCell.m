function[fileContent] = readLinesToCell(filePath, splitCols)
% [fileContent] = readLinesToCell(filePath, [splitCols])
%
% Read a text file and convert to cell.
% Each row represents one entry.
% If splitOnComma is true, the file will be treated like a csv with element
% separator ',' and line separator '\n'.
%
% Copyright by Holger Caesar, 2014

% Default arguments
if ~exist('splitCols', 'var')
    splitCols = false;
end
rowDelim = '\n';
colDelim = ' ';

% Check if file exists
assert(exist(filePath, 'file') ~= 0, 'Error: File does not exist: %s', filePath);

% Read input file
fid = fopen(filePath, 'r');
fileContent = textscan(fid, '%s', 'Delimiter', {rowDelim});
fclose(fid);

% Unpack
fileContent = fileContent{1};

% Remove leading and trailing spaces
fileContent = strtrim(fileContent);

% Split further
if splitCols
    % Split each line
    fileContent = cellfun(@(x) strsplit(x, colDelim), fileContent, 'UniformOutput', false);
    
    % Rearrange to correct width and height and convert to number
    fileContent = str2double(cat(1, fileContent{:}));
end