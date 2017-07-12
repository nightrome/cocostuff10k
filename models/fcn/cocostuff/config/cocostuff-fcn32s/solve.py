import caffe
import surgery, score

import numpy as np
import os
import sys

try:
    import setproctitle
    setproctitle.setproctitle(os.path.basename(os.getcwd()))
except:
    pass

base_proto = 'fcn/ilsvrc-nets/vgg16-fcn.prototxt'
base_weights = 'fcn/ilsvrc-nets/vgg16-fcn.caffemodel'
base_net = caffe.Net(base_proto, base_weights, caffe.TEST)

# init
caffe.set_device(int(sys.argv[1]))
caffe.set_mode_gpu()

solver = caffe.SGDSolver('cocostuff/config/cocostuff-fcn32s/solver.prototxt')
surgery.transplant(solver.net, base_net)

# surgeries
interp_layers = [k for k in solver.net.params.keys() if 'up' in k]
surgery.interp(solver.net, interp_layers)

# scoring
val = np.loadtxt('cocostuff/list/val.txt', dtype=str)

for _ in range(75):
    solver.step(4000)
    score.seg_tests(solver, False, val, layer='score')
