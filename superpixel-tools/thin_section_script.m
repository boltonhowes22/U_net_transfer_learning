% An example script of using user_training to produce initial training data
% for a large thin-section image. Saves the training data as an
% indexed-color image which can then be opened in Photoshop or fed into a
% neural network as training data.
%
% Devon Ulrich, 7/15/2020

%% load a specific image & all the required classifying data
im = imread("../../images/unused/RLG_80 _ppl.tif");

colorLabels = ["circ_shell" "sponge_spicule" "renalcid_texture" "oxide"...
    "speckled_fill" "misc_shell" "archaeo" "not_rock" "trilobite"...
    "crystal_calcite" "clay_layer" "gray_hash" "orientation_hole"...
    "peloidal" "stylolite" "calcimicrobe" "homogenous_fill" "unlabeled"];

% read our colors3.act palette, so the colors in Matlab are the same as
% what we use in Photoshop
colors = read_act("../../psds/colors3.act", 18);
colors = colors / 255; % convert from 0-255 to 0-1

% create a blank matrix for our tracing output
totalTracings = uint8(zeros(size(im,1), size(im,2)));

%% repeat picking a spot & tracing it over and over again
for i = 1:5
    imshow(labeloverlay(im, totalTracings,...
        'Colormap', colors, 'Transparency', 0));
    % draw some grids to show what sections can be selected
    hold on
    
    % side length of each square
    gridWidth = 512;
    for row = 1:gridWidth:size(im,1)
        line([1, size(im,2)], [row, row], 'Color', 'w', 'LineWidth', 2);
    end
    
    for col = 1:gridWidth:size(im,2)
        line([col, col], [1,size(im,1)], 'Color', 'w', 'LineWidth', 2);
    end
    
    % get a specific gridWidth x gridWidth square to segment with
    % user_training
    coords = ginput(1);
    
    xStart = floor(coords(1) / gridWidth) * gridWidth + 1;
    xEnd = xStart + gridWidth - 1;
    yStart = floor(coords(2) / gridWidth) * gridWidth + 1;
    yEnd = yStart + gridWidth - 1;
    
    % call user_training on the smaller image patch, and save the output to
    % totalTracings
    miniIm = im(yStart:yEnd, xStart:xEnd, :);
    tracings = user_training(miniIm, 50, colorLabels(1:end-1), colors);
    totalTracings(yStart:yEnd, xStart:xEnd) = tracings;
end

%% save the user-created image
% make sure everything that isn't traced is classified correctly
totalTracings(totalTracings == 0) = 18;
% change from 1-indexed to 0-indexed, and save!
imwrite((totalTracings-1), colors, "test.tif");