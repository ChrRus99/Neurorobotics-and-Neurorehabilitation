% Author: Nabil Errami, Giovanni Cerisara
% Contributor: Martina Cecchinato

%%
clc;
clearvars;

%% General information about the data such as: root folder, channel labels, class indexes, class labels. 
data_path = '/Users/salwaerrami/Documents/Project_4/micontinuous/';
% folder xproc; in which we will save the processed files
processeddatapath = '/Users/salwaerrami/Documents/Project_4/xproc/';

channelLb = {'Fz', 'FC3', 'FC1', 'FCz', 'EC2', 'FC4', 'C3', 'C1', 'Cz', 'C2', 'C4', 'CP3', 'CP1', 'CPZ', 'CP2', 'CP4'}; 
channelId = 1: length(channelLb); 
classId = [773 771 783];
classLb = {'both hands','both feet', 'rest '};
nclasses = length(classId);
modalityId = [0 1];
modalityLb = {'offline', 'online'};

%% PSD information
mlength = 1;
wlength = 0.5;
pshift = 0.25; 
wshift = 0.0625; 
selfreqs = 4:2:48; 
winconv = 'backward'; 

%% List of the GDF files
% WHOLE POPULATION
name_list = {dir(data_path).name};  

% Initialize table 
file_table = {};
%Fill in the table

for i = 1 : length(name_list)   
    % Open current subdirectory
    curr_name = name_list{i};   
    curr_name_path = fullfile(data_path, curr_name);

    % Read all files in current subdirectory
    file_dir = dir(fullfile(curr_name_path, "*.gdf")); 
    final_list = {file_dir.name};
    disp(final_list);
    
    % Fill the table of files name read
    file_table{i} = final_list;   
end

%% Loading and concatenate GDF files and events

s= [];
TYP=[];
POS=[];
DUR=[];
Rk=[];
Mk=[];

for i = 1 : length(file_table)      % iterate subdirectories
    file_list = file_table{i};   
    disp("SUBDIR " + i)
    
    for j = 1 : length(file_list)   % iterate files
        gdfname = file_list{j};
        disp("FILE " + j + " : " + gdfname )
        
        % Loading GDF file
        [s, h] = sload(str2mat(gdfname));
        s = s(:, channelId);
        SampleRate = h.SampleRate;

        
        % Spatial filters
        disp('Applying CAR and Laplacian filters');
        load('laplacian16.mat');
        s_lap = s*lap;

        % Spectrogram
        disp('Computing spectrogram');
        [psd, freqgrid] = proc_spectrogram(s_lap, wlength, wshift, pshift, SampleRate, mlength);
        % Selecting desired frequencies
        [freqs, idfreqs] = intersect(freqgrid, selfreqs);
        psd = psd(:, idfreqs, :);
        % Extracting events
        disp('Extract and convert the events');
        cevents = h.EVENT;
        events.TYP = cevents.TYP;
        events.POS = proc_pos2win(cevents.POS, wshift*h.SampleRate, winconv, mlength*h.SampleRate);
        % function to convert from samples to windows
        events.DUR = floor(cevents.DUR/(wshift*h.SampleRate)) + 1;
        events.conversion = winconv;
        
        % Store additional information
        disp('Store additional information');
        info.mlength = mlength;
        info.wlength = wlength;
        info.pshift = pshift;
        info.wshift = wshift;
        info.selfreqs = selfreqs;
        info.winconv = winconv;
        % Saving the processed file as file.mat
        [~, pgdfname] = fileparts(gdfname);
        sgdfname = [pgdfname '.mat'];
        disp(['Saving psd as file .mat in: ' sgdfname]);
        save([ processeddatapath sgdfname], 'psd', 'freqs', 'events', 'info', 'SampleRate');
    end
end



%% List of the PSD files
% Single subject loop

