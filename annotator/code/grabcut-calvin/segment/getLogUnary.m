function U = getLogUnary(varargin)

U = cellcat(4,varargin);
U = -log(U);
U = sum(U,4);
U = reshape(U,[],2);
U = sparse(U);

