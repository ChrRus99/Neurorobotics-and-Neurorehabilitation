function [decisions, avg_time_to_deliver_command] = script5_Evidence_accumulation_framework(post_probabilities, labels, trials, alpha, thresholds, pp_frequency, index_subject)
% This function executes the following processes:
% For each subject:
%   - Compute the evidence accumulation framework for each trial
%   - Visualization of the evidence accumulation framework
%   - Evaluation of the trial accuracy without and with rejection
%
% Input:
%   - post_probabilities: the matrix containing the 2 poterior probabilities 
%     predicted by the classifier for each window
%   - labels: the vector containing the label of each window
%   - trials: the trials feature vector
%   - alpha: the smoothing parameter ([0, 1])
%   - tresholds: [lower_threshold, upper_threshold], with lower_threshold,
%     upper_threshold in [0, 1] and lower_threshold <= upper_threshold
%   - pp_frequency: the #pp generated in output per second
%   - index_subject: the index of the selected subject for whom create the
%     classifier
%
% Output:
%   - decisions: a vector containing a decision of the decoder for each
%     trial
%   - avg_time_to_deliver_command: the average time to deliver a comand
%     knowing the pp_frequency (output stream frequency)
%
% Author: Christian Francesco Russo



    % Classes of tasks
    class_labels = [771 773];
    class_labels_names = ["Both Feet", "Both Hands"];
    tasks_periods = labels == 771 | labels == 773;
    
    num_trials = max(trials);

    % The vector of the decision taken for each trial: [trials x 1_decision]
    decisions = nan(num_trials, 1);

    % The ground truth vector: [trials x 1_label]
    ground_truth = nan(num_trials, 1);

    % The list of number of pp to make the decision
    pp_to_decision_list = zeros(num_trials, 1);

    %% EVIDENCE ACCUMULATION FRAMEWORK
    disp("   [script 5] ---- Evidence accumulation framework for each trial");

    for i = 1 : num_trials
        % Extract one posterior probability for each window in the current trial
        % where each trial starts from (start) fixation and end to (end) feedback
        pp = post_probabilities(trials == i & tasks_periods == 1);  

        % Consider only the posterior probability of boot feet
        % (thus, if pp(t)->1 => D=both feet, otherwise if pp(t)->0 => D=both hands)
        pp = pp(:, 1);  
        num_windows = length(pp);

        % Reset control framework
        D = zeros(num_windows, 1);
        D(1) = [0.5];

        % Point in which the decision is made (cross point on one threshold)
        is_decision_made = 0;
        decision_point = [0 0];

        % Number of pp to take the decision
        pp_to_decision = 1;

        for t = 2 : num_windows
            % Compute the formula for the accumulation framework
            D(t) = D(t-1) * alpha + pp(t) * (1-alpha);

            % When D(t) cross one of the two thresholds the decision is made
            if D(t) <= thresholds(1) && ~is_decision_made        % Both Hands
                decisions(i) = 773;     
                is_decision_made = 1;
                decision_point = [t, D(t)];
            elseif D(t) >= thresholds(2) && ~is_decision_made    % Both Feet
                decisions(i) = 771;     
                is_decision_made = 1;
                decision_point = [t, D(t)];
            end

            if ~is_decision_made
                pp_to_decision = pp_to_decision + 1;
            end
        end

        % Fill the  list of number of pp to make the decision
        pp_to_decision_list(i) = pp_to_decision;

        % Fill the ground truth vector with the expected class label for this trial
        ground_truth(i) = unique(labels(trials == i & tasks_periods == 1));


        %% VISUALIZATION OF EVIDENCE ACCUMULATION
        if i == 55 %|| (i >= 1 && i<=10) % Plot for only 1 trial
            disp(strcat("   [script 5] ---- Visulization of the evidence accumulation framework for example trial: ", int2str(i)));

            figure;
        
            % Plot the pp's points
            plot([1 : length(pp)]', pp, "o", "markersize", 4, "Color", "k");
            hold on;
        
            % Plot the accumulation framework function
            plot(D, Color="k", LineWidth=2);
            hold on;
        
            % Plot the thresholds lines
            yline([thresholds], "-r", {"Th2: Both Hands", "Th1: Both Feet"});
            hold on;
            yline([0.5], "--k");
            hold on;

            % Plot the point in which the decision is made
            if decision_point > [0, 0]
                plot(decision_point(1), decision_point(2), "o", "markersize", 10, "Color", "r", "LineWidth", 2);
            end
            hold off;

            % Add features to plot 
            grid on;
            xlabel("Sample");
            ylabel("Probability/Control");
            ylim([0 1]);
            
            label_name = class_labels_names(find(class_labels == ground_truth(i)));
            title(strcat("Evidence accumulation trial ", int2str(i), "/", int2str(num_trials), " - Class: " , label_name, " [Subject: ",  int2str(index_subject), "]"));
        end
    end
        

    %% EVALUATION OF TRIALS ACCURACIES WITHOUT AND WITH REJECTION
    disp(strcat("   [script 5] ---- Evaluation of trials accuracies without and with rejection"));

    % Accuracy without rejection: considering unclassified trials
    decisions_without_rejection = decisions;                    
    trial_accuracy_without_rejection = 100 * sum(decisions_without_rejection == ground_truth) / length(decisions_without_rejection);

    % Accuracy with rejection: do not consider unclassified trials
    decisions_with_rejection = decisions(~isnan(decisions));   
    sub_ground_truth = ground_truth(~isnan(decisions));
    trial_accuracy_with_rejection = 100 * sum(decisions_with_rejection == sub_ground_truth) / length(decisions_with_rejection);


    %% VISUALIZATION OF TRIALS ACCURACY GRAPHS
    disp("   [script 5] ---- Visualization of trials accuracy without and with rejection");

    % Plot the bar graphs of the trial accuracy without and with rejection
    figure;
    Y = [trial_accuracy_without_rejection; trial_accuracy_with_rejection];
    bar(Y);

    % Add features to plot 
    grid on;
    set(gca, "XTickLabel", {"Without rejection", "With rejection"});
    ylabel("Accuracy [%]");
    ylim([0 100]);
    text(1:length(Y'),Y',num2str(Y),'vert','bottom','horiz','center');
    
    title(strcat("Trial accuracy on test set: [Subject: ", int2str(index_subject), "]"));


    %% AVERAGE TIME TO DELIVER A COMMAND
    disp("   [script 5] ---- Compute and print the average time to deliver a command");
    num_windows = zeros(num_trials, 1);
    avg_num_of_pp_to_decision = mean(pp_to_decision_list);
    avg_time_to_deliver_command = avg_num_of_pp_to_decision / pp_frequency; 
    disp(strcat("Average time to deliver a command: ", num2str(avg_time_to_deliver_command), " seconds"));
    disp(strcat("(where: the average number of pp (per trial) to make the decision is: ", num2str(avg_num_of_pp_to_decision), " and the pp_frequency is: ", int2str(pp_frequency), " Hz)"))


    %% OUTPUT OF THIS FUNCTION
    decisions = decisions_without_rejection; 
    avg_time_to_deliver_command = avg_time_to_deliver_command;
end