csubject1 = (regexp(file_table{1,4}{1,1}, '(\w+)\..*', 'tokens'));
csubject2 = (regexp(file_table{1,5}{1,1}, '(\w+)\..*', 'tokens'));
csubject3 = (regexp(file_table{1,6}{1,1}, '(\w+)\..*', 'tokens'));
csubject4 = (regexp(file_table{1,7}{1,1}, '(\w+)\..*', 'tokens'));
csubject5 = (regexp(file_table{1,8}{1,1}, '(\w+)\..*', 'tokens'));
csubject6 = (regexp(file_table{1,9}{1,1}, '(\w+)\..*', 'tokens'));
csubject7 = (regexp(file_table{1,10}{1,1}, '(\w+)\..*', 'tokens'));
csubject8 = (regexp(file_table{1,11}{1,1}, '(\w+)\..*', 'tokens'));


subject1 = cell2mat(csubject1{1});
subject2 = cell2mat(csubject2{1});
subject3 = cell2mat(csubject3{1});
subject4 = cell2mat(csubject4{1});
subject5 = cell2mat(csubject5{1});
subject6 = cell2mat(csubject6{1});
subject7 = cell2mat(csubject7{1});
subject8 = cell2mat(csubject8{1});

%% All subjects analysis
% Find all .mat files of the selected subject
file_dir = dir(fullfile(processeddatapath, "*.mat"));
subject_files = {file_dir.name};
nfiles = length(subject_files);

% Loading and concatenate PSD files and events
P = [];
TYP = [];
POS = [];
DUR = [];
Rk = []; Mk = []; Sk = [];
   
for fId = 1:nfiles
    disp(['Loading PSD files ' num2str(fId) '/' num2str(nfiles) ]);
    csubject_filename = subject_files{1,fId};
    cdata = load(csubject_filename);
 
    % Extract the current PSD
    cpsd = cdata.psd;

    cevents = cdata.events;        
    TYP = cat(1,TYP,cevents.TYP); %what it means
    DUR = cat(1,DUR,cevents.DUR); %how long it lasts
    POS = cat(1,POS,cevents.POS+ size (P,1)); %when it happens
    

     % Create run vector Rk 
     cRk = fId*ones (size (cpsd, 1), 1);
     Rk = cat (1, Rk, cRk);
    
     % Create Mk vector (modality)
     if(contains(csubject_filename,'offline') == true)
        cMk = modalityId(1)*ones(size(cpsd, 1), 1);
     elseif ( contains(csubject_filename,'online') == true )
        cMk = modalityId(2)*ones(size(cpsd, 1), 1);
     else
        error( ['Unknown modality for run: ' csubject_filename]);
     end
     Mk = cat (1, Mk, cMk);
     %create Sk vector
     subjectId= 1:8 ; %8 total Subj
     if( contains(csubject_filename, 'ai6') == true)
        cSk = subjectId(1)*ones(size(cpsd, 1), 1);
     elseif ( contains(csubject_filename, 'ai7') == true )
        cSk = subjectId(2)*ones(size(cpsd, 1), 1);
     elseif ( contains(csubject_filename, 'ai8') == true )
        cSk = subjectId(3)*ones(size(cpsd, 1), 1);
     elseif ( contains(csubject_filename, 'aj1') == true )
        cSk = subjectId(4)*ones(size(cpsd, 1), 1);
     elseif ( contains(csubject_filename, 'aj3') == true )
        cSk = subjectId(5)*ones(size(cpsd, 1), 1);
     elseif ( contains(csubject_filename, 'aj4') == true )
        cSk = subjectId(6)*ones(size(cpsd, 1), 1);
     elseif ( contains(csubject_filename, 'aj7') == true )
        cSk = subjectId(7)*ones(size(cpsd, 1), 1);
     elseif ( contains(csubject_filename, 'aj9') == true )
        cSk = subjectId(8)*ones(size(cpsd, 1), 1);
        
     else
        error(['Unknown modality for run: ' csubject_filename]);
     end
    
    Sk = cat(1, Sk, cSk);

    P = cat(1, P, cpsd);
    freqs = cdata.freqs;
    SampleRate = cdata.SampleRate;
    info = cdata.info;
end
        
        
   


%% Extracting information from data

events.TYP = TYP;
events.DUR = DUR;
events.POS = POS;

nwindows = size(P, 1);
nfreqs = size(P, 2);
nchannels = size(P, 3);

