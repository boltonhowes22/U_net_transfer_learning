function augment_and_save(imgDS, maskDS, path, iterations, nanID)
% Creates and saves augmented copies of training input / masks.
% Helps increase the amount of training data available.
%
% IN
%
% imgDS: the ImageDatastore for the input images to use. The number of
% channels in the images does not matter.
%
% maskDS: a PixelLabelDatastore containing the labeled data for all images
% in imgDS. All pixels must have a specific label (including untraced
% pixels).
%
% path: the string path for where to save the augmented images
%
% iterations: the number of times to copy & save each sample. For example,
% if iterations = 2, then two extra augmented versions of each image will
% be generated and saved.
%
% nanID: the ID number associated with unlabeled / untraced pixels. When
% this augmenter creates additional blank sections by rotating & zooming
% images, it will fill those blank sections with this label.
%
% Devon Ulrich, 6/25/2020. Last modified 6/29/2020.
    augmenter = imageDataAugmenter(...
        'RandXReflection', 1, ...
        'RandYReflection', 1, ...
        'RandRotation', @get_angle, ...
        'RandScale', [1 1.2]);
    
    pliDS = pixelLabelImageDatastore(imgDS, maskDS, 'DataAugmentation', augmenter);
    
    % make 'iterations' copies of each training patch
    for i = 1:iterations
        reset(pliDS);
        imgNum = 1;
        while pliDS.hasdata()
            curr = read(pliDS);
            currImg = curr{1,1}{1};
            currMask = uint8(curr{1,2}{1});
            
            % replace undefined labels (from rotation) with blank label
            currMask(currMask == 0) = uint8(nanID + 1);
            currMask = currMask - 1; % change from 1-indexed to 0-indexed
            
            % save augmented images in training folder, as ###_in/out_#.tif
            imgName = fullfile(path, ...
                sprintf("%03d", imgNum) + "_in_" + i + ".tif");
            maskName = fullfile(path, ...
                sprintf("%03d", imgNum) + "_out_" + i + ".tif");
            save_img(currImg, imgName);
            imwrite(currMask, maskName, 'tiff');
            
            imgNum = imgNum + 1;
        end
    end
end