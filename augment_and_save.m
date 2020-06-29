function augment_and_save(pliDS, path, iterations)
% Creates and saves augmented copies of training input / masks.
% Helps increase the amount of training data available.
%
% IN
% pliDS: a PixelLabelImageDatastore, containing both the input images and
% their corresponding label data. The pixelLabelDatastore must contain all
% labels for each color index, including for unlabeled pixels. The
% unlabeled index must be last in the list of labels & IDs used.
%
% path: the string path for where to save the augmented images
%
% iterations: the number of times to copy & save each sample. For example,
% if iterations = 2, then two extra augmented versions of each image will
% be generated and saved.
%
% Devon Ulrich, 6/25/2020. Last modified 6/29/2020.
    augmenter = imageDataAugmenter(...
        'RandXReflection', 1, ...
        'RandYReflection', 1, ...
        'RandRotation', @getAngle, ...
        'RandScale', [1 1.2]);
    
    pliDS.DataAugmentation = augmenter;
    numClasses = pliDS.classNames;
    
    % make 'iterations' copies of each training patch
    for i = 1:iterations
        reset(pliDS);
        imgNum = 1;
        while pliDS.hasdata()
            curr = read(pliDS);
            currImg = curr{1,1}{1};
            currMask = uint8(curr{1,2}{1});
            
            % replace undefined labels (from rotation) with blank label
            currMask(currMask == 0) = uint8(numClasses);
            currMask = currMask - 1; % change from 1-indexed to 0-indexed
            
            % save augmented images in training folder, as ###_in/out_#.tif
            imgName = fullfile(path, ...
                sprintf("%03d", imgNum) + "_in_" + i + ".tif");
            maskName = fullfile(path, ...
                sprintf("%03d", imgNum) + "_out_" + i + ".tif");
            save_img(imgName, currImg);
            imwrite(currMask, maskName, 'tiff');
            
            imgNum = imgNum + 1;
        end
    end
end

function angle = getAngle()
% custom function for selecting a random rotation angle. Currently rotates
% images 90, 180, 270, or 360 degrees, with a +/- 20 degree offset. This
% creates a lot of rotation possibilities while still minimizing the amount
% of unlabeled pixels in the augmented images.
    big = randi(4);
    small = randi([-20 20]);
    angle = big * 90 + small;
end