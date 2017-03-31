# COCO-Stuff dataset v1.0
[Holger Caesar](http://www.it-caesar.com), [Jasper Uijlings](http://homepages.inf.ed.ac.uk/juijling), [Vittorio Ferrari](http://calvin.inf.ed.ac.uk/members/vittoferrari)

## Overview
<img src="http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-examples.png" alt="COCO-Stuff example annotations" width="100%">
Welcome to this release of the COCO-Stuff [1] dataset. COCO-Stuff augments the popular COCO [2] dataset with pixel-level stuff annotations. These annotations can be used for scene understanding tasks like semantic segmentation, object detection and image captioning.

## Overview
- [Highlights](#highlights)
- [Updates](#updates)
- [Results and Future Plans](#results-and-future-plans)
- [Dataset](#dataset)
- [Semantic Segmentation Models](#semantic-segmentation-models)
- [Annotation Tool](#annotation-tool)
- [Misc](#misc)

## Highlights
- 10,000 complex images from COCO [2]
- Dense pixel-level annotations
- 80 thing and 91 stuff classes
- Instance-level annotations for things from COCO [2]
- Complex spatial context between stuff and things
- 5 captions per image from COCO [2]

## Updates
- 31 Mar 2017: Published annotations in JSON format
- 09 Mar 2017: Added label hierarchy scripts
- 08 Mar 2017: Corrections to table 2 in arXiv paper [1]
- 10 Feb 2017: Added tools extract SLICO superpixels in annotation tool
- 12 Dec 2016: Dataset version 1.0 and arXiv paper [1] released 

## Results and Future Plans
The current release of COCO-Stuff-10K publishes both the training and test annotations and users report their performance individually. We invite users to report their results to us to complement this table. In the near future we will extend COCO-Stuff to the 200K images in COCO 2015 and organize an official challenge where the test annotations will only be known to the organizers.

Method       | Source| Class-average accuracy | Global accuracy | Mean IOU | FW IOU
---          | ---   | ---                    | ---             | ---      | ---
FCN [3]      | [1]   | 34.0%                  | 52.0%           | 22.7%    | -
Deeplab (no CRF) [4] | [1]   | 38.1%          | 57.8%           | 26.9%    | -
OHE + DC + FCN+ |[5] | 45.8%                  | 66.6%           | 34.3%    | 51.2%
W2V + DC + FCN+ |[5] | 45.1%                  | 66.1%           | 34.7%    | 51.0%

## Dataset
Filename | Description | Size
--- | --- | ---
[cocostuff-10k-v1.0.zip](http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-10k-data-v1.0.zip) | COCO-Stuff dataset version 1.0, including images and annotations | 2.6 GB
[cocostuff-10k-v1.1.json](http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-10k-v1.1.json) | (optional, experimental!) COCO-Stuff annotations in JSON format | 62.3 MB
[cocostuff-readme.txt](https://raw.githubusercontent.com/nightrome/cocostuff/master/README.md) | This document | 6.5 KB

### Usage
To use the COCO-Stuff dataset, please follow these steps:

1. Download or clone this repository using git: `git clone https://github.com/nightrome/cocostuff.git`
2. Open the dataset folder in your shell: `cd cocostuff`
3. Download and unzip the dataset:
  - `wget --directory-prefix=downloads http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-data-v1.0.zip`
  - `unzip downloads/cocostuff-data-v1.0.zip -d dataset/`
4. Add the code folder to your Matlab path: `startup();`
5. Run the demo script in Matlab `demo_cocoStuff();`
6. The script displays an image, its thing, stuff and thing+stuff annotations, as well as the image captions.

### JSON Format
Alternatively, we also provide annotations in the [COCO-style JSON format](http://mscoco.org/dataset/#download) above. These are created from the .mat file annotations using [this Python script](https://github.com/nightrome/cocostuff/blob/master/dataset/code/convertAnnotationsJSON.py). They include stuff, but no thing annotations, as these are already in COCO. We encode every stuff class present in an image as a single annotation using the RLE encoding format of COCO. Version 1.1 indicates that for compatibility with COCO, the stuff classes take the indices 92 - 182 (formerly 82 - 172). Note that COCO has 91 classes (some of which were removed, because they were not frequent enough).

### Label Hierarchy
The hierarchy of labels is stored in `CocoStuffClasses`. To visualize it, run `CocoStuffClasses.showClassHierarchyStuffThings()` (also available for just stuff and just thing classes) in Matlab. The output should look similar to the following figure:
<img src="http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-labelhierarchy.png" alt="COCO-Stuff label hierarchy" width="100%">

### File Format
The COCO-Stuff annotations are stored in separate .mat files per image. These files follow the same format as used by Tighe et al.. Each file contains the following fields:
- *S:* The pixel-wise label map of size [height x width]. For use in Matlab all label indices start from 1
- *names:* The names of the 172 classes in COCO-Stuff. 1 is the class 'unlabeled', 2-81 are things and 82-172 are stuff classes.
- *captions:* Image captions from [2] that are annotated by 5 distinct humans on average.
- *regionMapStuff:* A map of the same size as S that contains the indices for the approx. 1000 regions (superpixels) used to annotate the image.
- *regionLabelsStuff:* A list of the stuff labels for each superpixel. The indices in regionMapStuff correspond to the entries in regionLabelsStuff.

## Semantic Segmentation Models
To encourage further research of stuff and things we provide the trained semantic segmentation model (see Sect. 4.4 in [1]).

### DeepLab
Use the following steps to download and setup the DeepLab [4] semantic segmentation model trained on COCO-Stuff. It requires [deeplab-public-ver2](https://bitbucket.org/aquariusjay/deeplab-public-ver2) and is built on [Caffe](caffe.berkeleyvision.org):

1. Download deeplab-public-ver2: `git submodule update --init models/deeplab-public-ver2`
2. Compile and configure deeplab-public-ver2 following the [author's instructions](https://bitbucket.org/aquariusjay/deeplab-public-ver2). Depending on your system setup you might have to install additional packages, but a minimum setup could look like this:
  - `cd models/deeplab-public-ver2`
  - `cp Makefile.config.example Makefile.config`
  - `make`
  - `cd ../..`
3. Download and unzip the model:
  - `wget --directory-prefix=downloads http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/cocostuff-deeplab.zip`
  - `unzip downloads/cocostuff-deeplab.zip -d models/deeplab-public-ver2/`
4. Configure the COCO-Stuff dataset:
  - Create a symbolic link to the images: `mkdir models/deeplab-public-ver2/cocostuff/data && ln -s ../../../../dataset/images models/deeplab-public-ver2/cocostuff/data/images`
  - Convert the annotations by running the Matlab script: `convertAnnotationsDeeplab();`
5. Run `cd models/deeplab-public-ver2 && ./run_cocostuff.sh && cd ../..` to train and test the network on COCO-Stuff.

## Annotation Tool
In [1] we present a simple and efficient stuff annotation tool which was used to annotate the COCO-Stuff dataset. It uses a paintbrush tool to annotate SLICO superpixels (precomputed using the [code](http://ivrl.epfl.ch/files/content/sites/ivrg/files/supplementary_material/RK_SLICsuperpixels/SLIC_mex.zip) of [Achanta et al.](http://ivrl.epfl.ch/research/superpixels)) with stuff labels. These annotations are overlaid with the existing pixel-level thing annotations from COCO.
We provide a basic version of our annotation tool:
- Prepare the required data:
  - Specify a username in `annotator/data/input/user.txt`.
  - Create a list of images in `annotator/data/input/imageLists/<user>.list`.
  - Extract the thing annotations for all images in Matlab: `extractThings()`.
  - Extract the superpixels for all images in Matlab: `extractSLICOSuperpixels()`.
- Run the annotation tool in Matlab: `CocoStuffAnnotator();`
  - The tool writes the .mat label files to `annotator/data/output/annotations`.
  - To create a .png preview of the annotations, run `annotator/code/exportImages.m` in Matlab. The previews will be saved to `annotator/data/output/preview`.

## Misc
### References
- [1] [COCO-Stuff: Thing and Stuff Classes in Context](https://arxiv.org/abs/1612.03716)<br />
H. Caesar, J. Uijlings, V. Ferrari,<br />
In *arXiv preprint arXiv:1612.03716*, 2017.<br />

- [2] [Microsoft COCO: Common Objects in Context](https://arxiv.org/abs/1405.0312)<br />
T.-Y. Lin, M. Maire, S. Belongie et al.,<br />
In *European Conference in Computer Vision* (ECCV), 2014.<br />

- [3] [Fully convolutional networks for semantic segmentation](http://www.cv-foundation.org/openaccess/content_cvpr_2015/html/Long_Fully_Convolutional_Networks_2015_CVPR_paper.html)<br />
J. Long, E. Shelhammer and T. Darrell,<br />
In *Computer Vision and Pattern Recognition* (CVPR), 2015.<br />

- [4] [Semantic image segmentation with deep convolutional nets and fully connected CRFs](https://arxiv.org/abs/1412.7062)<br />
L.-C. Chen, G. Papandreou, I. Kokkinos et al.,<br />
In *International Conference on Learning Representations* (ICLR), 2015.<br />

- [5] [LabelBank: Revisiting Global Perspectives for Semantic Segmentation](https://arxiv.org/pdf/1703.09891.pdf)<br />
H. Hu, Z. Deng, G.-T. Zhou et al.<br />
In *arXiv preprint arXiv:1703.09891*, 2017.<br />

### Licensing
COCO-Stuff is a derivative work of the COCO dataset. The authors of COCO do not in any form endorse this work. Different licenses apply:
- COCO images: [Flickr Terms of use](http://mscoco.org/terms_of_use/)
- COCO annotations: [Creative Commons Attribution 4.0 License](http://mscoco.org/terms_of_use/)
- COCO-Stuff annotations & code: [Creative Commons Attribution 4.0 License](https://creativecommons.org/licenses/by/4.0/legalcode)

### Contact
If you have any questions regarding this dataset, please contact us at holger-at-it-caesar.com.
