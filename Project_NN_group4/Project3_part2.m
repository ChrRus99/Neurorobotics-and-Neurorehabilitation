%% 2) ANALYSES ON BMI DECODING ON EACH SUBJECT
% =========================================================================
% 
% DATA:
%   - 16 EEG-channel
%   - 512 Hz
%   - 10-20 international layout
%
% EXPERIMENT:
%   - 3 days experiment
%   - 8 healty subject
%   - each subject partecipated in at least 2 recording days
%   - DAY 1: subjects performed:
%       - 3 "offline" runs (calibration, no real feedback)
%       - 2 "online" runs (with real feedback)
%   - DAY 2 and DAY 3: subjects performed:
%       - 2 "online" runs
%
% TASKS:
%   - 2 motor imagery tasks: both hands vs. both feet
%   - rest
%   - colour of cue indicates which motor imagery task perform
%   - DURING OFFLINE RUNS:
%       - feedback associated to the cue was automatically moving towards
%         the correct direction
%   - DURING ONLINE RUNS:
%       - feedback moved accordingly to the output of the classifier
%
% Author: Christian Francesco Russo
%
% =========================================================================



% =========================================================================
% IMPORTANT NOTES FOR RUNNING THE PROGRAM:
% All the following important notes are referred to this script:
%   0) Manually add the dataset folder "micontinuous" in the folder 
%     "<PROJECT_PATH>/data/"
%   1) Before running the program be sure to modify all (and only) the  
%     parts of the code indicated with the comment "[TO MODIFY]".
%   2) If the program doesn't work (i.e., if the function sload.m doesn't 
%     work properly) run manually the install.m file only for the first run
%     of the program.
%   3) There are 2 for-loops which allow to iterate all the subjects in one 
%     shot for the calibration and for the evaluation part respectively. We
%     suggest you to comment these two lines as follow:
%       % for i = 1 : num_subjects
%     and to uncomment the lines marked with the comment "[SUGGESTED]" as
%     follow:
%       for i = <manually select the index of the subject you want to run>
%     in this way you can analyze 1 subject at a time, without ploting too 
%     many plots all at once.
%   4) If you want to change some settings you can do that by the pieces of
%     code marked as "[OPTIONALLY MODIFY]", all the rest of the code is
%     supposed to work without any modifications.
%
% MATLAB VERSION USED: R2022a
%
% TOOLBOXES:
%   - Signal Processing Toolbox
%   - Statistics and Machine Learning Toolbox
%   - biosig (already included)
% =========================================================================



%% SETTINGS
clear all;  % clear all variables
close all;  % close all plots
warning('off', 'MATLAB:mpath:nameNonexistentOrNotADirectory');


%% PARAMETERS
% Variables [TO MODIFY]
root_path = "D:\MATLAB\Project_NN_group4";

% Selected features for each subject i-th [OPTIONALLY MODIFY]
selected_features_list{1} = [[7, 10]; [11, 10]; [11, 12]];      % aj1 [C3, 10], [C4, 10], [C4, 12]
selected_features_list{2} = [[7, 12]; [7, 14]; [12, 14]];       % aj3 [C3, 12], [C3, 14], [CP3, 14]
selected_features_list{3} = [[7, 12]; [8, 12]; [7, 14]];        % aj4 [C3, 12], [C1, 12], [C3, 14]
selected_features_list{4} = [[9, 22]; [9, 20]; [9, 18]];        % ai6 [Cz, 22], [Cz, 20], [Cz, 18]
selected_features_list{5} = [[16, 14]; [7, 14]; [11, 14]];      % ai7 [CP4, 14], [C3, 14], [C4, 14]
selected_features_list{6} = [[16, 10]; [11, 12]; [14, 14]];     % aj7 [CP4, 10], [C4, 12], [CPZ, 14]
selected_features_list{7} = [[7, 14]; [11, 14]; [9, 24]];       % ai8 [C3, 14], [C4, 14], [Cz, 24]
selected_features_list{8} = [[12, 12]; [16, 12]; [12, 24]];     % aj9 [CP3, 12], [CP4, 12], [CP3, 24]

% Selected thresholds for each subject i-th [OPTIONALLY MODIFY]
selected_thresholds_list{1} = [0.10, 0.85];                     % aj1
selected_thresholds_list{2} = [0.15, 0.80];                     % aj3
selected_thresholds_list{3} = [0.25, 0.80];                     % aj4  
selected_thresholds_list{4} = [0.35, 0.70];                     % ai6
selected_thresholds_list{5} = [0.35, 0.60];                     % ai7 
selected_thresholds_list{6} = [0.35, 0.65];                     % aj7
selected_thresholds_list{7} = [0.30, 0.70];                     % ai8
selected_thresholds_list{8} = [0.30, 0.60];                     % aj9

% Alpha (smoothing strength) accumulation framework for each subject i-th [OPTIONALLY MODIFY]
selected_alpha_list{1} = 0.90;                                  % aj1
selected_alpha_list{2} = 0.90;                                  % aj3
selected_alpha_list{3} = 0.90;                                  % aj4 
selected_alpha_list{4} = 0.95;                                  % ai6
selected_alpha_list{5} = 0.95;                                  % ai7
selected_alpha_list{6} = 0.95;                                  % aj7
selected_alpha_list{7} = 0.95;                                  % ai8
selected_alpha_list{8} = 0.95;                                  % aj9

