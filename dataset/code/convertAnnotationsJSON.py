#!/usr/bin/python

# convertAnnotationsJSON
#
# This script converts the .mat file annotations of the COCO-Stuff into a single .json file compatible with the COCO API.
# Stuff classes take the indices 92-182.
# To run this script you need to download the COCO-Stuff code, COCO-Stuff dataset, COCO annotations and COCO API.
# For more information, go to: https://github.com/nightrome/cocostuff
#
# Copyright by Holger Caesar, 2017

# Settings
import inspect, os
rootFolder = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))))
annotFolder = os.path.join(rootFolder, 'dataset', 'annotations')
jsonPath = os.path.join(rootFolder, 'dataset', 'cocostuff-10k-v1.1-stuffOnly.json')
cocoApiFolder = os.path.join(rootFolder, 'downloads', 'cocoApi', 'coco-336d2a27c91e3c0663d2dcf0b13574674d30f88e', 'PythonAPI')
annPath = os.path.join(rootFolder, 'downloads', 'instances_train-val2014', 'annotations', 'instances_train2014.json')
indent = 0
separators = (',', ':')
ensure_ascii = False
oldStuffStartIdx = 82
newStuffStartIdx = 92

# Add COCO to path
import sys
sys.path.append(cocoApiFolder)

from pycocotools import mask
import numpy as np
import pylab
import h5py  # To open matlab files
import glob  # to get the files in a folder
import io
import json

# Get images
imageList = glob.glob(annotFolder + '/*.mat')
imageCount = len(imageList)
imageIds = [int(imageName[-16:-4]) for imageName in imageList]

# Load COCO API
print("Loading COCO annotations...")
with open(annPath) as annFile:
    data = json.load(annFile)

# Init
annId = 0

