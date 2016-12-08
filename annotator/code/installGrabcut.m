% Compile grabcut-calvin
filePath = fullfile('grabcut-calvin', 'external', 'sparseFromLabels.c');
mex('-largeArrayDims', filePath);

filePaths = fullfile('grabcut-calvin', 'maxflow', {'maxflow_mex.cpp', fullfile('maxflow-v3.0', 'graph.cpp'), fullfile('maxflow-v3.0', 'maxflow.cpp')}); 
mex('-largeArrayDims', filePaths{:});

% Grabcut-calvin
grabcutFolder = 'grabcut-calvin';
addpath(genpath(grabcutFolder));