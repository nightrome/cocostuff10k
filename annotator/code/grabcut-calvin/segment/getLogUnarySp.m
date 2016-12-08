function U = getLogUnarySp(sp_stats,varargin)
% TODO: do not just duplicate over pixels.

U = cellcat(4,varargin);
U = -log(U);
U = sum(U,4);
U = reshape(U,[],2);
U = bsxfun(@times,U,sp_stats.n);
U = sparse(U);

