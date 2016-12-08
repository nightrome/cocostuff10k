function [seg,flow,energy] = getSegmentation(P,U,w,h)

[flow,labels] = maxflow(50*P,50*U);
seg = reshape(labels==1,h,w);
energy = getEnergy(P,U,labels);

