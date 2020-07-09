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
[imgs, masks] = load_training_data(inputDS, tracingDS, [256 256], 0.3, 17);

% save the imgs / masks as tiffs in a 'training' folder
mkdir("../training");
imgCount = size(imgs,4);
for i = 1:imgCount
    imgName = fullfile("../training", sprintf("%03d", i) + "_in.tif");
    maskName = fullfile("../training", sprintf("%03d", i) + "_out.tif");
    % use custom function for 6-channel image saving
    save_img(imgs(:,:,:,i), imgName);
    imwrite(masks(:,:,:,i), maskName, 'tiff');
end

%% load the images and save augmented copies of them
imgPath = fullfile("../training", "*_in.tif");
imgDS = imageDatastore(imgPath);
maskPath = fullfile("../training", "*_out.tif");
maskDS = pixelLabelDatastore(maskPath, colorLabels, colorIDs);

% make 3 augmented copies of each original patch
augment_and_save(imgDS, maskDS, "../training", 3, 17);

%% read some files and show them, as a test
testInDS = imageDatastore("../training/*in*.tif");
testOutDS = pixelLabelDatastore("../training/*out*.tif", ...
    colorLabels(1:end-1), colorIDs(1:end-1)); % don't use the untraced category

numImgs = numpartitions(testInDS);

for i = 1:numImgs
    baseImg = read(testInDS);
    maskImg = read(testOutDS);
    
    res{i} = labeloverlay(baseImg(:,:,1:3), maskImg{1});
end
montage(res, "Size", [10 10]);