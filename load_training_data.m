function load_training_data(inputDS, tracingDS, outputFolder, patchSize, maxUndef, nanID)
% This function accepts large input images and their corresponding
% partially-traced masks, and splits them into patches of almost
% entirely traced inputs and outputs to use as training data for the u-net.
%
% IN
% inputDS: the datastore for all color input images. Can be either an
% imageDatastore or a combinedDatastore (consisting of multiple
% imageDatastores), depending on how many layers / color channels are
% desired for the output patches.
%
% tracingDS: imageDatastore for all indexed-color tracing images. Note:
% inputDS and tracingDS must contain images from the same samples in the
% same exact order.
%
% patchSize: a 2-element vector describing the desired [rows, columns] of
% all output patches
%
% maxUndef: the maximum fraction of untraced pixels for each output patch.
% maxUndef should be between 0 and 1. Ex: 0.2 means that at most 20% of
% each patch should be untraced.
% 
% nanID: the integer label for unlabeled pixels in the training image
% masks.
% 
% Devon Ulrich, 6/11/2020. Last modified 7/2/2020.
    % reset all datastores
    reset(inputDS);
    reset(tracingDS);
    
    if class(inputDS) == "matlab.io.datastore.CombinedDatastore"
        numChannels = 3 * size(inputDS.UnderlyingDatastores, 2);
    elseif class(inputDS) == "matlab.io.datastore.ImageDatastore"
        numChannels = 3;
    else
        error("inputDS is an unsupported datatype: %s", class(inputDS));
    end
    
    imgs(patchSize(1),patchSize(2),numChannels) = uint16(0);
    currIndex = 1;
    while hasdata(inputDS)
        % load all the data for this sample
        currImg = read(inputDS);
        if ~isa(currImg, 'cell')
            % make sure that currImg is a cell
            currImg = {currImg};
        end
        
        imgLabels = read(tracingDS);
        
        % iterate through each patch rectangle in the image
        for row = 1:patchSize(1):(size(currImg{1}, 1) - patchSize(1))
            currRows = row:(row+patchSize(1)-1);
            for col = 1:patchSize(2):(size(currImg{1}, 2) - patchSize(2))
                currCols = col:(col+patchSize(2)-1);
                currPatch = imgLabels(currRows, currCols);
                
                % get the total count of unlabeled pixels
                numUnlabeled = sum(currPatch == nanID, "all");
                % if the current patch has a small amount of untraced
                % pixels, then use it
                if numUnlabeled / (patchSize(1) * patchSize(2)) < maxUndef
                    % add everything to a single multi-channel image
                    for ch = 1:(numChannels / 3)
                        currChannels = (ch-1)*3 + 1 : ch*3; % = 1:3, 4:6, etc
                        imgs(:,:,currChannels) = currImg{ch}(currRows, currCols, :);
                    end
                    
                    % save the image and label
                    imgName = fullfile(outputFolder, sprintf("%03d", currIndex) + "_in.tif");
                    maskName = fullfile(outputFolder, sprintf("%03d", currIndex) + "_out.tif");
                    % use custom function for 6-channel image saving
                    save_img(imgs, imgName);
                    imwrite(currPatch, maskName, 'tiff');
                    currIndex = currIndex + 1;
                end
            end
        end
    end
end
