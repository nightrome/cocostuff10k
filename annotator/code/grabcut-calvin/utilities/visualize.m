function visualize(img,initfg,seg,iteration,energies)

clf();

subplot2d(2,3,1,1);
plot_image(img,'image');

%subplot2d(2,3,1,2);
%plot_image(mg_sp_label2image(img,sp),'superpixels');

subplot2d(2,3,1,3);
plot_image(reshape(initfg,size(img(:,:,1))),'init');

pixseg = seg;

subplot2d(2,3,2,1);
plot_image(im2double(img).*repmat(double(pixseg),[1 1 3]),'foreground');

subplot2d(2,3,2,2);
plot_image(pixseg,'segmentation');

subplot2d(2,3,2,3);
plot(energies);
title('convergence');
ylabel('energy');
xlabel('iteration');

drawnow();

