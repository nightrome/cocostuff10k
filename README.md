# COCO-Stuff dataset v1.0 (unreleased)
## Holger Caesar, Jasper Uijlings, Vittorio Ferrari

## Overview
Welcome to this release of the COCO-Stuff [1] dataset. COCO-Stuff augments the popular COCO [2] dataset with pixel-level stuff annotations. These annotations can be used for scene understanding tasks like semantic segmentation, object detection and image captioning.

## Highlights
- 10,000 complex images from [2]
- Dense pixel-level annotations
- 80 thing and 91 stuff classes
- Instance-level annotations for things from [2]
- Complex spatial context between stuff and things
- 5 captions per image from [2]

## Dataset

Filename		Description									Size
cocostuff-v1.0.zip	COCO-Stuff dataset version 1.0, including images, annotations and code examples	2.6 GB
cocostuff-readme.txt	Text version of this document							3.3 KB

## Usage
To use the COCO-Stuff dataset, please follow these steps:
- Download the dataset
- Run the file code/demo_cocoStuff.m in Matlab
- You will see an image, its thing, stuff and thing+stuff annotations, as well as the image captions.

## File format
The COCO-Stuff annotations are stored in separate .mat files per image. These files follow the same format as used by Tighe et al.. Each file contains the following fields:
- S: The pixel-wise label map of size [height x width]. For use in Matlab all label indices start from 1
- names: The names of the 172 classes in COCO-Stuff. 1 is the class 'unlabeled', 2-81 are things and 82-172 are stuff classes.
- captions: Image captions from [2] that are annotated by 5 distinct humans on average.
- regionMapStuff: A map of the same size as S that contains the indices for the approx. 1000 regions (superpixels) used to annotate the image.
- regionLabelsStuff: A list of the stuff labels for each superpixel. The indices in regionMapStuff correspond to the entries in regionLabelsStuff.

## Semantic segmentation models (coming soon)
To encourage further research of stuff and things we provide trained semantic segmentation models for several state-of-the-art methods (see Sect. 4.4 in [1]).
Filename			Description						Size
cocostuff-fcn.zip [TODO]	FCN [3] model for Matconvnet-Calvin			[TODO]
cocostuff-deeplab.zip [TODO]	DeepLab [4] model for deeplab-public-ver2 and Caffe	[TODO]

## Contact
If you have any questions regarding this dataset, please contact us at holger.caesar-at-ed.ac.uk.

## Licensing
COCO-Stuff is a derivative work of the COCO dataset. The authors of COCO do not in any form endorse this work. Different licenses apply:
- COCO images: Flickr Terms of use
- COCO annotations: Creative Commons Attribution 4.0 License
- COCO-Stuff annotations & code: Creative Commons Attribution 4.0 License

## References
1) COCO-Stuff: Thing and Stuff Classes in Context [TODO]
H. Caesar, J. Uijlings, V. Ferrari,
In arXiv preprint arXiv:1506.xxx, 2016.

2) Microsoft COCO: Common Objects in Context
T.-Y. Lin, M. Maire, S. Belongie et al.,
In European Conference in Computer Vision (ECCV), 2014.

3) Fully convolutional networks for semantic segmentation
J. Long, E. Shelhammer and T. Darrell,
in Computer Vision and Pattern Recognition (CVPR), 2015.

4) Semantic image segmentation with deep convolutional nets and fully connected CRFs
L.-C. Chen, G. Papandreou, I. Kokkinos, K. Murphy and A. L. Yuille,
In International Conference on Learning Representations (ICLR), 2015.
