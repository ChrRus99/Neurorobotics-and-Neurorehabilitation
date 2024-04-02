function [trials, instances, labels] = script2_Features_selection(data_path, selected_features, index_subject)
% This function executes the following processes:
% For each file of the selected subject:
%   - Load the PSD file
%   - Extract data from the PSD files and concatenate data
%   - Labels vectors creation and concatenation
%   - Computation of Fisher scores
%   - Visualization of Fisher scores
%   - Feature selection
%   - Feature/Instances extraction
%   - Labels extraction
%
% Input:
%   - data_path: the path where are stored the .mat files
%   - selected_features: the selected features to extract
%   - index_subject: the index of the selected subject to analyze
%
% Output:
%   - trials: the trials vector
%   - instances: the features matrix containing a feature vector 
%     (of the selected_features) for each window ([windows x features])
%   - labels: the label vector containing a label for each window 
%     ([windows x 1_label])
%
% References:
%   - Workflow: see "Lab04_smr_spectrogram_features_selection.pdf" pag. 3
%   - BMI scheme: see "Lesson14_classification.pdf" pag. 3
%
% Author: Christian Francesco Russo
% Contributor: Matteo Spinato
    
    

    % Channels montage
    channel_names = ["Fz", "FC3", "FC1", "FCz", "FC2", "FC4", "C3", "C1", "Cz", "C2", "C4", "CP3", "CP1", "CPz", "CP2", "CP4"];

    % Classes labels
    class_labels = [773 771 783];
    class_label_names = ["Both Hand", "Both Feet", "Rest"];

    % Data parameters
    PSD = [];
    psd_events = [];
    
    % Events parameters
    TYP = [];       % TYPe of the event
    POS = [];       % POSsition in the file
    DUR = [];       % DURation of the event
    
    % Labels vectors
    runs = [];                  % run (file) number
%     fixation = [];              % fixation cross
%     cue = [];                   % cue
%     feedback = [];              % continuous feedback
    trials = [];                % vector of 0's and NUM_TRIAL's: (start) fixation + cue + (end) feedback
    interesting_periods = [];   % vector of 0's and CODE's: (start) cue + (end) feedback

    % Avoid load errors
    data_path = fullfile(data_path, strcat("subject", int2str(index_subject)));
    addpath(data_path);

    % Find all .mat files in the data directory
    file_dir = dir(fullfile(data_path, "*.mat"));
    mat_file_list = {file_dir.name};
    
    file_index = 1;

    % Extract data from files
    for filename = mat_file_list
        disp(strcat("   FILE:[", int2str(file_index), "/", int2str(length(mat_file_list)), "]"));
        
        
        %% LOAD PSD FILE
        % Load the .mat file
        disp(strcat("   [script 2] - Load .mat PSD file: [", filename, "]"));
        data_file = load(str2mat(filename));
        

        %% EXTRACT DATA FROM PSD FILE: PSD = [windows x frequencies x channels]
        % Extract and concatenate events data from file
        disp("   [script 2] ---- Extract data from file and concatenate data");
        psd_events = data_file.psd_events_struct;
         
        % Extract and concatenate PSD from file
        curr_PSD = data_file.PSD_filt;
        PSD = vertcat(PSD, curr_PSD);

        % Extract other data from file
        freq_band = data_file.freq_band;
        psd_params_struct = data_file.psd_params_struct;
              

        %% LABEL VECTORS
        % Fill the runs vector
        [dim_window, ~, ~] = size(curr_PSD);
        runs = vertcat(runs, file_index*ones(dim_window, 1));    
        
        % Fill and concatenate the labels vectors
        disp("   [script 2] ---- Label vectors creation and concatenation");
        [labels_vect_struct] = labeling_data_1run(dim_window, psd_events.TYP, psd_events.POS, psd_events.DUR);

