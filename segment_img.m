load('results/06-Aug-2020-22-29-44.mat');

pplDS = imageDatastore("../images/*_ppl.tif");
xplDS = imageDatastore("../images/*_xpl.tif");

mkdir("/scratch/network/dulrich/segmented");

imCount = 1
while hasdata(pplDS)
    img = read(pplDS);
    img(:,:,4:6) = read(xplDS);

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

    save("/scratch/network/dulrich/segmented/" + imCount + "_out.mat", 'output', 'imgscores');
    imCount = imCount + 1
end
