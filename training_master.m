function [training_ds, validation_ds] = training_master(colorIDs, colorLabels, pplImgs, xplImgs, tracingImgs, nanID)
% This function is a wrapper that combines several functions and scripts to
% build an augmented training dataset for a 6 channel neural network. 
%% Inputs
% colorIDs: the number for each color in the training set
% colorLabels: the label/name for each category
% pplimages: fullfile() path to the ppl images folder
% xplimages: fullfile() path to the xpl images folder
%
%% Outputs
% training_ds: a pixelLabelImageDatastore of training images
% validation_ds: a pixelLabelImageDatastore of validation images
%
%% Example Inputs
% colorIDs = 0:4;
% colorLabels = ["out_of_focus" "giant_ooids" "matrix" "fragments" "unlabeled"];
% pplImgs = fullfile("images", "*_scale.tif");
% xplImgs = fullfile("images", "*_scale.tif");
% tracingImgs = fullfile("images", "*_training.tif");
%
% [training_ds, validation_ds] = training_master(colorIDs, colorLabels, pplimages, xplimages)
%
% Written by Devon Ulrich, Ryan Manzuk, Bolton Howes
% July 10, 2020
% Requirements: Matlab 2020a, Deep Learning Toolbox, Computer Vision
% Toolbox, and Image Processing Toolbox
% ============================== Begin ==============================

% set up input image datastores
pplDS = imageDatastore(pplImgs);
xplDS = imageDatastore(xplImgs);
inputDS = combine(pplDS, xplDS); % combines into 6 channel image
tracingDS = imageDatastore(tracingImgs);

mkdir("training");

% get all patches with less than 30% untraced pixels
patch_size = [256 256];
max_undefined = .3;
load_training_data(inputDS, tracingDS, "training",patch_size, max_undefined, nanID);

%% load the images and save augmented copies of them
imgPath = fullfile("training", "*_in.tif");
imgDS = imageDatastore(imgPath);
maskPath = fullfile("training", "*_out.tif");
maskDS = pixelLabelDatastore(maskPath, colorLabels, colorIDs);

augment_and_save(imgDS, maskDS, "training", 3, nanID);

%% read some files and show them, as a test
testInDS = imageDatastore("training/*in*.tif");
testOutDS = pixelLabelDatastore("training/*out*.tif", ...
    colorLabels(1:end-1), colorIDs(1:end-1)); % don't use untraced categories

numImgs = numpartitions(testInDS);

for i = 1:numImgs
    baseImg = read(testInDS);
    maskImg = read(testOutDS);
    
    res{i} = labeloverlay(baseImg(:,:,1:3), maskImg{1});
end
montage(res, "Size", [10 10]);
%% OK now that the training set is compiled, it is time to split it into 
%  training and validation
% Make training/validation split
% First we are going to make new directories to hold the training and
% validation data
% Start with making file paths
training_dir = fullfile("sliced_training");
training_dir_masks = fullfile(training_dir, 'masks');
training_dir_ims = fullfile(training_dir, 'ims');
validation_dir = fullfile("sliced_validation");
validation_dir_masks = fullfile(validation_dir, 'masks');
validation_dir_ims = fullfile(validation_dir, 'ims');

% Make directory and subdirectory for masks and images
mkdir(training_dir);
mkdir(training_dir_masks);
mkdir(training_dir_ims);
mkdir(validation_dir);
mkdir(validation_dir_masks);
mkdir(validation_dir_ims);

% Now make the training/validation split
n_val = round(size(imgs,4) * 0.1);
val_idx = randperm(size(imgs,4), n_val);
train_idx = [1:size(imgs,4)];
train_idx(val_idx) = [];

for i = train_idx
  imgName = fullfile(training_dir_ims, sprintf("%03d", i) + "_in.tif");
  maskName = fullfile(training_dir_masks, sprintf("%03d", i) + "_out.tif");
  % use custom function for 6-channel image saving
  save_img(imgs(:,:,:,i), imgName);
  imwrite(masks(:,:,:,i), maskName, 'tiff');
end

for j = val_idx
  imgName = fullfile(validation_dir_ims, sprintf("%03d", j) + "_in.tif");
  maskName = fullfile(validation_dir_masks, sprintf("%03d", j) + "_out.tif");
  % use custom function for 6-channel image saving
  save_img(imgs(:,:,:,i), imgName);
  imwrite(masks(:,:,:,j), maskName, 'tiff');
end

%% Make imageDataStores
% now we need to combine the directories and convert them to
% imageDatastores to feed into the NN 

imds_training = imageDatastore(training_dir_ims);
imds_validation = imageDatastore(validation_dir_ims);

pxds_training = pixelLabelDatastore(training_dir_masks,colorLabels,colorIDs);
pxds_validation = pixelLabelDatastore(validation_dir_masks,colorLabels,colorIDs);

training_ds = pixelLabelImageDatastore(imds_training, pxds_training);
validation_ds = pixelLabelImageDatastore(imds_validation, pxds_validation);

end

