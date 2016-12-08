
function y=flatten(x,k)
y=cellcat(1,cellfun2(@(z) reshape(z,[],k),x));


