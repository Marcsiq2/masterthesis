%% Adding to the path necessary functions and miditoolbox
clear all;
addpath(genpath('1.1/'));
addpath(genpath('feature_extractor'));

%% Process Score %%
%%%%%%%%%%%%%%%%%%%
[score_fn, score_pn, ~] = uigetfile('*.xml', 'Choose an score xml file');
score = [score_pn,score_fn];

%% Read xml file into nmat and nstruct_sco
fprintf(['Reading score xml file into matix and structures: ', score_fn,'...']);
[~, nstruct_sco]=xml2nmat(score);%Read xml file into nmat!
%[nmat, nstruct_sco]=xmlMusicParse(score);%read data from xml file
fprintf('Done!\n');

%% Read midi file into nmat
fprintf(['Reading score midi file into matix: ',score_fn(1:end-4),'.mid...']);
nmat_sco = midi2nmat([score_pn(1:end-4),'midi/',score_fn(1:end-4),'.mid']);
fprintf('Done!\n');

%% Extract note descriptors from midi, and chord information from xml file
fprintf(['Extracting descriptors of file: ',score_fn,'...']);
score_d=midi2ds2_poly(nmat_sco,nstruct_sco);
fprintf('Done!\n');

%% Add file name to note descriptors (needed?)
score_d=addAttribute(score_d, score_fn, 'fileName');

%% Save extracted descriptors
% %saving to nmat
% fprintf(['Saving descriptors to file: ', score_fn(1:end-4),'score.mat...']);
% save([score_pn(1:end-11),'dataOut/nmat/',score_fn(1:end-4),'_score.mat'],'score_d');
% fprintf('Done!\n');
% %savint to arff
% fprintf(['Saving descriptors to file: ', score_fn(1:end-4),'_score.arff...']);
% atrib=attributes(score_d,score_d);%create atribute list
% arff_write([score_pn(1:end-11),'dataOut/arff/', score_fn(1:end-4),'_score.arff'],score_d,'train',atrib, [score_fn(1:end-4),'_score']);%write train data set for embellishment 
% fprintf('Done!\n')

%% Process Performance Data
fprintf(['Reading performance midi file into matrix: ',score_fn(1:end-4),'.mid...']);
nmat_per = midi2nmat([score_pn(1:end-11),'extracted_midi/',score_fn(1:end-4),'.mid']);%Read midi file into nmat!!! (by me!)

%% Processing
performance_d=midi2ds2_poly(nmat_per,nstruct_sco);
performance_d=addAttribute(performance_d, score_fn, 'fileName');
fprintf('Done!\n');

%% Align performance 2 score
%Shift both sequences to same octave
octaveOffset=round((mean(nmat_per(:,4))-mean(nmat_sco(:,4)))/12)*12;%mean of notes of first sequence minus mean of notes of second sequence
nmat_sco(:,4)=nmat_sco(:,4)+octaveOffset;%shift octave

%% Load anotated data
fprintf(['Loading manually anotated data...']);
load([score_pn(1:end-11),'dataOut/nmat/', score_fn(1:end-4),'_workspace.mat'], 'p2s_manual');
fprintf('Done!\n');

%% Score Performance alignment
fprintf('Performing aligment betwen performance and score...'); 
%aligment using dinamic time wrapping, with distance function based on cost of onsets, pitch duration and legato
nmat_per_0of = shift(nmat_per, 'onset', -nmat_per(1,1));
%[H2, p2s] = dtwSig(nmat_sco,nmat_per, 0.6, 0.1, 1, 0.5, 0.6, 'no', 0.3, plot);
[H2, p2s] = dtwSig(nmat_sco(1:20,:),nmat_per_0of(1:28,:), 1, 0.1, 0.5, 0, 0, 'no', 0.3, 0);
aligmentPlot(nmat_sco(1:20,:),nmat_per_0of(1:28,:),p2s, 2);
aligmentPlot(nmat_sco(1:20,:),nmat_per_0of(1:28,:),p2s_manual, 2);
% pitchW, durW, OnsetW, iniLegatoW,lastLegatoW, inverted, legato_threshold(gap betwen two notes in beats fraction), plot );
fprintf('Done!\n');

%% note omisions... If a score note is omited in the performance
 %(or two notes of the score are related to one of the
%performance, we ommit the second one... Becasuse we can...
p2s=unique_sig(p2s); 

%% Save extracted descriptors
% %saving to nmat
% fprintf(['Saving descriptors to file: ', score_fn(1:end-4),'_perf.mat...']);
% save([score_pn(1:end-11),'dataOut/nmat/',score_fn(1:end-4),'_perf.mat'],'performance_d', 'H2', 'p2s');
% fprintf('Done!\n');
% %savint to arff
% fprintf(['Saving descriptors to file: ', score_fn(1:end-4),'_perf.arff...']);
% atrib=attributes(performance_d,performance_d);%create atribute list
% arff_write([score_pn(1:end-11),'dataOut/arff/', score_fn(1:end-4),'_perf.arff'],performance_d,'performance',atrib, [score_fn(1:end-4),'_perf']);
% fprintf('Done!\n')

%% Compute performance actions
fprintf(['Computing performance actions for: ', score_fn(1:end-4)],'...');
pactions = perfactions(score_d, nmat_sco, nmat_per, p2s, score_fn);
fprintf('Done!\n')

%% Save performance actions
fprintf(['Saving performance actions to file: ', score_fn(1:end-4),'_pas.arff...']);
atrib=attributes(pactions,pactions);%create atribute list
arff_write([score_pn(1:end-11),'dataOut/arff/', score_fn(1:end-4),'_pas.arff'],pactions,'train',atrib, [score_fn(1:end-4),'_pas']);
fprintf('Done!\n')

%% Delete unused variables and save all workspace
clear plot atrib octaveOffset
save([score_pn(1:end-11),'dataOut/nmat/', score_fn(1:end-4),'_workspace.mat']);