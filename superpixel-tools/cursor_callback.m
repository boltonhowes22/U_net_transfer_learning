function [] = cursor_callback(source, ~, label, mask)
    global global_collector;
    label_size = size(label);
    % Okay, now grab the screen coordinates
    coordinates = fix(source.Parent.CurrentPoint(1,1:2,1));
    col_coordinate = coordinates(1);
    row_coordinate = coordinates(2);
    % Get index of label
    label_index = sub2ind(label_size, row_coordinate, col_coordinate);
    label_value = label(label_index);
    % Now, check to see if the label value is already in the global
    % collector
    if ismember(label_value, global_collector)
        global_collector = global_collector(global_collector ~= label_value);
    else
        global_collector = [global_collector; label_value];
    end
    idx = find(ismember(label, global_collector));
    masking = zeros(label_size);
    masking(idx) = .5;
    mask.AlphaData = masking;
end