# U-Net Transfer Learning

![U-Net Input & Output](/media/demo-img.png)

A collection of MATLAB functions and scripts for transfer learning on a U-Net and applying it to stacks of geologic images.
Our main goal for this project was to automatically identify fossilized shells from a stack of Cambrian-era thin sections: these thin
sections of rock were imaged under PPL and XPL lighting, so we had 6 color channels of data and subsequently focused on
including all channels in our training & segmenting scripts.

## Main Files

### training_data_script.m
* This is our main script for splicing up our images and hand-drawn training data masks into 256x256x6 input images and 256x256x1 ground truth segmentations
* The script uses a few of our functions to create & augment hundreds of individual files in a separate folder, which can then be fed into our U-Net as training data

### learn_script.m
* This script is what actually trains the U-Net and outputs a network capable of segmenting our patches of rock
* It uses a pre-trained U-Net that can semantically segment 6-channel satellite imagery -- more info [here](https://www.mathworks.com/help/images/multispectral-semantic-segmentation-using-deep-learning.html)
* The script outputs a binary .mat file containing the trained network, which we can open later to test our network or fully segment our image stack
* With the settings defined in learn_script.m, we were able to achieve approximately an 85% accuracy on our validation data

### segment_script.m
* This is our script for fully segmenting our large thin section images and creating a signle-channel image of rock classes
* It feeds each 256x256 patch of input images into our own trained U-Net, and saves all images it generates as .tif files.

## Other Files

### shells/process_shells.m
* This script uses a pre-made SVM to analyze our U-Net's output images and identify possible shell fossils
* We originally wanted to train the U-Net to automatically do this task, however it had a very difficult time learning the difference between shells and other calcites since they are so similar in color, so we opted for this more typical approach to classification instead
* We used MATLAB's regionprops function to generate statistics about each connected component of calcite, such as:
  * Width
  * Height
  * Eccentricity
  * Perimeter
  * Orientation
* These stats are then fed into the SVM, which predicts whether each component is a shell fossil or not
* We created the SVM itself with MATLAB's Classification Learner app & a small sample of ~100 identified calcite components

### superpixel-tools/thin_section_script.m
* This is more of a side project for creating training data, and its main goal is to make it easier to quickly hand-draw training images
* The application code is heavily based on [this code from another research project in our lab](https://github.com/giriprinceton/cloudina/tree/master/figure_3/image_processing)

## Downloading & Using

If you want to try out this code for yourself, be sure to:
1. **Clone or download this repository**. This step is pretty self-explanatory.
2. **Look through each script file and change all directory variables**. The current scripts use file locations that are specific to our computers and server setups, so you will need to change them to get everything running.
3. **Download the multispectralUnet.mat and/or trainedCNN.mat**. Instructions for downloading & using these files are available [here](https://github.com/boltonhowes22/U_net_transfer_learning/releases/tag/v1.0).
4. **Run in MATLAB**. Our code works best in R2019b and R2020a.

## Credits and Acknowledgements
This project was created by [Bolton Howes](https://geosciences.princeton.edu/people/bolton-howes), [Ryan Manzuk](https://geosciences.princeton.edu/people/bolton-howes), and [Devon Ulrich](https://github.com/devonulrich) as part of the [Maloof Research Group](https://maloof.princeton.edu/) in Princeton's Department of Geosciences. Bolton and Ryan are currently PhD Candidates in the Maloof Group, and Devon is an undergraduate at Princeton working with the group thanks to funding from the [Princeton Environmental Institute](https://environment.princeton.edu/).
