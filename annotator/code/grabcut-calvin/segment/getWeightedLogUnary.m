function U = getWeightedLogUnary(weights,varargin)

U = cellcat(4,varargin);
for i=1:length(weights),
    U(:,:,:,i) = U(:,:,:,i)*weights(i);
end
U = sum(U,4);
U = reshape(U,[],2);
U = sparse(U);

