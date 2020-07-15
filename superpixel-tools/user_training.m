function output_img = user_training(img, num_pixels, classes, colors)
% Creates an indexed-color training mask by manually filling in superpixel regions
% Opens a figure window for the user to click each superpixel and add it to
% one of their specified classes.
%
% IN
% img: the image to segment. This function opens the entire image and
% creates superpixels on it, so it may be helpful to use another script to
% divide up large input images into smaller chunks, and only create
% training data for one chunk at a time.
% 
% num_pixels: the maximum number of superpixels to split img into.
%
% classes: a string vector containing all the classes that you want to use,
% in the correct order. This function will number all pixels assigned to
% the first class as #1, all pixels to the second class as #2, etc. Any
% regions not assigned to a specific class will have a value of 0 in
% output_img.
%
% colors: An optional (length(classes) x 3) matrix that specifies RGB
% colors for each class. This field is required when segmenting the image
% into more than 6 classes, and all matrix values must be doubles from 0 to
% 1.
%
% OUT
% output_img: the indexed-color image matrix that stores the classes of all
% pixels in img. Each class number corresponds with the class indcides in
% 'classes', and any unlabeled pixels have a default value of 0.
%
% Created by Akshay Mehra. Modified by Devon Ulrich.
    global global_collector;
    close all
    
    % default colormap
    if ~exist('colors', 'var')
        colors = [1, 0, 0;...
                  0, 1, 0;...
                  0, 0, 1;...
                  1, 1, 0;...
                  1, 0, 1;...
                  0, 1, 1];
        if length(classes) > 6
            warning("A custom color palette is required when using more than 6 classes");
        end
    end
    %% Process Superpixels + Produce Training Set
    % Blur the image
    blurred_img = imgaussfilt(img, 2);
    % Get the superpixels
    label = superpixels(blurred_img, num_pixels);
    
    % BW boundaries from label image
    bw_mask = boundarymask(label);
    % First, display the image
    imshow(imoverlay(img, bw_mask, 'cyan'));
    % Add UI element
    btn = uicontrol('Style', 'pushbutton',...
        'Position', [20 20 150 20],...
        'Callback', 'uiresume()');
    % Get the image size
    [img_y, img_x, ~] = size(img);
    two_d_img = [img_y, img_x];
    
    % make output image
    output_img = uint8(zeros(two_d_img));
    
    % Number of classes
    number_classes = length(classes);
    for y = 1:number_classes
        % Create a mask overlay
        % First, produce an influence matrix
        influence = zeros(two_d_img);
        mask_elements = zeros(two_d_img);
        hold on
        % show all previously classified superpixels
        tempout = imshow(labeloverlay(img, output_img,...
            'Colormap', colors, 'Transparency', 0));
        % show the regions that the user is currently selecting
        mask = imshow(mask_elements);
        hold off
        % modify the transparency of each overlay so only the correct
        % superpixels are shown
        tempout.AlphaData = (output_img ~= 0);
        mask.AlphaData = influence;
        mask.ButtonDownFcn = {@cursor_callback, label, mask};
        mask.HitTest = 'on';
        
        % Show graph window; bring the image to the front
        shg;

        global_collector = [];
        % Set the button string
        button_string = 'Next Class';
        if y == number_classes
            button_string = 'Finish Image';
        end
        btn.String = button_string;
        % remove interpreter to make underscores appear normally
        title(['Defining ', classes{y}, ' Class'], 'Interpreter', 'none');
        % Now, wait until continue is hit
        uiwait
        
        % Now, let's go through and save these values
        output_img(ismember(label, global_collector)) = y;
        
        % Delete the overlays
        delete(mask)
        delete(tempout)
        % Move on
        if y == number_classes
            close;
        end
    end
end