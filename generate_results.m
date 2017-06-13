%% Adding to the path necessary functions and miditoolbox
clear all;
addpath(genpath('1.1/'));
addpath(genpath('feature_extractor'));

%%
path_scores = 'Files/scores/midi';
path_predictions = 'Files/Predictions';
path_results = 'Files/Predictions/midis';

[score_fn, score_pn, ~] = uigetfile('*.mid', 'Choose an score midi file', path_scores);
score = [score_pn,score_fn];
fprintf(['Reading score for midi: ', score_fn,'...\n']);
nmat_sco = midi2nmat(score);
nmat_out = nmat_sco;

[res_fn, res_pn, ~] = uigetfile('*.csv', 'Choose a results csv file', path_predictions);
res = [res_pn,res_fn];

M = csvread(res);
if strfind(res_fn,'energy')
    nmat_out(:,5) = M(:,3);
    
elseif strfind(res_fn,'onset')
    timesc=max(nmat_out(:,2))./max(nmat_out(:,7));
    nmat_out(:,1)=(nmat_out(:,6)+M(:,3)) *timesc;
    nmat_out(:,1)=max(nmat_out(:,1),0);
    nmat_out(:,6)=nmat_out(:,6)+M(:,3);
    nmat_out(:,6)=max(nmat_out(:,6),0);
end

f_name = input('Enter a file name for the results midi file: ', 's');
writemidi(nmat_out,[path_results,'/',f_name]);  