function [offline_file_table, online_file_table] = GDF_files_load(data_path)
% Load all GDF files from the given data_path and return a table containing
% all the names of the files.
%
% Input:
%   - data_path: the path of the directory in which are stored the 
%     subdirectories of the .gdf files
% Output:
%   - offline_file_table: table containing a list of all offline files
%   - online_file_table: table containing a list of all online files
%
% Author: Christian Francesco Russo



    %% Find GDF files   
    data_dir = dir(data_path);
    subdir_list = {data_dir.name};
    
    % Table of all file names
    offline_file_table = {};
    online_file_table = {};

    % Fill the table of all file names
    index_off = 1;
    index_on = 1;
    for i = 1 : length(subdir_list)   
        % Open current subdirectory
        curr_subdir = subdir_list{i};
        curr_subdir_path = fullfile(data_path, curr_subdir);
        
        % Avoid sload errors
        addpath(curr_subdir_path);
    
        % Read all .gdf files in the current subdirectory
        file_dir = dir(fullfile(curr_subdir_path, "*.gdf"));
        file_list = {file_dir.name};
        
        % Fill the tables of offline and online files names
        for filename = file_list
            if contains(filename, "offline")        % offline file
                offline_file_table{index_off} = filename{1};
                index_off = index_off + 1;
            elseif contains(filename, "online")     % online file
                online_file_table{index_on} = filename{1}; 
                index_on = index_on + 1;
            else                                    % unchategorized file
                disp(strcat("Unchategorized file: ", filename{1}));
        end
    end   
end