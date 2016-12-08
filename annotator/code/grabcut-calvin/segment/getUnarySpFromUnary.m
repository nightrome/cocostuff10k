function V = getUnarySpFromUnary(U,sp,C)
sp=double(sp(:));
U=double(full(U));
V1=sparseFromLabels(sp,C,U(:,1));
V2=sparseFromLabels(sp,C,U(:,2));
V=cat(2,sum(V1,2),sum(V2,2));
%sp = sp(:);
%V = zeros(C,2);
%for i=1:C,
%    idx = sp==i;
%    V(i,:) = sum(U(idx,:),1);
%end
%V = sparse(V);

