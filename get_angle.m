function angle = get_angle()
% custom function for selecting a random rotation angle. Currently rotates
% images 90, 180, 270, or 360 degrees, with a +/- 20 degree offset. This
% creates a lot of rotation possibilities while still minimizing the amount
% of unlabeled pixels in the augmented images.
%
% Devon Ulrich, 9/8/2020
    big = randi(4);
    small = randi([-20 20]);
    angle = big * 90 + small;
end