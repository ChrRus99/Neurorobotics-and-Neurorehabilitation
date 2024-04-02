function [labels_vect_struct] = labeling_data_1run(data_lenght, TYP, POS, DUR)
% This function create the labels vectors of the given data_length decoding
% the given TYP, DUR and POS, FOR 1 RUN, i.e., for 1 single file.
%
% Input:
%   - data_length: the length of the data, that will be equal to the length
%     of all the labels vectors
%   - TYP: the TYP of the event of the GDF file
%   - POS: the POS of the event of the GDF file
%   - DUR: the DUR of the event of the GDF file
%   
% Output:
%   - labels_vect_struct: a struct containing the labels vectors:
%       - start: vector of all 0's except for 1's in start periods
%       - fixation: vector of all 0's except for 1's in fixation periods
%       - cue: vector of all 0's except for 1's in cue periods
%       - feedback: vector of all 0's except for 1's in feedback periods
%       - target: vector of all 0's except for 1's in target periods
%       - trials: vector of all 0's except for 1's from (start) fixation +
%         cue + (end) feedback periods
%       - interesting_periods: vector of all 0's except for CODE's from 
%         (start) cue + (end) feedback periods
%
% Note:
%   - offline files: each trial should start from start run to continuous 
%     feedback
%   - online files: each trial should start from fixation cross to target
%     hit/miss
%
% Author: Christian Francesco Russo



    %% Define the labels vectors
    % Labels vectors
    start = zeros(data_lenght, 1);          % start trial
    fixation = zeros(data_lenght, 1);       % fixation cross
    cue = zeros(data_lenght, 1);            % cue: both hand, both feet, rest
    feedback = zeros(data_lenght, 1);       % continuous feedback
    target = zeros(data_lenght, 1);         % target hit/miss

    % Trials vector
    trials = zeros(data_lenght, 1);                 % (start) fixation + cue + (end) feedback (vector of 0's and NUM_TRIAL's)
    num_tr = 1;
    start_trial = -1;
    end_trial = -1;

    % Interesting periods vector
    interesting_periods = zeros(data_lenght, 1);    % (start) cue + (end) feedback (vector of 0's and CODE's)
    code = -1;
    start_interest = -1;
    end_interest = -1;
    

    %% Fill the labels vectors
    for i = 1 : length(TYP)
        DUR(i) = DUR(i);
        start_index = POS(i);
        end_index = POS(i) + DUR(i) - 1;
        dur_ones = ones(DUR(i), 1);
        
        % disp([TYP(i) POS(i) DUR(i)]);
        % disp([start_index end_index]);

        if TYP(i) == 1                                              % trial start
            start(start_index : end_index) = num_tr * dur_ones;
        elseif TYP(i) == 786                                        % fixation
            fixation(start_index : end_index) = dur_ones;

            start_trial = start_index;
        elseif TYP(i) == 773 || TYP(i) == 771 || TYP(i) == 783      % cue: both hand, both feet, rest
            cue(start_index : end_index) = dur_ones * TYP(i);

            start_interest = start_index;
            code = TYP(i);
        elseif TYP(i) == 781                                        % feedback
            feedback(start_index : end_index) = dur_ones;

            end_trial = end_index;
            dur_trial = end_trial - start_trial + 1;
            trials(start_trial : end_trial) = num_tr * ones(dur_trial, 1);

            end_interest = end_index;
            dur_interest = end_interest - start_interest + 1;
            interesting_periods(start_interest : end_interest) = code * ones(dur_interest, 1);

            num_tr = num_tr + 1;
        elseif TYP(i) == 897 || TYP(i) == 898                       % target hit/miss
            target(start_index : end_index) = dur_ones * TYP(i);
        else
            disp(strcat("Unknown code typ: ", string(TYP(i))));
        end   
    end

    
    %% Return labels vectors in a struct
    labels_vect_struct.start = start;
    labels_vect_struct.fixation = fixation;
    labels_vect_struct.cue = cue;
    labels_vect_struct.feedback = feedback;
    labels_vect_struct.target = target;

    labels_vect_struct.trials = trials;
    labels_vect_struct.interesting_periods = interesting_periods;
end