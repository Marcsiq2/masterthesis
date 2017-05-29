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

%% Process Performance Data
fprintf(['Reading performance midi file into matrix: ',score_fn(1:end-4),'.mid...']);
nmat_per = midi2nmat([score_pn(1:end-11),'extracted_midi/',score_fn(1:end-4),'.mid']);%Read midi file into nmat!!! (by me!)
nmat_per(:,3) = nmat_per(:,3)+1;

%% Align performance 2 score
%Shift both sequences to same octave
octaveOffset=round((mean(nmat_per(:,4))-mean(nmat_sco(:,4)))/12)*12;%mean of notes of first sequence minus mean of notes of second sequence
nmat_sco(:,4)=nmat_sco(:,4)+octaveOffset;%shift octave

%% Load anotated data
fprintf('Loading manually anotated data...');
load([score_pn(1:end-11),'dataOut/nmat/', score_fn(1:end-4),'_workspace.mat'], 'p2s_manual');
fprintf('Done!\n');

%% Score Performance alignment
fprintf('Performing aligment betwen performance and score...'); 
%aligment using dinamic time wrapping, with distance function based on cost of onsets, pitch duration and legato

%Tempo deviation correction
nmat_per_0of = shift(nmat_per, 'onset', -nmat_per(1,1));
nmat_per_0of(:,1)=nmat_per_0of(:,1)*1.04;
nmat_per_0of(:,6)=nmat_per_0of(:,6)*1.04;

%% all score
[~, p2s] = dtwSig(nmat_sco,nmat_per_0of, 1, 0.1, 0.5, 0, 0, 'no', 0.3, 0);
figu = aligmentPlot(nmat_sco,nmat_per_0of,p2s, 2);

set(figu, 'PaperPosition', [0 0 130 100]); %Position plot at left hand corner with width 5 and height 5.
set(figu, 'PaperSize', [130 100]); %Set the paper to have width 5 and height 5.
print(figu,'Files/Figures/Darn_auto.pdf','-dpdf','-r0')

% %% First 8 beats
% 
% [~, p2s_8] = dtwSig(nmat_sco(1:20,:),nmat_per_0of(1:28,:), 1, 0.1, 0.5, 0, 0, 'no', 0.3, 0);
% figu = aligmentPlot(nmat_sco(1:20,:),nmat_per_0of(1:28,:),p2s_8, 2);
% figu_m = aligmentPlot(nmat_sco(1:20,:),nmat_per_0of(1:28,:),p2s_manual(1:28,:), 2);
% 
% set(figu, 'PaperPosition', [0 0 130 100]); %Position plot at left hand corner with width 5 and height 5.
% set(figu, 'PaperSize', [130 100]); %Set the paper to have width 5 and height 5.
% print(figu,'Files/Figures/Darn_8b_auto.pdf','-dpdf','-r0')
% 
% set(figu_m, 'PaperPosition', [0 0 130 100]); %Position plot at left hand corner with width 5 and height 5.
% set(figu_m, 'PaperSize', [130 100]); %Set the paper to have width 5 and height 5.
% print(figu_m,'Files/Figures/Darn_8b_corrected.pdf','-dpdf','-r0')
% 
% %% First 20 beats
% [~, p2s_20] = dtwSig(nmat_sco(1:55,:),nmat_per_0of(1:70,:), 1, 0.1, 0.5, 0, 0, 'no', 0.3, 0);
% figu = aligmentPlot(nmat_sco(1:55,:),nmat_per_0of(1:70,:),p2s_20, 2);
% figu_m = aligmentPlot(nmat_sco(1:55,:),nmat_per_0of(1:70,:),p2s_manual, 2);
% 
% set(figu, 'PaperPosition', [0 0 130 100]); %Position plot at left hand corner with width 5 and height 5.
% set(figu, 'PaperSize', [130 100]); %Set the paper to have width 5 and height 5.
% print(figu,'Files/Figures/Darn_20b_auto.pdf','-dpdf','-r0')
% 
% set(figu_m, 'PaperPosition', [0 0 130 100]); %Position plot at left hand corner with width 5 and height 5.
% set(figu_m, 'PaperSize', [130 100]); %Set the paper to have width 5 and height 5.
% print(figu_m,'Files/Figures/Darn_20b_corrected.pdf','-dpdf','-r0')
% fprintf('Done!\n');

%% note omisions... If a score note is omited in the performance
 %(or two notes of the score are related to one of the
%performance, we ommit the second one... Becasuse we can...
p2s_manual=unique_sig(p2s_manual); 

%% Compute performance actions
fprintf(['Computing performance actions for: ', score_fn(1:end-4)],'...');
%pactions = perfactions(score_d, nmat_sco, nmat_per_0of, p2s, score_fn);
pactions = perfactions(score_d, nmat_sco,nmat_per_0of, p2s_manual, score_fn);
pactions = cut_struct(pactions, 21, 55);
fprintf('Done!\n')

%% Save performance actions
fprintf(['Saving performance actions to file: ', score_fn(1:end-4),'_pas.arff...']);
atrib=attributes(pactions,pactions);%create atribute list
arff_write([score_pn(1:end-11),'dataOut/arff/', score_fn(1:end-4),'_8bto20b_pas.arff'],pactions,'train',atrib, [score_fn(1:end-4),'_pas']);
fprintf('Done!\n')

%% Delete unused variables and save all workspace
clear ans plot atrib octaveOffset
save([score_pn(1:end-11),'dataOut/nmat/', score_fn(1:end-4),'_workspace.mat']);
