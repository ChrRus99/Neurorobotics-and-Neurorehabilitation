function [] = script3_Classification_training(instances, labels, classifier_path, index_subject)
% This function executes the following processes:
% For the selected subject:
%   - Select the appropiate classifier (LDA or QDA) on the base of the 
%     equality of the covariance matrix of the distribution of the two 
%     classes of instances
%   - Training of the selected classifier using the given instances and 
%     labels
%   - Save the classifier as .mat file in the given classifier_path
%
% Input:
%   - instances: the matrix containing the instances for each window
%   - labels: the vector containing the label of each window
%   - classifier_path: the path where saving the .mat classifier
%   - index_subject: the index of the selected subject for whom create the
%     classifier
%
% Output:
%   - [none]
%
% Author: Christian Francesco Russo
% Contributor: Matteo Spinato


    
    %% SELECT THE APPROPIATE CLASSIFIER
    disp("   [script 3] ---- Select the appropiate classifier");
    tasks_periods = labels == 771 | labels == 773;

    % Compute the covariance matrix to select the kind of classifier to use
    first_distr_cov = cov(instances(labels == 771, :));
    second_distr_cov = cov(instances(labels == 773, :));


    %% CLASSIFIER TRAINING
    if isequal(first_distr_cov, second_distr_cov)   % the two classes have the same covariance matrix
        % Create a linear classifier (LDA)
        disp("   [script 3] ---- Training of the linear classifier (LDA)");
        Model = fitcdiscr(instances(tasks_periods, :), labels(tasks_periods), DiscrimType="linear");
    else                                            % the two classes have different covariance matrix
        % Create a quadratic classifier (QDA)
        disp("   [script 3] ---- Training of the quadratic classifier (QDA)");
        Model = fitcdiscr(instances(tasks_periods, :), labels(tasks_periods), DiscrimType="quadratic");
    end
    

    %% SAVE CLASSIFIER
    % Create the subdirectory to save the classifier of the subject i-th
    subj_classifier_path = fullfile(classifier_path, strcat("subject", int2str(index_subject)));
    
    if ~exist(subj_classifier_path, 'dir')  % create the subdirectory if it does not exist
        mkdir(subj_classifier_path);
    end
                
    % Save PSD data in file .mat
    data_filename = strcat("Model", int2str(index_subject), ".mat");
    file_path = fullfile(subj_classifier_path, data_filename);
    disp(strcat("   [script 3] - Save classifier in file: [", data_filename, "]"));
    save(file_path, "Model");


    %% OUTPUT OF THIS FUNCTION
    Model = Model;
end