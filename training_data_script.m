% Script and function for loading our manually traced thin sections from
% image files. The output (imgs and labels) can then be used to train
% classification models.
%
% Devon Ulrich, 6/11/2020. Last modified 7/2/2020.

colorIDs = 0:17;
colorLabels = ["circ_shell" "sponge_spicule" "renalcid_texture" "oxide"...
    "speckled_fill" "misc_shell" "archaeo" "not_rock" "trilobite"...
    "crystal_calcite" "clay_layer" "gray_hash" "orientation_hole"...
    "peloidal" "stylolite" "calcimicrobe" "homogenous_fill" "unlabeled"];

% Load all images of each type
pplImgs = fullfile("../images", "*_ppl.tif");
xplImgs = fullfile("../images", "*_xpl.tif");
tracingImgs = fullfile("../images", "*_indexed.tif");

% set up input image datastores
pplDS = imageDatastore(pplImgs);
xplDS = imageDatastore(xplImgs);
inputDS = combine(pplDS, xplDS);
tracingDS = imageDatastore(tracingImgs);

% get all 256x256 patches with less than 30% untraced pixels
mkdir("../training");
load_training_data(inputDS, tracingDS, "../training", [256 256], 0.3, 17);

%% load the images and save augmented copies of them
imgPath = fullfile("../training", "*_in.tif");
imgDS = imageDatastore(imgPath);
maskPath = fullfile("../training", "*_out.tif");
maskDS = pixelLabelDatastore(maskPath, colorLabels, colorIDs);

% make 3 augmented copies of each original patch
augment_and_save(imgDS, maskDS, "../training", 3, 17);
