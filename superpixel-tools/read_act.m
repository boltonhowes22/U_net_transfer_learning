function [colors] = read_act(filepath, num_colors)
% reads a color palette (.act) file
% returns its data as a num_colors x 3 matrix
%
% Devon Ulrich, 7/13/2020
    fileID = fopen(filepath, 'r');
    colors = fread(fileID, [3, num_colors], 'uint8');
    
    colors = colors';
end

