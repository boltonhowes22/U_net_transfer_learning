% Script for loading our manually traced thin sections from
% image files. The output (imgs and labels) can then be used to train
% classification models.
%
% Devon Ulrich, 6/11/2020. Last modified 9/8/2020.

% NOTE: be sure to replace these strings if you're running this script!
IMGS_DIR = "../images";
OUTPUT_DIR = "/scratch/network/dulrich/training";

colorIDs = 0:17;
colorLabels = ["circ_shell" "sponge_spicule" "renalcid_texture" "oxide"...
    "speckled_fill" "misc_shell" "archaeo" "not_rock" "trilobite"...
    "crystal_calcite" "clay_layer" "gray_hash" "orientation_hole"...
    "peloidal" "stylolite" "calcimicrobe" "homogenous_fill" "unlabeled"];

% Load all images of each type
pplImgs = fullfile(IMGS_DIR, "*_ppl.tif");
xplImgs = fullfile(IMGS_DIR, "*_xpl.tif");
tracingImgs = fullfile(IMGS_DIR, "*_indexed.tif");

% set up input image datastores
pplDS = imageDatastore(pplImgs);
xplDS = imageDatastore(xplImgs);
inputDS = combine(pplDS, xplDS);
tracingDS = imageDatastore(tracingImgs);

% get all 256x256 patches with less than 20% untraced pixels
mkdir(OUTPUT_DIR);
reduceMap = [0 0 6 2 3 0 0 4 0 0 1 5 4 3 2 1 3 7];
load_training_data(inputDS, tracingDS, OUTPUT_DIR,...
    [256 256], [64 64], 0.2, 17, reduceMap);
colorIDs = 0:7;
colorLabels = ["calcite" "clay" "oxide" "fill" "not_rock" "gray" "renalcid" "unlabeled"];

%% load the images and save augmented copies of them
imgPath = fullfile(OUTPUT_DIR, "*_in.tif");
imgDS = imageDatastore(imgPath);
maskPath = fullfile(OUTPUT_DIR, "*_out.tif");
maskDS = pixelLabelDatastore(maskPath, colorLabels, colorIDs);

% make 1 augmented copy of each original patch
augment_and_save(imgDS, maskDS, OUTPUT_DIR, 1, 7);
