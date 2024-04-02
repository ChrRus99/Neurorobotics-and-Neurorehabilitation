function [post_probabilities] = script4_Classification_evaluation(instances, labels, classifier_path, selected_features, modality, index_subject)
% This function executes the following processes:
% For each subject:
%   - Load the pretrained classifier of the selected subject
%   - Prediction on the given instances
%   - Visualization of the data distribution and of the classifier
%   - Evaluation of accuracy on the given instances
%   - Visualization of the overall accuracy and of the classes accuracy
%
% Input:
%   - instances: the matrix containing the instances for each window
%   - labels: the vector containing the label of each window
%   - classifier_path: the path where is saved the .mat classifier
%   - selected features: the selected features
%   - modality: "offline"/"online"
%   - index_subject: the index of the selected subject for whom create the
%     classifier
%
% Output:
%   - post_probabilites: a matrix containing the 2 poterior probabilities 
%     predicted by the classifier for each window
%
% Author: Christian Francesco Russo



    % Extract the features selected
    channel_features = unique(selected_features(:, 1))';
    frequency_features = unique(selected_features(:, 2))';

    % Channels montage
    channel_names = ["Fz", "FC3", "FC1", "FCz", "FC2", "FC4", "C3", "C1", "Cz", "C2", "C4", "CP3", "CP1", "CPz", "CP2", "CP4"];

    % Classes of tasks
    class_labels = [771 773];
    class_labels_names = ["Both Feet", "Both Hands"];

    % Modality: {offline, online}
    evaluation_modality = "Unkwnown";
    if modality == "offline"
        evaluation_modality = "training";
    elseif modality == "online"
        evaluation_modality = "test";
    end

    
    %% LOAD THE PRETRAINED MODEL
    filename = strcat("Model", int2str(index_subject), ".mat");
    disp(strcat("   [script 4] - Load the pretrained classifier of subject: ", filename));

    classifier_path = fullfile(classifier_path, strcat("subject", int2str(index_subject)));
    addpath(classifier_path);

    model = load(str2mat(fullfile(classifier_path, filename)));
    Model = model.Model;

    
    %% PREDICTION
    disp(strcat("   [script 4] ---- Prediction on ", evaluation_modality, " set"));
    [predictions, post_probabilities] = predict(Model, instances);


    %% VISUALIZATION OF DATA DISTRIBUTION AND CLASSIFIER (FOR THE FIRST 2 FEATURES)
    disp("   [script 4] ---- Visualization of data distribution and classifier (for the first 2 features)");
    tasks_periods = labels == 771 | labels == 773;

    % Plot the first 2 features of the data distribution
    figure;
    gscatter(instances(tasks_periods, 1), instances(tasks_periods, 2), labels(tasks_periods), "kb", "ov^", [], "off");
    hold on;
    
    % Create the appropiate function for the kind of classifier
    if Model.DiscrimType == "linear"            % LDA classifier
        K = Model.Coeffs(1,2).Const;
        L = Model.Coeffs(1,2).Linear;
        f = @(x1, x2) K + L(1)*x1 + L(2)*x2;
    elseif Model.DiscrimType == "quadratic"     % QDA classifier
        K = Model.Coeffs(1,2).Const;
        L = Model.Coeffs(1,2).Linear;
        Q = Model.Coeffs(1,2).Quadratic;
        f = @(x1, x2) K + L(1)*x1 + L(2)*x2 + Q(1,1)*x1.^2 + (Q(1,2) + Q(2,1))* x1.*x2 + Q(2,2)*x2.^2;
    else                                        % unsupported classifier
        ME = MException(strcat("The classifier type: [", Model.DiscrimType, "] is not supported"));
        throw(ME);
    end

    % Plot the function of the classifier
    fimplicit(f, Color="r", LineWidth=2);
    hold off;

    % Add features to plot 
    grid on;
    axis square;
    xlabel(strcat(channel_names(channel_features(1)), "@", num2str(frequency_features(1)), "Hz"));
    if length(channel_features) < 2
        ylabel(strcat(channel_names(channel_features(1)), "@", num2str(frequency_features(2)), "Hz"));
    elseif length(frequency_features) < 2
        ylabel(strcat(channel_names(channel_features(2)), "@", num2str(frequency_features(1)), "Hz"));
    else
        ylabel(strcat(channel_names(channel_features(2)), "@", num2str(frequency_features(2)), "Hz"));
    end
    xlim([-6 2]);
    ylim([-6 2]);
    legend("Both feet", "Both hands", "Boundary");

    title(strcat("Classifier space of two features on ", evaluation_modality, " set: [Subject: ", int2str(index_subject), "]"));
    
    
    %% EVALUATION OF OVERALL AND SINGLE CLASS ACCURACIES
    disp("   [script 4] ---- Evaluation of overall accuracy and single class accuracy");

    % Compute the overall accuracy (for both classes)
    accuracy_overall = 100 * sum(predictions(tasks_periods, :) == labels(tasks_periods)) ./ length(predictions(tasks_periods));

    % Compute the accuracy of the two classes separately
    num_classes = length(class_labels);
    accuracy_classes = nan(num_classes, 1);

    for i = 1 : num_classes
        accuracy_classes(i) = 100 * sum(predictions(labels == class_labels(i)) == labels(labels == class_labels(i))) ./ length(predictions(labels == class_labels(i)));
    end
    

    %% VISUALIZATION OF ACCURACY GRAPHS
    disp("   [script 4] ---- Visualization of overall accuracy and classes accuracy");

    % Plot the bar graphs of the overall accuracy and of the classes accuracy
    figure;
    Y = [accuracy_overall; accuracy_classes];
    bar(Y);

    % Add features to plot 
    grid on;
    set(gca, "XTickLabel", {"Overall", class_labels_names(1), class_labels_names(2)});
    ylabel("Accuracy [%]");
    ylim([0 100]);
    text(1:length(Y'),Y',num2str(Y),'vert','bottom','horiz','center');
    
    title(strcat("Single sample accuracy on ", evaluation_modality, " set: [Subject: ", int2str(index_subject), "]"));


    %% OUTPUT OF THIS FUNCTION
    post_probabilities = post_probabilities;
end