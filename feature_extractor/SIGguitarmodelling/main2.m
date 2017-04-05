function main2()

addpath('/Applications/MATLAB_R2013a.app/toolbox/miditoolbox')

batch=input('perform batch proccessing?(y=1,n=0):');
% arg_in=getpath_sig(batch);

if (input('perform score processing? (y=1,n=0):'))
    preprocessScoreData(batch);%input:xml-->output: nmat (MIDI)
    %                                                                               nscore (Descriptors and other info such as chords, tempo, key...)
end

if (input('perform performance processing? (y=1,n=0):'))
    preprocessPerformanceData(batch);%input:monophonic melody wav-->output:nmat(MIDI)
    %manual correction scheme.... missing notes... error notes
end

if (input('perform manual correction of performance trancription? (y=1,n=0):'))
    melodyTranscriptionCorrect();%input:monophonic melody wav-->output:nmat(MIDI)
    %manual correction scheme.... missing notes... error notes
end

if (input('perform beat track processing? (y=1,n=0):'))
    bakingTrackBeat(batch);% input:poliphonic backingtrack -->manual correction interface---->output:beats list in seconds txt
    %                                                                                                                     ^<-------------Backingtrack with audible beats
end

if (input('perform beat midi alignment? (y=1,n=0):'))
    beatTrackMidiAlign(batch);%input:performance nmat  ---->performance nmat aligned with beats
    %                                                       beats list in sec txt
end

if (input('create file for manual score to perform aligment? (y=1,n=0):'))
    create_file_for_manual_aligment(batch);%input:performance nmat--->nmat
    %                                             score nmat
    %Check score to performance key in case they are dirfferent (ene20015)
end

%choose manual or automatic alligment to score and performance...?

if (input('create score to performance correspondence? (y=1,n=0):'))
    create_performace2score_corr(batch)
end

if (input('create embellisment database and arff files? (y=1,n=0):'))
    embellish_db_create(batch)% input: anotations folder -----> output: noteDB
    %                                                       nmat scores
end

if (input('Perform song out modeling? (y=1,n=0):'))
    embellishModel_song_fold
end

if (input('Predict embellishments in song data base? (y=1,n=0):'))
    create_prediction_song2
end

%I have encountered a problem here. There are errors on the embellishment
%data base. Some songs are labeled as 100% of the notes embellished which
%is rwong. So fixing this bug may improove the results. 

%Also embellishments
%of one note (pitch change) may be omited, and only take into account as
%embellisment when a note is changed by two or more notes.....OK!Nov 2014

%song modeling Embellishment



end




% function arg_in=getpath_sig(batch)
%
% arg_in=[];
% if batch==1
%
%     %% Get performance directory path
%     path_file_s=uigetdir('Choose the folder in which scores are stored');%Get the directory path where the midi and xml files are stored
%     arg_in{1}=path_file_s;
%     arg_in{2}=[];
%
%
% else
%
%     %% Get socre file path
%     [file,path_file_s]=uigetfile('*.xml','Choose a score file');%Get the directory path where the midi and xml files are stored
%     arg_in{1}=path_file_s;
%     arg_in{2}=file;
%
%
% end
%
%
% end
