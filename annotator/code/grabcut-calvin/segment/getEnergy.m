function energy = getEnergy(A,T,labels)

energy = 0;
energy = energy + sum(T(labels==0,2));
energy = energy + sum(T(labels==1,1));
energy = energy + sum(sum(A(labels==0,labels==1)));


