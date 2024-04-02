function [] = script1_Processing(GDF_file_list, output_path, psd_params_struct, subject, index_subject)
% This function executes the following processes: 
% For each file of the selected subject:
%   - Load the EEG signal
%   - Apply the spatial filter: Laplacian filter
%   - Compute the PSD transform: improved Welch's method 
%   - Extract the PSD in the selected frequency band
%   - Save PSD data: as .mat file in the given output_path
% 
% Input:
%   - GDF_file_list: list of GDF files to process
%   - output_path: the path where saving the .mat processed files
%   - psd_params_struct: a struct containing the PDS settings parameters
%   - index_subject: the index of the selected subject to analyze
%
% Output:
%   - [none]
%
% References: 
%   - Workflow: see "Lab04_smr_spectrogram_features_selection.pdf" pag. 3
%   - Procedure: see "A04_spectogram_features_selection.pdf" pag. 1
%   - Spectrogram: see "Lab04_smr_spectrogram_features_selection.pdf" pag. 5
%
% Author: Christian Francesco Russo


   
    % PSD parameters
    wlenght = psd_params_struct.wlenght;
    pshift = psd_params_struct.pshift;
    wshift = psd_params_struct.wshift;
    mlenght = psd_params_struct.mlenght;
    selected_frequencies = psd_params_struct.selected_frequencies;
    winconv = psd_params_struct.winconv;

    file_index = 1;
    is_subject_existing = false;

    % Processing
    for filename = GDF_file_list
        % Load the files of the selected subject
        %if contains(filename{1}([1:3]), int2str(index_subject))
        if contains(filename{1}([1:3]), subject)
            disp(strcat("   FILE:[", int2str(file_index), "]"));

            %% EEG SIGNAL: s = [samples x channels]
            % Load the GDF file
            disp(strcat("   [script 1] - Load GDF file: [", filename, "]"));
            [s, h] = sload(str2mat(filename));
        

            %% SPATIAL FILTER: s_lap = [samples x channels]
            % Laplacian filter
            disp("   [script 1] ---- Spatial filter: Laplacian filter");
            load("laplacian16.mat");    % lap = [channels x channels]
            s = s(:, 1:16);             % erase the last channel which is useless
            s_lap = s * lap;   


            %% PSD TRANSFORM: PSD = [windows x frequencies x channels]
            % Spectrogram: improved Welch's method 
            disp("   [script 1] ---- PSD transform: improved Welch's method");
            SampleRate = h.SampleRate;
            [PSD, f] = proc_spectrogram(s_lap, wlenght, wshift, pshift, SampleRate, [, mlenght]);


            %% PSD IN SELECTED FREQUENCY BAND: PSD_filt = [windows x frequencies x channels]
            % PSD extraction in the selected frequency band
            disp("   [script 1] ---- PSD extraction in the selected frequency band");
            [freq_band, index_band] = intersect(f, selected_frequencies);
            PSD_filt = PSD(:, index_band, :);   % extract the PSD in the selected frequency band


            %% SAVE PSD DATA 
            % PSD events struct building
            disp("   [script 1] ---- PSD events struct building");
            events = h.EVENT;
            psd_events_struct.TYP = events.TYP;                                                                  % Same events type as before
            psd_events_struct.POS = proc_pos2win(events.POS, wshift*SampleRate, winconv, mlenght*SampleRate);    % POS(in windows): rescale events positions in file: time -> windows
            psd_events_struct.DUR = floor(events.DUR/(wshift*SampleRate)) + 1;                                   % DUR(in windows): rescale events durations: time -> windows
            psd_events_struct.conv = winconv;

            % Create the subdirectory to save the data of subject i-th
            subj_output_path = fullfile(output_path, strcat("subject", int2str(index_subject)));
            
            if ~exist(subj_output_path, 'dir')  % create the subdirectory if it does not exist
                mkdir(subj_output_path);
            end
                        
            % Save PSD data in file .mat
            data_filename = strrep(string(filename), ".gdf", ".mat");
            file_path = fullfile(subj_output_path, data_filename);
            disp(strcat("   [script 1] - Save PSD data in file: [", data_filename, "]"));
            save(file_path, "PSD_filt", "freq_band", "psd_events_struct", "psd_params_struct", "SampleRate");


            fprintf('\n');
            file_index = file_index + 1;
            is_subject_existing = true;
        end
    end

    % Throw an exception if the subject's files do not exist
    if ~is_subject_existing
        ME = MException(strcat("SUBJECT ", int2str(index_subject), " FILES DO NOT EXIST"));
        throw(ME);
    end
end