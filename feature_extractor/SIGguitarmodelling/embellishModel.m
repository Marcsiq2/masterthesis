function embellishModel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        WEKA Experiment                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%initialize output
    emb_pred_fold=[];
    CCI_fold=[];
    CCI_percent_fold=[];
    CM_fold=[];
%load data


load('dataOut/noteDB/score_descript.mat')

%create yes no indexes
no_idx=find(strcmp(score_all.emb,'n'));%get no indexes
yes_idx=find(strcmp(score_all.emb,'y'));

%% Randomization

%split clases

score_n_ds=remove_instances(score_all,yes_idx); %Class no database, is all except yes clases
score_y_ds=remove_instances(score_all,no_idx);%viceversa

% perform the test 10 times
for i=1:10%this for has to go on line 3


score_n_ds_rand=rand_ds(score_n_ds,0);%randomize no class
score_y_ds_rand=rand_ds(score_y_ds,0);%randomize yes class

%Select from n class instances the same amount as y class instances
score_n_ds_rand_reduced=remove_instances(score_n_ds_rand, (length(yes_idx)+1):length(no_idx));%select first set from randomized "n" class of size = (n instances)-(y instances) to be reomoved

%% attribute remove
remove_idx=[3,   5,     18   , 29             ,30,                 32              ];%Index of attributes to be reomoved
%                    vel, chn , key, file_name  embCount,     emb_label
attributes_list=fieldnames(score_n_ds_rand);%get attributes names
score_n_ds_rand_reduced=rmfield(score_n_ds_rand_reduced,attributes_list(remove_idx));%remove indexed attributes
score_y_ds_rand=rmfield(score_y_ds_rand,attributes_list(remove_idx));%remove indexed attributes

% create arff to try with weka and compare results
score_equal_class=structCat(score_y_ds_rand,score_n_ds_rand_reduced);

% atrib=attributes(score_equal_class,score_equal_class);
% arff_write('/Users/Sergio/Dropbox/PHD/guitarModelling/modelingCode/dataOut/arffs/embellish_equal_class.arff',score_equal_class,'train',atrib);


%% Embellish prediction
fprintf('Running weka experiment for embelishment prediction...\n');


% if strcmp(score_file_train,test_score_file)%if train and test files are the same predict using cross val

    CCI_percent_max=0;
%10 Cross fold validation experiment

    [emb_pred,CCI,CCI_percent,CM]=cross_val2(score_n_ds_rand_reduced,score_y_ds_rand,10);%structure data, folds, same seed(yes not)
    
    %store data of each fold
    emb_pred_fold=[emb_pred_fold;emb_pred];
    CCI_fold=[CCI_fold;CCI];
    CCI_percent_fold=[CCI_percent_fold;CCI_percent];
    CM_fold=[CM_fold;CM];
    
    %choose maximun accuracy data
    if CCI_percent_max<CCI_percent
        emb_pred=emb_pred;
        CCI_percent_max=CCI_percent;
        CCI_max=CCI;
        CM_max=CM;
        fold_max=i;
    end
end
% else %else use train_test approach
%     train_ds=score_ds;
%     %test_ds=test_ds; was setted at line 83
%     atrib=attributes(train_ds,test_ds);
%     emb_pred=weka_run(train_ds,test_ds,atrib,'kStar',1);

save('dataOut/modelValidation/crossFold.mat', 'emb_pred_fold','CCI_fold','CCI_percent_fold','CM_fold');

end

function score_ds_rand=rand_ds(score_ds,seed)
%randomize no instances
%seed=1;
%idx=[1:numel(no_idx)]; %Create a vector of indexes of the length of the data
if seed==1;%if we want the same seed...
    s = RandStream('mt19937ar','Seed',0);%define the seed
    rand_idx=randperm(s,numel(score_ds.pitch));% create a random vector of the size of the data
else% else use the normal random fuction with a different seed each time.
    rand_idx=randperm(numel(score_ds.pitch));
end
score_ds_rand=score_ds;%initialize output structure

header=fieldnames(score_ds);% get field names

for i=1:numel(header)%for each field
    if strcmp(header{i},'nar') %if narmour
        score_ds_rand.nar(:,:)=score_ds.nar(rand_idx,:);%remove rows

    else
    score_ds_rand.(header{i})(:)=score_ds.(header{i})(rand_idx);%remove row of current field
    end
end

load('/Users/Sergio/Dropbox/PHD/guitarModelling/modelingCode/dataOut/modelValidation/crossFold.mat')

end

