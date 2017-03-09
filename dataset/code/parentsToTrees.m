function[nodes, categories, heights] = parentsToTrees(parents)
% [nodes, categories, heights] = parentsToTrees(parents)
%
% Converts an [s x 2] dimensional cell of strings into a tree where the
% first column indicates nodes and the second column indicates their parent
% nodes.
%
% The output can be plotted using Matlab's treeplot function:
% treeplot(nodes');
% [xs, ys] = treelayout(nodes);
%
% Copyright by Holger Caesar, 2016

% Extract categories and make sure they are unique
categories = parents(:, 1);
assert(numel(categories) == numel(unique(categories)));

% Create pointers to parent nodes
categoryCount = size(categories, 1);
nodes = nan(categoryCount, 1);
heights = nan(categoryCount, 1);
nodes(1) = 0;
heights(1) = 0;
for i = 2 : categoryCount
    childNode = find(strcmp(parents(:, 1), categories{i}));
    if isempty(childNode)
        error('Error: No parent node found for %s!', categories{i});
    end
    parentNode = find(strcmp(categories, parents(childNode, 2)));
    assert(numel(parentNode) == 1, 'Error: Node %s has %d labels! Should be 1.', parents{childNode, 2}, numel(parentNode));
    nodes(i) = parentNode;
    heights(i) = heights(parentNode) + 1;
end