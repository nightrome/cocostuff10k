#!/bin/sh

## MODIFY PATH for YOUR SETTING
ROOT_DIR=
CAFFE_DIR=deeplab-public-ver2
CAFFE_BIN=${CAFFE_DIR}/.build_release/tools/caffe.bin
EXP=cocostuff

if [ "${EXP}" = "cocostuff" ]; then
    NUM_LABELS=172
    DATA_ROOT=${EXP}/data
else
    NUM_LABELS=0
    echo "Wrong exp name"
fi
 

## Specify which model to train
########### voc12 ################
NET_ID=deeplabv2_vgg16
DEV_ID=2

#####

## Create dirs
CONFIG_DIR=${EXP}/config/${NET_ID}
MODEL_DIR=${EXP}/model/${NET_ID}
mkdir -p ${MODEL_DIR}
LOG_DIR=${EXP}/log/${NET_ID}
mkdir -p ${LOG_DIR}
export GLOG_log_dir=${LOG_DIR}

## Run
RUN_TRAIN=1
RUN_TEST=1

## Training #1 (on train_aug)

if [ ${RUN_TRAIN} -eq 1 ]; then
    #
    LIST_DIR=${EXP}/list
    TRAIN_SET=train${TRAIN_SET_SUFFIX}
    if [ -z ${TRAIN_SET_WEAK_LEN} ]; then
				TRAIN_SET_WEAK=${TRAIN_SET}_diff_${TRAIN_SET_STRONG}
				comm -3 ${LIST_DIR}/${TRAIN_SET}.txt ${LIST_DIR}/${TRAIN_SET_STRONG}.txt > ${LIST_DIR}/${TRAIN_SET_WEAK}.txt
    else
				TRAIN_SET_WEAK=${TRAIN_SET}_diff_${TRAIN_SET_STRONG}_head${TRAIN_SET_WEAK_LEN}
				comm -3 ${LIST_DIR}/${TRAIN_SET}.txt ${LIST_DIR}/${TRAIN_SET_STRONG}.txt | head -n ${TRAIN_SET_WEAK_LEN} > ${LIST_DIR}/${TRAIN_SET_WEAK}.txt
    fi
    #
    MODEL=${EXP}/model/${NET_ID}/init.caffemodel
    #
    echo Training net ${EXP}/${NET_ID}
    for pname in train solver; do
				sed "$(eval echo $(cat sub.sed))" \
						${CONFIG_DIR}/${pname}.prototxt > ${CONFIG_DIR}/${pname}_${TRAIN_SET}.prototxt
    done
        CMD="${CAFFE_BIN} train \
         --solver=${CONFIG_DIR}/solver_${TRAIN_SET}.prototxt \
         --gpu=${DEV_ID}"
		if [ -f ${MODEL} ]; then
				CMD="${CMD} --weights=${MODEL}"
		fi
		echo Running ${CMD} && ${CMD}
fi

## Test #1 specification (on val or test)

if [ ${RUN_TEST} -eq 1 ]; then
    #
    for TEST_SET in val; do
				TEST_ITER=`cat ${EXP}/list/${TEST_SET}.txt | wc -l`
				MODEL=${EXP}/model/${NET_ID}/test.caffemodel
				if [ ! -f ${MODEL} ]; then
						MODEL=`ls -t ${EXP}/model/${NET_ID}/train_iter_*.caffemodel | head -n 1`
				fi
				#
				echo Testing net ${EXP}/${NET_ID}
				FEATURE_DIR=${EXP}/features/${NET_ID}
				mkdir -p ${FEATURE_DIR}/${TEST_SET}/fc8
        mkdir -p ${FEATURE_DIR}/${TEST_SET}/fc9
				mkdir -p ${FEATURE_DIR}/${TEST_SET}/seg_score
				sed "$(eval echo $(cat sub.sed))" \
						${CONFIG_DIR}/test.prototxt > ${CONFIG_DIR}/test_${TEST_SET}.prototxt
				CMD="${CAFFE_BIN} test \
             --model=${CONFIG_DIR}/test_${TEST_SET}.prototxt \
             --weights=${MODEL} \
             --gpu=${DEV_ID} \
             --iterations=${TEST_ITER}"
				echo Running ${CMD} && ${CMD}
    done
fi
