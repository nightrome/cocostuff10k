function[path] = filePathRemoveFolder(path)
% [path] = filePathRemoveFolder(path)
%
% Removes the folder from a file path to have just the name of the file.
% Folders will be reduced to empty strings.
%
% Copyright by Holger Caesar, 2014

delims = strfind(path, filesep);
if iscell(path),
    % For cells
    empties = find(cellfun(@isempty, delims));
    delims(empties) = repmat({1}, [numel(empties), 1]);
    path = cellfun(@(x, y) x(y(end)+1:end), path, delims, 'UniformOutput', false);
else
    % For strings
    if isempty(delims),
        path = '';
    else
        path = path(delims(end)+1:end);
    end;
end;