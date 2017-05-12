%% Adding to the path necessary functions and miditoolbox
addpath(genpath('1.1/'));
addpath(genpath('feature_extractor'));

%% Process Score %%
%%%%%%%%%%%%%%%%%%%
[score_fn, score_pn, ~] = uigetfile('*.xml', 'Choose an score xml file');
score = [score_pn,'/',score_fn];

%% Read xml file into nmat and nstruct
fprintf(['Reading score xml file into matix and structures: ', score_fn,'...']);
[nmat, nstruct]=xml2nmat(score);%Read xml file into nmat!!! (sergio Giraldo)
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
