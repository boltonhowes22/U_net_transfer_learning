% Script for running the trained SVM on a set of shell regionprops. This
% is a rough approach to isolating shells from large binary images of
% calcite components & a non-calcite background, and the SVM is designed to
% remove a bulk of the non-shell components while being careful not to
% accidentally remove too many actual shells. It does keep a lot of
% non-shell components in the final output though, so I recommend manually
% verifying each shell fragment if possible.
%
% Devon Ulrich, 8/31/2020. Last modified 9/8/2020

SHELLS_DIR = "../../shells";
SEG_DIR = "../../segmented";

load('svm.mat');

mkdir(SHELLS_DIR);
files = dir(fullfile(SEG_DIR, "*.mat"));
for i = 1:size(files, 1)
    % load each segmented .mat file
    currdir = fullfile(files(i).folder, files(i).name)
    load(currdir);
    
    BW = output == 1;
    CC = bwconncomp(BW);
    
    numPixels = cellfun(@numel, CC.PixelIdxList);
    [sorted, idxs] = sort(numPixels); % sort CC's in increasing size
    
    % remove smallest components (with < 400 pixels)
    processed = BW;
    j = 1;
    while numel(CC.PixelIdxList{idxs(j)}) < 400
        processed(CC.PixelIdxList{idxs(j)}) = 0;
        j = j + 1;
    end
    
    % remove biggest components (including them can create memory problems)
    j = CC.NumObjects;
    while numel(CC.PixelIdxList{idxs(j)}) > 50000
        processed(CC.PixelIdxList{idxs(j)}) = 0;
        j = j - 1;
    end
    
    CC = bwconncomp(processed);
    stats = regionprops('table', CC, 'all');
    
    yfit = trainedModel.predictFcn(stats);
    
    for idx = 1:CC.NumObjects
        processed(CC.PixelIdxList{idx}) = yfit(idx);
    end
    
    imwrite(processed, fullfile(SHELLS_DIR, sprintf("%02d", i) + ".tif"));
end