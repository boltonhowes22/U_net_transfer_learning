function [imgs, labels] = load_training_data(inputDS, tracingDS, maxUndef, nanID)
% This function accepts large input images and their corresponding
% partially-traced masks, and splits them into 256x256 patches of almost
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
% maxUndef: the maximum fraction of untraced pixels for each output patch.
% maxUndef should be between 0 and 1. Ex: 0.2 means that at most 20% of
% each patch should be untraced.
% 
% nanID: the integer label for unlabeled pixels in the training image
% masks.
% 
% OUT
% imgs: A 4D table of the selected patches. The first two dimensions are
% for the rows and columns of the images (256 each), and the third
% dimension is for each image channel (3 channels for each imageDatastore 
% in inputDS). The fourth dimension is for each patch.
%
% labels: A 4D table of integers for each image, describing each pixel's
% label. The first two dimensions are for the rows and columns again, and
% the third dimension is always 1. The fourth dimension is for each
% individual patch as well.
% 
% Devon Ulrich, 6/11/2020. Last modified 6/29/2020.
    % reset all datastores
    reset(inputDS);
    reset(tracingDS);
    
    numImgs = numpartitions(inputDS);
    if class(inputDS) == "matlab.io.datastore.CombinedDatastore"
        numChannels = 3 * size(inputDS.UnderlyingDatastores, 2);
    elseif class(inputDS) == "matlab.io.datastore.ImageDatastore"
        numChannels = 3;
    else
        error("inputDS is an unsupported datatype: %s", class(inputDS));
    end
    
    % initialize empty img and label tables with starting size of 128
    imgs(256, 256, numChannels, 128) = uint16(0);
    labels(256, 256, 1, 128) = uint8(0);
    currIndex = 1;
    for img = 1:numImgs
        % load all the data for this sample
        currImg = read(inputDS);
        if ~isa(currImg, 'cell')
            % make sure that currImg is a cell
            currImg = {currImg};
        end
        
        imgLabels = read(tracingDS);
        
        % iterate through each 256x256 grid in the image
        for row = 1:256:(size(currImg{1}, 1) - 256)
            currRows = row:(row+255);
            for col = 1:256:(size(currImg{1}, 2) - 256)
                currCols = col:(col+255);
                currPatch = imgLabels(currRows, currCols);
                
                % get the total count of unlabeled pixels
                numUnlabeled = sum(currPatch == nanID, "all");
                % if the current patch has a small amount of untraced
                % pixels, then use it
                if numUnlabeled / (256^2) < maxUndef
                    % add everything to the output variables
                    for ch = 1:(numChannels / 3)
                        currChannels = (ch-1)*3 + 1 : ch*3;
                        imgs(:,:,currChannels,currIndex) = currImg{ch}(currRows, currCols, :);
                    end
                    
                    labels(:,:,1,currIndex) = currPatch;
                    currIndex = currIndex + 1;
                    
                    % double the size of imgs and labels, if needed
                    if currIndex > size(imgs, 4)
                        imgs(256, 256, numChannels, size(imgs, 4)*2) = uint16(0);
                        labels(256, 256, 1, size(labels,4)*2) = uint8(0);
                    end
                end
            end
        end
    end
    
    % remove unused indices in imgs & labels
    imgs = imgs(:, :, :, 1:(currIndex-1));
    labels = labels(:, :, :, 1:(currIndex-1));
end