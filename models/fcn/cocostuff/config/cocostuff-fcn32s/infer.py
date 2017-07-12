import numpy as np
from PIL import Image

import caffe
import scipy.io # for mat files
import os

# Settings
save_folder = 'cocostuff/features/'

# Create save folder
if not os.path.exists(save_folder):
    os.makedirs(save_folder)

# load image, switch to BGR, subtract mean, and make dims C x H x W for Caffe
image_name = 'COCO_train2014_000000000113'
im = Image.open('cocostuff/data/images/' + image_name + '.jpg')
in_ = np.array(im, dtype=np.float32)
in_ = in_[:,:,::-1]
in_ -= np.array((104.00698793,116.66876762,122.67891434))
in_ = in_.transpose((2,0,1))

# load net
net = caffe.Net('cocostuff/config/cocostuff-fcn32s/val.prototxt', 'cocostuff/bak.model/fcn32s_iter_56000.caffemodel', caffe.TEST)

# shape for input (data blob is N x C x H x W), set data
net.blobs['data'].reshape(1, *in_.shape)
net.blobs['data'].data[...] = in_

# run net and take argmax for prediction
net.forward()
out = net.blobs['score'].data[0].argmax(axis=0)

# save to disk
import pdb; pdb.set_trace()
scipy.io.savemat(save_folder + image_name, mdict={'data': out})


