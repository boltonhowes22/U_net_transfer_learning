function [ready_lgraph] = transfer_ready(pretrained_net, last_fixed_layer,...
    n_classes, class_list, new_learnrate_factor, dice_loss, classWeights)
% This function takes a downloaded, pretrained DAGNetwork and prepares it
% for transfer learning by fixing the weights of layers to a desired depth
% and replacing learnable layers past that depth
%
% IN 
% pretrained_net: DAGNetwork of the downloaded, pretrained net for transfer
% learning
%
% last_fixed_layer: The numerical index on the last layer that will remain
% fixed throughout transfer learning. All learnable layers downstream of
% this will be reset and re-trained
% 
% n_classes: The number of output classes
%
% class_list: curly bracketed cell array with strings giving the name of
% each class
%
% new_learnrate_factor: Numerical learn rate factor for the replace layers.
% When training a network from scratch, this number usually is 1. In
% transfer learning, much of the literature suggests this number be 10 to
% speed the new learning of replaced layers. 
%
% dice_loss: logical flag to replace the pixel classification layer to one
% using the dice loss function. 1 for dice loss, 0 for crossentropy.
%
% classWeights: predefined class weights to use if dice_loss == 0
%
% OUT
% ready_lgraph: Layer graph of a network with the original architecture and
% fixed weights up to the desired depth. The rest of the layers are
% replaced and ready to transfer learn
%
% R. A. Manzuk, 06/27/2020

    %% begin the function
    % we need the net to be in lgraph format for transfer learning
    lgraph = layerGraph(pretrained_net);

    % and it'll help to have the layers and connections as their own variable
    layers = lgraph.Layers;
    connections = lgraph.Connections;

    % how many layers are there? for bookkeeping
    n_layers = numel(layers);

    % and which layers are convolutional? Useful for bookkeeping as well
    conv_index = [];
    for q = 1:numel(layers)
        conv_index(q) = isa(layers(q), 'nnet.cnn.layer.Convolution2DLayer');
    end

    % hold the final conv layer as its own thing
    final_conv_ind = find(conv_index,1,'last');
    conv_index(final_conv_ind) = 0;

    % don't forget about transposed convolutions
    tran_conv_index = [];
    for q = 1:numel(layers)
        tran_conv_index(q) = isa(layers(q), 'nnet.cnn.layer.TransposedConvolution2DLayer');
    end

    % replace all convolution layers (except final) in the desired part of the network
    for i = (last_fixed_layer+1):n_layers
        if conv_index(i)
            new_conv_layer = convolution2dLayer(layers(i,1).FilterSize,layers(i,1).NumFilters,...
                'NumChannels',layers(i,1).NumChannels,'Name',layers(i,1).Name,'Stride',layers(i,1).Stride,...
                'DilationFactor',layers(i,1).DilationFactor,'Padding',layers(i,1).Padding, ...
                'WeightsInitializer',layers(i,1).WeightsInitializer, 'BiasInitializer', layers(i,1).BiasInitializer, ...
                'WeightLearnRateFactor',new_learnrate_factor, 'BiasLearnRateFactor', new_learnrate_factor);
            lgraph = replaceLayer(lgraph, layers(i,1).Name, new_conv_layer);  
        end
    end

    % replace all transposed convolution layers in the desired part of the network
    for i = (last_fixed_layer+1):n_layers
        if tran_conv_index(i)
            new_tconv_layer = transposedConv2dLayer(layers(i,1).FilterSize,layers(i,1).NumFilters,...
                'NumChannels',layers(i,1).NumChannels,'Name',layers(i,1).Name,'Stride',layers(i,1).Stride,...
                'Cropping',layers(i,1).Cropping, ...
                'WeightsInitializer',layers(i,1).WeightsInitializer, 'BiasInitializer', layers(i,1).BiasInitializer, ...
                'WeightLearnRateFactor',new_learnrate_factor, 'BiasLearnRateFactor', new_learnrate_factor);
            lgraph = replaceLayer(lgraph, layers(i,1).Name, new_tconv_layer);  
        end
    end

    % replace final conv with n_filters defined by the number of classes
    final_conv_layer = convolution2dLayer(layers(final_conv_ind,1).FilterSize,n_classes,...
                'NumChannels',layers(final_conv_ind,1).NumChannels,'Name',layers(final_conv_ind,1).Name,'Stride',layers(final_conv_ind,1).Stride,...
                'DilationFactor',layers(final_conv_ind,1).DilationFactor,'Padding',layers(final_conv_ind,1).Padding, ...
                'WeightsInitializer',layers(final_conv_ind,1).WeightsInitializer, 'BiasInitializer', layers(final_conv_ind,1).BiasInitializer, ...
                'WeightLearnRateFactor',new_learnrate_factor, 'BiasLearnRateFactor', new_learnrate_factor);

    lgraph = replaceLayer(lgraph, layers(final_conv_ind,1).Name,final_conv_layer);
            
    % replace softmax
    new_softmax = softmaxLayer('Name',layers(end-1,1).Name);
    lgraph = replaceLayer(lgraph, layers(end-1,1).Name,new_softmax);

    % replace classification
    if dice_loss
        new_classification = dicePixelClassificationLayer('Name',layers(end,1).Name,'Classes',class_list);
    else
        new_classification = pixelClassificationLayer('Name',layers(end,1).Name,'Classes',class_list, 'ClassWeights', classWeights);
    end
    lgraph = replaceLayer(lgraph, layers(end,1).Name, new_classification);

    % grab the layers from the lgraph again because we changed them
    layers = lgraph.Layers;

    % freeze all of the early layers 
    for i = 1:last_fixed_layer
        if isprop(layers(i),'WeightLearnRateFactor')
            layers(i).WeightLearnRateFactor = 0;
        end
        if isprop(layers(i),'WeightL2Factor')
            layers(i).WeightL2Factor = 0;
        end
        if isprop(layers(i),'BiasLearnRateFactor')
            layers(i).BiasLearnRateFactor = 0;
        end
        if isprop(layers(i),'BiasL2Factor')
            layers(i).BiasL2Factor = 0;
        end
    end

    % and make these newly fixed layers with the replaced layers into a layer
    % graph
    ready_lgraph = layerGraph(layers);

    % check for missing connections that were in the original net!
    connections2 = ready_lgraph.Connections;
    missing_connections  = setdiff(connections, connections2);

    % and connect those babies!
    for i = 1:size(missing_connections,1)
        ready_lgraph = connectLayers(ready_lgraph, string(missing_connections{i,1}),string(missing_connections{i,2}));
    end

end