%         fixation = vertcat(fixation, labels_vect_struct.fixation); 
%         cue = vertcat(cue, labels_vect_struct.cue);
%         feedback = vertcat(feedback, labels_vect_struct.feedback);

        % Fill and concatenate the trials vector
        curr_trial = labels_vect_struct.trials;
        
        if length(trials) ~= 0
            temp_trial = curr_trial;

            for i = 1 : length(temp_trial)
                if curr_trial(i) > 0
                    temp_trial(i) = curr_trial(i) + max(trials); % append trials after to previous ones
                end 
            end
             
            trials = vertcat(trials, temp_trial);
        else
            trials = curr_trial;
        end

        % Fill and concatenate the interesting period vector
        interesting_periods = vertcat(interesting_periods, labels_vect_struct.interesting_periods); 
        
        fprintf('\n');
        file_index = file_index + 1;
    end

    
    %% FISHER SCORES
    disp("   FILES DATA CONCATENATION:")
    disp("   [script 2] ---- Compute Fisher scores");
    PSD_power = log(PSD);   % [dB]
    class_labels = class_labels(1:2);

    [num_windows, num_freqs, num_chns] = size(PSD);
    num_run = length(unique(runs));

    FisherScore = nan(num_freqs, num_chns, num_run);

    for i = 1 : num_run                     % iterate files
        cmu = nan(num_freqs, num_chns, 2);
        csigma = nan(num_freqs, num_chns, 2);

        for j = 1 : length(class_labels)    % iterate classes of tasks
            cmu(:, :, j) = squeeze(mean(PSD_power(runs == i & interesting_periods == class_labels(j), :, :)));
            csigma(:, :, j) = squeeze(std(PSD_power(runs == i & interesting_periods == class_labels(j), :, :)));
        end

        FisherScore(:, :, i) = abs(cmu(:, :, 2) - cmu(:, :, 1)) ./ sqrt((csigma(:, :, 1).^2 + csigma(:, :, 2).^2));
    end

    
    %% VISUALIZATION FISHER SCORES
    disp("   [script 2] ---- Visualization of Fisher scores");
    figure;
    num_cols = 2;
    num_rows = ceil(num_run / num_cols);
    num_plot = num_cols*num_rows;
    modality = "Unknown";
    day = 1;
    
    for i = 1 : num_run
        % Plot Fisher score grid: runs
        subplot(num_rows, num_cols, i);
        imagesc(FisherScore(:, :, i)');

        % Add features to plot 
        axis square;
        set(gca, "XTick", 1 : num_freqs);
        set(gca, "XTickLabel", freq_band);
        set(gca, "YTick", 1 : num_chns);
        set(gca, "YTickLabel", channel_names);
        colorbar;
        clim([0 (min(max(max(FisherScore)))+0.2)]);

        if(contains(filename{1}, "offline"))
            title(strcat("Calibration: [run: ", num2str(i), "]"));
            modality = "training";
        elseif(contains(filename{1}, "online"))
            title(strcat("Evaluation: [run: ", num2str(i), " , day: ", num2str(day), "]"));
            modality = "test";
            if(mod(i, 2) == 0)
                day = day + 1;
            end
        end
    end

    sgtitle(strcat("Fischer score on ", modality, " set: [Subject: ", int2str(index_subject), "]"));


    %% FEATURES SELECTION
    disp("   [script 2] ---- Features selection");
    % Features selected da input %
    num_features = length(selected_features);


    %% FEATURES EXTRACTION: feature_vectors = [windows x 3_PSD_powers]
    disp('   [script 2] ---- Features extraction');
    channels_selected = channel_names(selected_features(:, 1));
    frequencies_selected = selected_features(:, 2);
    [~, chn_selected_indexes] = ismember(channels_selected, channel_names);
    [~, freq_selected_indexes] = ismember(frequencies_selected, freq_band);
    
    feature_vectors = NaN(num_windows, num_features);

    for i = 1 : num_features        % iterate features
        curr_chan_index = chn_selected_indexes(i);
        curr_freq_index = freq_selected_indexes(i);
        
        for j = 1 : num_features    % iterate features        
            if(selected_features(j, :) == [curr_chan_index freq_band(curr_freq_index)])
                feature_vectors(:, i) = PSD_power(:, curr_freq_index, curr_chan_index);
            end
        end
    end
    

    %% LABELS EXTRACTION: (labels = [windows x 1_label])
    disp("   [script 2] ---- Labels extraction");
    labels = interesting_periods; % to simplify in the next


    %% OUTPUT OF THIS FUNCTION
    trials = trials;
    instances = feature_vectors;
    labels = labels;
end