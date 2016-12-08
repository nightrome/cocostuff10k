function initfg = maskFromCenter(h,w,centerInitFrac)
initfg = false(h,w);
yc = (h+1)/2;  xc = (w+1)/2;
yr = round(yc-centerInitFrac*h/2):round(yc+centerInitFrac*h/2);
xr = round(xc-centerInitFrac*w/2):round(xc+centerInitFrac*w/2);
initfg(yr,xr) = true;

