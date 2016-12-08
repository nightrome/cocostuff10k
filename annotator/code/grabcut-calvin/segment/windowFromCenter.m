function win = windowFromCenter(h,w,centerInitFrac)
yc = (h+1)/2;
xc = (w+1)/2;
win = [ round(xc-centerInitFrac*w/2) round(yc-centerInitFrac*h/2) ...
    round(xc+centerInitFrac*w/2) round(yc+centerInitFrac*h/2)];


