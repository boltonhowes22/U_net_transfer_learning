% Script for transfer learning on multispectralUnet.mat with the training
% image data generated by training_data_script.m
%
% Devon Ulrich, 7/22/2020. Last modified 9/8/2020.

% NOTE: be sure to replace these strings if you're running this script!
TRAINING_DIR = "/scratch/network/dulrich/training";
NETS_DIR = "./nets";

% load all images & their segmented class settings
colorIDs = 0:6;
colorLabels = ["calcite" "clay" "oxide" "fill" "not_rock" "gray" "renalcid"];
n_classes = length(colorIDs);

training_im_ds = imageDatastore(fullfile(TRAINING_DIR, "*in.tif"));
training_label_ds = pixelLabelDatastore(fullfile(TRAINING_DIR, "*out.tif"),...
    colorLabels, colorIDs);

% augmenter changes each image slightly during each epoch to prevent
% overfitting
augmenter = imageDataAugmenter(...
        'RandXReflection', 1, ...
        'RandYReflection', 1, ...
        'RandRotation', @get_angle, ...
        'RandScale', [1 1.2]);
training_ds = pixelLabelImageDatastore(training_im_ds,training_label_ds,...
    'DataAugmentation', augmenter);

val_im_ds = imageDatastore(fullfile(TRAINING_DIR, "*_in_1.tif"));
val_label_ds = pixelLabelDatastore(fullfile(TRAINING_DIR, "*_out_1.tif"),...
    colorLabels, colorIDs);
val_ds = pixelLabelImageDatastore(val_im_ds, val_label_ds);

% load the network & prep it for transfer learning
ld = load(fullfile(NETS_DIR, "multispectralUnet.mat"));
pretrained_net = ld.net;
last_fixed_layer = 21;
new_learnrate_factor = 10;
dice_loss = 0;
class_list = cellstr(colorLabels);

% set up class weights
tbl = countEachLabel(training_ds);
totalNumberOfPixels = sum(tbl.PixelCount);
frequency = tbl.PixelCount / totalNumberOfPixels;
classWeights = 1./frequency;
[ready_net] = transfer_ready(pretrained_net, last_fixed_layer, n_classes,...
    class_list, new_learnrate_factor, dice_loss, classWeights);

%setup some options
options = trainingOptions('sgdm', ...
  'ExecutionEnvironment','multi-gpu',...
  'LearnRateSchedule','piecewise',...
  'LearnRateDropPeriod',12,...
  'LearnRateDropFactor',0.7,...
  'InitialLearnRate',2e-3,...
  'Momentum', 0.9,...
  'GradientThreshold',0.05,...
  'GradientThresholdMethod','l2norm',...
  'ValidationData',val_ds,...
  'MaxEpochs',90,...
  'MiniBatchSize',16, ...
  'Shuffle','every-epoch', ...
  'CheckpointPath', tempdir, ...
  'VerboseFrequency',2);
% Now, train
[cnn_net, training_info] = trainNetwork(training_ds, ready_net, options);

% evaluate results
results_ds = semanticseg(val_im_ds, cnn_net, "WriteLocation", tempdir);
metrics = evaluateSemanticSegmentation(results_ds, val_label_ds)

date = datestr(now);
date = strrep(date, ' ', '-');
date = strrep(date, ':', '-');
save(fullfile(NETS_DIR, date + ".mat"), "cnn_net", "training_info", "metrics");
date
