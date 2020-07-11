function quick_check(im, net)
% quickly check the output of the network
%% Inputs
% im: image
% network
%% Outputs
% none
% ================================= Begin =================================
C = semanticseg(im, net); %

B = labeloverlay(im(:,:,1), C);
figure
subplot(1,2,2)
imshow(B)

subplot(1,2,1)
imshow(im(:,:,1:3))

end