import os
import scipy.ndimage
import scipy.misc

# Specify folders
tgt_size = 513
image_src = 'cocostuff/data/annotations'
image_tgt = 'cocostuff/data/annotations' + str(tgt_size)

# Create output folder
if not os.path.exists(image_tgt):
    os.makedirs(image_tgt)

# Find image files
for file in os.listdir(image_src):
    image_path_src = os.path.join(image_src, file)
    image_path_tgt = os.path.join(image_tgt, file)
    image = scipy.ndimage.imread(image_path_src)
    image_out = scipy.misc.imresize(image, (513, 513), 'nearest')
    scipy.misc.imsave(image_path_tgt, image_out)
    print(file)
