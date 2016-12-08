function U = getWeightedLogUnarySp(sp_stat,weights,varargin)
% TODO: do not just multiply by the number of pixel...

U = cellcat(4,varargin);

ii=abs(weights)>eps;
weights = weights(ii);
U = U(:,:,:,ii);

for i=1:length(weights),
    U(:,:,:,i) = U(:,:,:,i)*weights(i);
end
U = sum(U,4);
U = reshape(U,[],2);
U = bsxfun(@times,U,sp_stat.n);
U = sparse(U);

