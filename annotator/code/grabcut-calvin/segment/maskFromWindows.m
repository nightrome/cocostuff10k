function mask = maskFromWindows(h,w,win)
if size(win,1)==0,
    mask = true(h,w);
else
    mask = false(h,w);
    win = round(win);
    for b=1:size(win,1),
        mask(win(b,2):win(b,4),win(b,1):win(b,3)) = true;
    end
end 