%% Creating vector labels

CFeedbackPOS = POS(TYP == 781);
CFeedbackDUR = DUR(TYP == 781);

CuePOS = POS(events.TYP == 771 | events.TYP == 773 |  events.TYP == 783);
CueDUR = DUR(events.TYP == 771 | events.TYP == 773 |  events.TYP == 783);
CueTYP = TYP(events.TYP == 771 | events.TYP == 773 |  events.TYP == 783);

FixPOS = POS(TYP == 786);
FixDUR = DUR(TYP == 786);
FixTYP = TYP(TYP == 786);

NumTrials = length(CFeedbackPOS);

%% We consider the intersting period from Cue appearance to end of continuous feedback
Ck = zeros(nwindows, 1);
Tk = zeros(nwindows, 1);
TrialStart = nan(NumTrials, 1);
TrialStop = nan(NumTrials, 1);
FixStart = nan(NumTrials, 1);
FixStop = nan(NumTrials, 1);
for trId = 1:NumTrials
    cstart = CuePOS(trId);
    cstop = CFeedbackPOS(trId) + CFeedbackDUR(trId) - 1;
    Ck(cstart:cstop) = CueTYP(trId);
    Tk(cstart:cstop) = trId;

    TrialStart(trId) = cstart;
    TrialStop(trId) = cstop;
    FixStart(trId) = FixPOS(trId);
    FixStop(trId) = FixPOS(trId) + FixDUR(trId) - 1;
end



%% Trial extraction
disp('Extracting data for each trial');
MinTrialDur = min(TrialStop - TrialStart);
Trialdatasub = nan(MinTrialDur, nfreqs, nchannels, NumTrials);
tCk = zeros(NumTrials, 1);
tMk = zeros(NumTrials, 1);
tRk = zeros(NumTrials, 1);
for trId = 1:NumTrials
    cstart = TrialStart(trId);
    cstop = cstart + MinTrialDur - 1;
    Trialdatasub(:, :, :, trId) = P(cstart:cstop, :, :);

    tCk(trId) = unique(Ck(cstart:cstop));
    tRk(trId) = unique(Rk(cstart:cstop));
    tMk(trId) = unique(Mk(cstart:cstop));
end


%% Baseline extraction (from fixation)
disp('Extracting baseline data for each trial');
FixationDur_min = min(FixStop - FixStart);
FixationData = nan(FixationDur_min, nfreqs, nchannels, NumTrials);
for trId = 1:NumTrials
    cstart = FixStart(trId);
    cstop = cstart + FixationDur_min - 1;
    FixationData(:, :, :, trId) = P(cstart:cstop, :, :);
end

%% ERD/ERS
disp('Computing ERD/ERS');
% Average and replicate the value of the baseline
Baseline = repmat(mean(FixationData), [size(Trialdatasub, 1) 1 1 1]);
ERD = log(Trialdatasub./ Baseline);

%% Visualization of ERD maps
fig = figure(1);
time = linspace(0, MinTrialDur*info.wshift, MinTrialDur);
ChannelSelected = [7 9 11];
selclassId = [773 771];
selclassLb = {'Both hands', 'Both feet'};
nselclasses = length(selclassId);
chandles = [];
for cId = 1:nselclasses
    climits = nan(2, length(ChannelSelected));
    for chId = 1:length(ChannelSelected)
        subplot(2, 3, (cId - 1)*length(ChannelSelected) + chId);
        cdata = mean(ERD(:, :, ChannelSelected(chId), tCk == selclassId(cId)), 4);
        imagesc(time, freqs, cdata');
        set(gca,'YDir','normal');
        climits(:, chId) = get(gca, 'CLim');
        chandles = cat(1, chandles, gca);
        colormap(hot);
        colorbar;
        title(['Channel ' channelLb{ChannelSelected(chId)} ' | ' selclassLb{cId}]);
        xlabel('Time [s]');
        ylabel('Frequency [Hz]');
        line([1 1],get(gca,'YLim'),'Color',[0 0 0])
    end
end
sgtitle('ERD map')
set(chandles, 'CLim', [min(min(climits)) max(max(climits))]);

