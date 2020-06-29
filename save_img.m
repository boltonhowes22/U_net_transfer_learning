function save_img(img, filename)
% Saves a multi-channel image matrix as a .tiff file
%
% IN
%
% img: the 3-dimensional image matrix. Dimensions should be in the order
% Length x Width x Channels, and all values should be uint16. The number of
% channels can be anything, but this function works best with 4+ channels. 
%
% filename: a string with the desired path & name for the image
%
% Devon Ulrich, 6/29/2020
    tif = Tiff(filename, 'w');
    tagstruct.ImageLength = size(img, 1);
    tagstruct.ImageWidth = size(img, 2);
    tagstruct.SampleFormat = 1;
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample = 16;
    tagstruct.SamplesPerPixel = size(img, 3);
    tagstruct.ExtraSamples = Tiff.ExtraSamples.Unspecified;
    tagstruct.Compression = Tiff.Compression.None;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';
    
    % Note: the Tiff library will always throw a warning when saving these
    % images, which says that the number of channels being saved is not the
    % same as the number of channels listed in the options above. This can
    % be ignored for now, and there does not seem to be any way to get rid
    % of the warning when saving images with over 4 channels.
    setTag(tif, tagstruct);
    tif.write(img);
    tif.close();
end