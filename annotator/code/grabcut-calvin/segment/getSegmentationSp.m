function [seg,flow,energy] = getSegmentationSp(P,U)

[flow,labels] = maxflow(50*P,50*U);
seg = labels==1;
energy = getEnergy(P,U,labels);

