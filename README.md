# COCO-Stuff dataset v1.0
[Holger Caesar](http://www.it-caesar.com), [Jasper Uijlings](http://homepages.inf.ed.ac.uk/juijling), [Vittorio Ferrari](http://calvin.inf.ed.ac.uk/members/vittoferrari)

## Overview
<img src="http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-examples.png" alt="COCO-Stuff example annotations" width="100%">
Welcome to this release of the COCO-Stuff [1] dataset. COCO-Stuff augments the popular COCO [2] dataset with pixel-level stuff annotations. These annotations can be used for scene understanding tasks like semantic segmentation, object detection and image captioning.

## Highlights
- 10,000 complex images from [2]
- Dense pixel-level annotations
- 80 thing and 91 stuff classes
- Instance-level annotations for things from [2]
- Complex spatial context between stuff and things
- 5 captions per image from [2]

## Dataset

Filename | Description | Size
--- | --- | ---
[cocostuff-dataset-v1.0.zip](http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-dataset-v1.0.zip) | COCO-Stuff dataset version 1.0, including images, annotations and code examples | 2.6 GB
[cocostuff-readme.txt](https://github.com/nightrome/cocostuff/README.md) | This document | 3.3 KB

### Usage
To use the COCO-Stuff dataset, please follow these steps:

1. Download or clone this repository using git: `git clone https://github.com/nightrome/cocostuff.git`
2. Open the dataset folder in your shell: `cd cocostuff`
3. *Either* run the file `dataset/code/downloadData.m` in Matlab *or* download the dataset from [here](http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-data-v1.0.zip) and unpack it into the dataset folder.
4. Run the file dataset/code/demo_cocoStuff.m in Matlab
5. You will see an image, its thing, stuff and thing+stuff annotations, as well as the image captions.

### File format
The COCO-Stuff annotations are stored in separate .mat files per image. These files follow the same format as used by Tighe et al.. Each file contains the following fields:
- *S:* The pixel-wise label map of size [height x width]. For use in Matlab all label indices start from 1
- *names:* The names of the 172 classes in COCO-Stuff. 1 is the class 'unlabeled', 2-81 are things and 82-172 are stuff classes.
- *captions:* Image captions from [2] that are annotated by 5 distinct humans on average.
- *regionMapStuff:* A map of the same size as S that contains the indices for the approx. 1000 regions (superpixels) used to annotate the image.
- *regionLabelsStuff:* A list of the stuff labels for each superpixel. The indices in regionMapStuff correspond to the entries in regionLabelsStuff.

## Semantic segmentation models (coming soon)
To encourage further research of stuff and things we provide trained semantic segmentation models for several state-of-the-art methods (see Sect. 4.4 in [1]).

Filename | Description | Size
--- | --- | ---
[cocostuff-fcn.zip](http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-fcn.zip) [TODO] | FCN [3] model for Matconvnet-Calvin | [TODO]
[cocostuff-deeplab.zip](http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-deeplab.zip) [TODO] | DeepLab [4] model for deeplab-public-ver2 and Caffe | [TODO]

## Contact
If you have any questions regarding this dataset, please contact us at holger.caesar-at-ed.ac.uk.

## Licensing
COCO-Stuff is a derivative work of the COCO dataset. The authors of COCO do not in any form endorse this work. Different licenses apply:
- COCO images: Flickr Terms of use
- COCO annotations: Creative Commons Attribution 4.0 License
- COCO-Stuff annotations & code: Creative Commons Attribution 4.0 License

## References
1. [COCO-Stuff: Thing and Stuff Classes in Context](arxiv) [TODO]<br />
H. Caesar, J. Uijlings, V. Ferrari,<br />
In *arXiv preprint arXiv:1506.xxx*, 2016.<br />

2. [Microsoft COCO: Common Objects in Context](https://arxiv.org/abs/1405.0312)<br />
T.-Y. Lin, M. Maire, S. Belongie et al.,<br />
In *European Conference in Computer Vision* (ECCV), 2014.<br />

3. [Fully convolutional networks for semantic segmentation](http://www.cv-foundation.org/openaccess/content_cvpr_2015/html/Long_Fully_Convolutional_Networks_2015_CVPR_paper.html)<br />
J. Long, E. Shelhammer and T. Darrell,<br />
in *Computer Vision and Pattern Recognition* (CVPR), 2015.<br />

4. [Semantic image segmentation with deep convolutional nets and fully connected CRFs](https://arxiv.org/abs/1412.7062)<br />
L.-C. Chen, G. Papandreou, I. Kokkinos, K. Murphy and A. L. Yuille,<br />
In *International Conference on Learning Representations* (ICLR), 2015.<br />
