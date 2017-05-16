%% Adding to the path necessary functions and miditoolbox
clear all;
addpath(genpath('1.1/'));
addpath(genpath('feature_extractor'));

%% Process Score %%
%%%%%%%%%%%%%%%%%%%
[score_fn, score_pn, ~] = uigetfile('*.xml', 'Choose an score xml file');
score = [score_pn,'/',score_fn];

%% Read xml file into nmat and nstruct
fprintf(['Reading score xml file into matix and structures: ', score_fn,'...']);
[nmat, nstruct]=xml2nmat(score);%Read xml file into nmat!
%[nmat, nstruct]=xmlMusicParse(score);%read data from xml file
fprintf('Done!\n');

%% Read midi file into nmat
fprintf(['Reading score midi file into matix: ',score_fn(1:end-4),'.mid...']);
nmat_midi = readmidi([score_pn(1:end-4),'midi/',score_fn(1:end-4),'.mid']);
fprintf('Done!\n');

%% Extract note descriptors from midi, and chord information from xml file
fprintf(['Extracting descriptors of file: ',score_fn,'...']);
score_d=midi2ds2(nmat_midi,nstruct);
fprintf('Done!\n');

%% Add file name to note descriptors (needed?)
score_d=addAttribute(score_d, score_fn, 'fileName');

%% Save extracted descriptors
%saving to nmat
fprintf(['Saving descriptors to file: ', score_fn(1:end-4),'.mat...']);
save([score_pn(1:end-11),'dataOut/nmat/',score_fn(1:end-4),'.mat'],'score_d');
fprintf('Done!\n');
%savint to arff
fprintf(['Saving descriptors to file: ', score_fn(1:end-4),'.arff...']);
atrib=attributes(score_d,score_d);%create atribute list
arff_write([score_pn(1:end-11),'dataOut/arff/', score_fn(1:end-4),'.arff'],score_d,'train',atrib, score_fn(1:end-4));%write train data set for embellishment 
fprintf('Done!\n')

%% Process Performance Data
fprintf(['Reading performance midi file into matrix: ',score_fn(1:end-4),'.mid...']);
nmat_per = midi2nmat([score_pn(1:end-11),'extracted_midi/',score_fn(1:end-4),'.mid']);%Read midi file into nmat!!! (by me!)

%% Processing
score_p=midi2ds2(nmat_per,nstruct);
score_p=addAttribute(score_p, score_fn, 'fileName');
fprintf('Done!\n');

%% Align performance 2 score
%Shift both sequences to same octave
octaveOffset=round((mean(nmat_per(:,4))-mean(nmat_midi(:,4)))/12)*12;%mean of notes of first sequence minus mean of notes of second sequence
nmat_midi(:,4)=nmat_midi(:,4)+octaveOffset;%shift octave

%% Create aligment matrix
fprintf(['Performing aligment betwen performance and score...\n']); 
%aligment using dinamic time wrapping, with distance function based on cost of onsets, pitch duration and legato
plot = 1; %Plot = 1 plots performance aligment
[H2, p2s] = dtwSig(nmat_midi,nmat_per, 0.6, 0.1, 1, 0.5, 0.6, 'no', 0.3, plot);
% pitchW, durW, OnsetW, iniLegatoW,lastLegatoW, inverted, legato_threshold(gap betwen two notes in beats fraction), plot );
fprintf('Done!\n');

%% note omisions... If a score note is omited in the performance
 %(or two notes of the score are related to one of the
%performance, we ommit the second one... Becasuse we can...
p2s=unique_sig(p2s); 

%% Create database of ornaments            
% emb = embellish(nmat_midi,nmat_per,p2s); %returns a structure     
% emb=addAttribute(emb, score_fn, 'fileName');  %set constant descriptors (ej. tempo) to each not

%% Save extracted descriptors
%saving to nmat
fprintf(['Saving descriptors to file: ', score_fn(1:end-4),'_perf.mat...']);
save([score_pn(1:end-11),'dataOut/nmat/',score_fn(1:end-4),'_perf.mat'],'score_p', 'H2', 'p2s');
fprintf('Done!\n');
%savint to arff
fprintf(['Saving descriptors to file: ', score_fn(1:end-4),'_perf.arff...']);
atrib=attributes(score_p,score_p);%create atribute list
arff_write([score_pn(1:end-11),'dataOut/arff/', score_fn(1:end-4),'_perf.arff'],score_p,'performance',atrib, score_fn(1:end-4));
fprintf('Done!\n')
           
