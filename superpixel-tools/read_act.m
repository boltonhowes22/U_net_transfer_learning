function [colors] = read_act(filepath, num_colors)
% reads a color palette (.act) file
% returns its data as a num_colors x 3 matrix
    fileID = fopen(filepath, 'r');
    colors = fread(fileID, [3, num_colors], 'uint8');
    
    colors = colors';
end

