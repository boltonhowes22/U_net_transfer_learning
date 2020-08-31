load('svm.mat');

mkdir('../shells');
files = dir('../segmented/*.mat');
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
    
    CC = bwconncomp(processed);
    stats = regionprops('table', CC, 'all');
    
    yfit = trainedModel.predictFcn(stats);
    
    for idx = 1:CC.NumObjects
        processed(CC.PixelIdxList{idx}) = yfit(idx);
    end
    
    imwrite(processed, "../shells/" + i + ".tif");
end