% Stream of probabilities frequency [OPTIONALLY MODIFY]
pp_frequency = 16;  % [Hz]

% Directories
toolbox_path = fullfile(root_path, "toolbox\biosig-2.4.2-Windows-64bit\share\matlab");
func_path = fullfile(root_path, "functions");
helper_func_path = fullfile(func_path, "helper");
util_func_path = fullfile(func_path, "util");
data_path = fullfile(root_path, "data\micontinuous");
output_offline_path = fullfile(root_path, "data\outputs\offline");
output_online_path = fullfile(root_path, "data\outputs\online");
output_classifiers_path = fullfile(root_path, "data\outputs\classifiers");

% Subjects
num_subjects = 8;
subjects_list = ["aj1", "aj3", "aj4", "ai6", "ai7", "aj7", "ai8", "aj9"];

% Channels montage
channel_names = ["Fz", "FC3", "FC1", "FCz", "FC2", "FC4", "C3", "C1", "Cz", "C2", "C4", "CP3", "CP1", "CPz", "CP2", "CP4"];

% PSD parameters
psd_params_struct.wlenght = 0.5;                        % seconds
psd_params_struct.pshift = 0.25;                        % seconds
psd_params_struct.wshift = 0.0625;                      % seconds
psd_params_struct.mlenght = 1;                          % seconds
psd_params_struct.selected_frequencies = 4 : 2 : 48;    % Hz
psd_params_struct.winconv = 'backward';


%% INIT
% Add paths to workspace
addpath(root_path);
addpath(toolbox_path);
addpath(func_path);
addpath(helper_func_path);
addpath(util_func_path);
addpath(data_path);

% Install toolbox
run install.m
clc;    % clear the command window

% Load GDF files:
[offline_file_table, online_file_table] = GDF_files_load(data_path);



%% A) CALIBRATION PHASE OF DECODER: [training]
% =========================================================================
%   - Consider only the offline runs
%   - Process the data, compute the features, select the most disciminant 
%     features;
%   - Create a classifier based on those features.
% =========================================================================

fprintf('\n');
disp("CALIBRATION PHASE OF DECODER [training on offline files]");

% Create and calibrate a classifier for each subject
%for i = 1 : num_subjects
for i = 1   % [SUGGESTED]
    disp(strcat("SUBJECT NUMBER: ", int2str(i)));

    try
        % Extracts the manually selected data for the i-th subject
        subject = subjects_list(i);
        selected_features = selected_features_list{i};

        disp(" [SCRIPT 1]: Processing");
        script1_Processing(offline_file_table, output_offline_path, psd_params_struct, subject, i);
        fprintf('\n');
    catch
        disp(strcat("SUBJECT ", int2str(i), " DOES NOT EXIST"));
        fprintf('\n');
        continue;
    end

    disp(" [SCRIPT 2]: Feature selection");
    [~, instances, labels] = script2_Features_selection(output_offline_path, selected_features, i);
    fprintf('\n');

    disp(" [SCRIPT 3]: Classifier training");
    script3_Classification_training(instances, labels, output_classifiers_path, i);
    fprintf('\n');

    disp(" [SCRIPT 4]: Classifier evaluation on training set");
    script4_Classification_evaluation(instances, labels, output_classifiers_path, selected_features, "offline", i);
    fprintf('\n');

    fprintf('\n');
end



%% B) EVALUATION PHASE OF DECODER: [test]
% =========================================================================
%   - Consider only the online runs
%   - Process the data, compute the features, and extract those already
%     selecting during the calibration phase
%   - Use this data to evaluate the classifier created during the
%     calibration phase
%   - Implement and apply a evidence accumulation framework on the
%     posterior probabilities
% =========================================================================

fprintf('\n')
disp("EVALUATION PHASE OF DECODER [test on online files]");

% Evaluate the classifier for each subject
%for i = 1 : num_subjects   
for i = 1   % [SUGGESTED]
    disp(strcat("SUBJECT NUMBER: ", int2str(i)));

    try
        % Extracts the manually selected data for the i-th subject
        subject = subjects_list(i);
        selected_features = selected_features_list{i};
        selected_thresholds = selected_thresholds_list{i};
        selected_alpha = selected_alpha_list{i};

        disp(" [SCRIPT 1]: Processing");
        script1_Processing(online_file_table, output_online_path, psd_params_struct, subject, i);
        fprintf('\n');
    catch
        disp(strcat("SUBJECT ", int2str(i), " DOES NOT EXIST"));
        fprintf('\n');
        continue;
    end

    disp(" [SCRIPT 2]: Feature selection");
    [trials, instances, labels] = script2_Features_selection(output_online_path, selected_features, i);
    fprintf('\n');

    disp(" [SCRIPT 4]: Classifier evaluation on test set");
    [post_probabilities] = script4_Classification_evaluation(instances, labels, output_classifiers_path, selected_features, "online", i);
    fprintf('\n'); 

    disp(" [SCRIPT 5]: Accumulation framework");
    [decisions, avg_time_to_deliver_command] = script5_Evidence_accumulation_framework( ...
        post_probabilities, labels, trials, selected_alpha, selected_thresholds, pp_frequency, i);
    fprintf('\n');

    fprintf('\n');
end

