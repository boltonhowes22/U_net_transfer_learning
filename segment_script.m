% Script for using our trained U-net to segment all images in a directory.
%
% Devon Ulrich, 8/6/2020. Last modified 9/8/2020.

% NOTE: be sure to replace these strings if you're running this script!
IMGS_DIR = "/scratch/network/dulrich/images";
NETS_DIR = "./nets";
SEGMENTED_DIR = "/scratch/network/dulrich/segmented";

% load the net and images
load(fullfile(NETS_DIR, "trainedCNN.mat"));

pplDS = imageDatastore(fullfile(IMGS_DIR, "*_ppl.tif"));
xplDS = imageDatastore(fullfile(IMGS_DIR, "*_xpl.tif"));

mkdir(SEGMENTED_DIR);

% for each image, segment all patches & stitch them together
imCount = 0;
while hasdata(pplDS)
    imCount = imCount + 1
    img = read(pplDS);
    img(:,:,4:6) = read(xplDS);

    % keep track of both the predicted output categories & their confidence
    % scores
    output = uint8(zeros(size(img,1),size(img,2)));
    imgscores = zeros(size(img,1),size(img,2));

    for row = 1:256:(size(img,1) - 256)
        currRows = row:(row+255);
        for col = 1:256:(size(img,2) - 256)
            currCols = col:(col+255);
            
            miniIm = img(currRows, currCols, :);
            [C, scores, allscores] = semanticseg(miniIm, cnn_net);
            clean = medfilt2(uint8(C), [5 5]);
            
            output(currRows, currCols) = clean;
            imgscores(currRows, currCols) = scores;
        end
    end

    save(fullfile(SEGMENTED_DIR, sprintf("%02d", imCount) + "_out.mat"),...
        'output', 'imgscores');
end