print("Writing JSON metadata...")
with io.open(jsonPath, 'w', encoding='utf8') as outfile:
    # Global start
    outfile.write(unicode('{\n'))

    # Write info
    infodata = {'description': 'This is the 1.0 release of the COCO-Stuff (10K) dataset.',
                'url': 'https://github.com/nightrome/cocostuff',
                'version': '1.0',
                'year': 2017,
                'contributor': 'H. Caesar, J. Uijlings and V. Ferrari',
                'date_created': '2016-12-12 12:00:00.0'},
    infodata = {'info': infodata}
    str_ = json.dumps(infodata, indent=indent, sort_keys=True, separators=separators, ensure_ascii=ensure_ascii)
    str_ = str_[1:-2] + ',\n'  # Remove brackets and add comma
    outfile.write(unicode(str_))

    # Write images
    imdata = [i for i in data['images'] if i['id'] in imageIds]
    imdata = {'images': imdata}
    str_ = json.dumps(imdata, indent=indent, sort_keys=True, separators=separators, ensure_ascii=ensure_ascii)
    str_ = str_[1:-2] + ',\n'  # Remove brackets and add comma
    outfile.write(unicode(str_))

    # Write licenses
    licdata = {'licenses': data['licenses']}
    str_ = json.dumps(licdata, indent=indent, sort_keys=True, separators=separators, ensure_ascii=ensure_ascii)
    str_ = str_[1:-2] + ',\n'  # Remove brackets and add comma
    outfile.write(unicode(str_))

    # Write categories
    catdata = data['categories']
    catdata.extend([
        {'id': 92, 'name': 'banner', 'supercategory': 'textile'},
        {'id': 93, 'name': 'blanket', 'supercategory': 'textile'},
        {'id': 94, 'name': 'branch', 'supercategory': 'plant'},
        {'id': 95, 'name': 'bridge', 'supercategory': 'building'},
        {'id': 96, 'name': 'building-other', 'supercategory': 'building'},
        {'id': 97, 'name': 'bush', 'supercategory': 'plant'},
        {'id': 98, 'name': 'cabinet', 'supercategory': 'furniture-stuff'},
        {'id': 99, 'name': 'cage', 'supercategory': 'structural'},
        {'id': 100, 'name': 'cardboard', 'supercategory': 'raw-material'},
        {'id': 101, 'name': 'carpet', 'supercategory': 'floor'},
        {'id': 102, 'name': 'ceiling-other', 'supercategory': 'ceiling'},
        {'id': 103, 'name': 'ceiling-tile', 'supercategory': 'ceiling'},
        {'id': 104, 'name': 'cloth', 'supercategory': 'textile'},
        {'id': 105, 'name': 'clothes', 'supercategory': 'textile'},
        {'id': 106, 'name': 'clouds', 'supercategory': 'sky'},
        {'id': 107, 'name': 'counter', 'supercategory': 'furniture-stuff'},
        {'id': 108, 'name': 'cupboard', 'supercategory': 'furniture-stuff'},
        {'id': 109, 'name': 'curtain', 'supercategory': 'textile'},
        {'id': 110, 'name': 'desk', 'supercategory': 'furniture-stuff'},
        {'id': 111, 'name': 'dirt', 'supercategory': 'ground'},
        {'id': 112, 'name': 'door', 'supercategory': 'furniture-stuff'},
        {'id': 113, 'name': 'fence', 'supercategory': 'structural'},
        {'id': 114, 'name': 'floor-marble', 'supercategory': 'floor'},
        {'id': 115, 'name': 'floor-other', 'supercategory': 'floor'},
        {'id': 116, 'name': 'floor-stone', 'supercategory': 'floor'},
        {'id': 117, 'name': 'floor-tile', 'supercategory': 'floor'},
        {'id': 118, 'name': 'floor-wood', 'supercategory': 'floor'},
        {'id': 119, 'name': 'flower', 'supercategory': 'plant'},
        {'id': 120, 'name': 'fog', 'supercategory': 'water'},
        {'id': 121, 'name': 'food-other', 'supercategory': 'food-stuff'},
        {'id': 122, 'name': 'fruit', 'supercategory': 'food-stuff'},
        {'id': 123, 'name': 'furniture-other', 'supercategory': 'furniture-stuff'},
        {'id': 124, 'name': 'grass', 'supercategory': 'plant'},
        {'id': 125, 'name': 'gravel', 'supercategory': 'ground'},
        {'id': 126, 'name': 'ground-other', 'supercategory': 'ground'},
        {'id': 127, 'name': 'hill', 'supercategory': 'solid'},
        {'id': 128, 'name': 'house', 'supercategory': 'building'},
        {'id': 129, 'name': 'leaves', 'supercategory': 'plant'},
        {'id': 130, 'name': 'light', 'supercategory': 'furniture-stuff'},
        {'id': 131, 'name': 'mat', 'supercategory': 'textile'},
        {'id': 132, 'name': 'metal', 'supercategory': 'raw-material'},
        {'id': 133, 'name': 'mirror', 'supercategory': 'furniture-stuff'},
        {'id': 134, 'name': 'moss', 'supercategory': 'plant'},
        {'id': 135, 'name': 'mountain', 'supercategory': 'solid'},
        {'id': 136, 'name': 'mud', 'supercategory': 'ground'},
        {'id': 137, 'name': 'napkin', 'supercategory': 'textile'},
        {'id': 138, 'name': 'net', 'supercategory': 'structural'},
        {'id': 139, 'name': 'paper', 'supercategory': 'raw-material'},
        {'id': 140, 'name': 'pavement', 'supercategory': 'ground'},
        {'id': 141, 'name': 'pillow', 'supercategory': 'textile'},
        {'id': 142, 'name': 'plant-other', 'supercategory': 'plant'},
        {'id': 143, 'name': 'plastic', 'supercategory': 'raw-material'},
        {'id': 144, 'name': 'platform', 'supercategory': 'ground'},
        {'id': 145, 'name': 'playingfield', 'supercategory': 'ground'},
        {'id': 146, 'name': 'railing', 'supercategory': 'structural'},
        {'id': 147, 'name': 'railroad', 'supercategory': 'ground'},
        {'id': 148, 'name': 'river', 'supercategory': 'water'},
        {'id': 149, 'name': 'road', 'supercategory': 'ground'},
        {'id': 150, 'name': 'rock', 'supercategory': 'solid'},
        {'id': 151, 'name': 'roof', 'supercategory': 'building'},
        {'id': 152, 'name': 'rug', 'supercategory': 'textile'},
        {'id': 153, 'name': 'salad', 'supercategory': 'food-stuff'},
        {'id': 154, 'name': 'sand', 'supercategory': 'ground'},
        {'id': 155, 'name': 'sea', 'supercategory': 'water'},
        {'id': 156, 'name': 'shelf', 'supercategory': 'furniture-stuff'},
        {'id': 157, 'name': 'sky-other', 'supercategory': 'sky'},
        {'id': 158, 'name': 'skyscraper', 'supercategory': 'building'},
        {'id': 159, 'name': 'snow', 'supercategory': 'ground'},
        {'id': 160, 'name': 'solid-other', 'supercategory': 'solid'},
        {'id': 161, 'name': 'stairs', 'supercategory': 'furniture-stuff'},
        {'id': 162, 'name': 'stone', 'supercategory': 'solid'},
        {'id': 163, 'name': 'straw', 'supercategory': 'plant'},
        {'id': 164, 'name': 'structural-other', 'supercategory': 'structural'},
        {'id': 165, 'name': 'table', 'supercategory': 'furniture-stuff'},
        {'id': 166, 'name': 'tent', 'supercategory': 'building'},
        {'id': 167, 'name': 'textile-other', 'supercategory': 'textile'},
        {'id': 168, 'name': 'towel', 'supercategory': 'textile'},
        {'id': 169, 'name': 'tree', 'supercategory': 'plant'},
        {'id': 170, 'name': 'vegetable', 'supercategory': 'food-stuff'},
        {'id': 171, 'name': 'wall-brick', 'supercategory': 'wall'},
        {'id': 172, 'name': 'wall-concrete', 'supercategory': 'wall'},
        {'id': 173, 'name': 'wall-other', 'supercategory': 'wall'},
        {'id': 174, 'name': 'wall-panel', 'supercategory': 'wall'},
        {'id': 175, 'name': 'wall-stone', 'supercategory': 'wall'},
        {'id': 176, 'name': 'wall-tile', 'supercategory': 'wall'},
        {'id': 177, 'name': 'wall-wood', 'supercategory': 'wall'},
        {'id': 178, 'name': 'water-other', 'supercategory': 'water'},
        {'id': 179, 'name': 'waterdrops', 'supercategory': 'water'},
        {'id': 180, 'name': 'window-blind', 'supercategory': 'window'},
        {'id': 181, 'name': 'window-other', 'supercategory': 'window'},
        {'id': 182, 'name': 'wood', 'supercategory': 'solid'}
    ])
    catdata = {'categories': catdata}
    str_ = json.dumps(catdata, indent=indent, sort_keys=True, separators=separators, ensure_ascii=ensure_ascii)
    str_ = str_[1:-2] + ',\n'  # Remove brackets and add comma
    outfile.write(unicode(str_))

    # Start
    outfile.write(unicode('"annotations": [\n'))

    for imageIdx, imageName in enumerate(imageList):

        # Write annotations
        print "Writing JSON annotation %d of %d..." % (imageIdx+1, imageCount)

        # Read annotation file
        annotPath = os.path.join(annotFolder, imageName)
        matfile = h5py.File(annotPath)
        S = matfile['S'].value
        [h, w] = S.shape
        regionLabelsStuff = matfile['regionLabelsStuff']
        labelsAll = np.unique(regionLabelsStuff)
        labelsStuff = [i for i in labelsAll if i >= oldStuffStartIdx]

        # Accumulate label masks
        for i, labelIdx in enumerate(labelsStuff):
            # Create mask and encode it
            labelMask = np.zeros((h, w))
            labelMask[:, :] = S == labelIdx
            labelMask = labelMask.transpose()
            labelMask = np.expand_dims(labelMask, axis=2)
            labelMask = labelMask.astype('uint8')
            labelMask = np.asfortranarray(labelMask)
            Rs = mask.encode(labelMask)

            # Create annotation data
            anndata = {}
            anndata['id'] = annId
            anndata['image_id'] = imageIds[imageIdx]
            anndata['category_id'] = labelIdx - oldStuffStartIdx + newStuffStartIdx # Stuff classes start from 92 in Python format
            anndata['segmentation'] = Rs
            anndata['area'] = float(mask.area(Rs))
            anndata['bbox'] = mask.toBbox(Rs).tolist()
            anndata['iscrowd'] = 1

            annId = annId + 1

            # Write JSON
            str_ = json.dumps(anndata, indent=indent, sort_keys=True, separators=separators, ensure_ascii=ensure_ascii)
            outfile.write(unicode(str_))

            # Add a comma and line break after each annotation
            if not (imageIdx == imageCount-1 and i == len(labelsStuff)-1):
                outfile.write(unicode(','))
            outfile.write(unicode('\n'))

    # End
    outfile.write(unicode(']\n'))

    # Global end
    outfile.write(unicode('}'))
