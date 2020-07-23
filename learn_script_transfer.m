% load all images
colorIDs = 0:4;
colorLabels = ["calcite" "clay" "oxide" "fill" "not_rock"];
n_classes = length(colorIDs);

training_im_ds = imageDatastore("../training/*in_*.tif");
training_label_ds = pixelLabelDatastore("../training/*out_*.tif", colorLabels, colorIDs);
training_ds = pixelLabelImageDatastore(training_im_ds,training_label_ds);

val_im_ds = imageDatastore("../training/*_in.tif");
val_label_ds = pixelLabelDatastore("../training/*_out.tif", colorLabels, colorIDs);
val_ds = pixelLabelImageDatastore(val_im_ds, val_label_ds);

% load the network & prep it for transfer learning
ld = load("multispectralUnet.mat");
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
[ready_net] = transfer_ready(pretrained_net, last_fixed_layer, n_classes, class_list, new_learnrate_factor, dice_loss, classWeights);

%setup some options
options = trainingOptions('sgdm', ...
  'LearnRateSchedule','piecewise',...
  'InitialLearnRate',1e-3,...
  'Momentum', 0.9,...
  'GradientThreshold',0.05,...
  'GradientThresholdMethod','l2norm',...
  'L2Regularization',0.005, ...
  'ValidationData',val_ds,...
  'MaxEpochs',30, ...
  'MiniBatchSize',16, ...
  'Shuffle','every-epoch', ...
  'CheckpointPath', tempdir, ...
  'VerboseFrequency',2,...
  'ValidationFrequency',30,...
  'ValidationPatience', 4);
% Now, train
[cnn_net, training_info] = trainNetwork(training_ds, ready_net, options);

% evaluate results
results_ds = semanticseg(val_im_ds, cnn_net, "WriteLocation", tempdir);
metrics = evaluateSemanticSegmentation(results_ds, val_label_ds)

date = datestr(now);
date = strrep(date, ' ', '-');
date = strrep(date, ':', '-');
save("results/" + date + ".mat", "cnn_net", "training_info", "metrics");
