function plotTree(nodes, cats, subTree, figLabelHierarchy)
% plotTree(nodes, cats, subTree, figLabelHierarchy)
%
% Plot a tree using the results of the CocoStuffClasses.getClassHierarchyX() functions.
%
% subTree: (optional) +-1 for left/right sub tree, 0 for the entire tree
% figLabelHierarchy: (optional) handle to a figure
%
% Copyright by Holger Caesar, 2017

% By default we plot the entire tree
if ~exist('subTree', 'var')
    subTree = 0;
end

% Create figure if necessary
if ~exist('figLabelHierarchy', 'var')
    figLabelHierarchy = figure();
end

% Check that tree is binary at the top node
firstChildren = find(nodes == 1);
assert(numel(firstChildren) == 2);

% Get only relevant nodes and cats
if subTree ~= 0
    % Find descendents of the specified startTreeInd node
    sel = false(size(nodes));
    if subTree == -1
        sel(firstChildren(1)) = true;
    elseif subTree == 1
        sel(firstChildren(2)) = true;
    end
    while true
        oldSel = sel;
        sel = sel | ismember(nodes, find(sel));
        if isequal(sel, oldSel)
            break;
        end
    end
    nodes = nodes(sel);
    cats = cats(sel);
    
    % Remap nodes in 0:x range
    map = false(max(nodes), 1);
    map(unique(nodes)) = true;
    map = cumsum(map)-1;
    nodes = map(nodes);
end

% Plot them
ax = axes('Parent', figLabelHierarchy, 'Units', 'Norm');
axis(ax, 'off');
treeplot(nodes');
moveLeft = 0.08;
if subTree == -1
    set(ax, 'Position', [0-moveLeft,   0, 0.5+moveLeft, 1]);
elseif subTree == 1
    set(ax, 'Position', [0.5-moveLeft, 0, 0.5+moveLeft, 1]);
end
[xs, ys] = treelayout(nodes);

% Set appearance settings and show labels
isLeaf = ys == min(ys);
textInner = text(xs(~isLeaf) + 0.01, ys(~isLeaf) - 0.025, cats(~isLeaf), 'VerticalAlignment', 'Bottom', 'HorizontalAlignment', 'right'); %#ok<NASGU>
textLeaf  = text(xs( isLeaf) - 0.01, ys( isLeaf) - 0.02,  cats( isLeaf), 'VerticalAlignment', 'Bottom', 'HorizontalAlignment', 'left'); %#ok<NASGU>
set(ax, 'XTick', [], 'YTick', [], 'Units', 'Normalized');
ax.XLabel.String = '';

% Rotate view
camroll(90);