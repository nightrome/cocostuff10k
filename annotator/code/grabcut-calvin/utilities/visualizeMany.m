function visualizeMany(img,mask,threshold,seg,iteration,energies)

clf();
viz = mg_map(@(x,y) mg_sp_label2image(x,y,'thickborder'),img(:),seg(:));
mg_imshow(viz);

drawnow();

