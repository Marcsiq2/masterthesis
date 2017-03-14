function LearningCurves
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        WEKA Experiment                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%In this setting we will perform the train test experiment adding new
%instances each time to obtain learning curves. As we have an imbalanced
%class problem, we will divide num of no class/num of yes class, and chose
%on each iterarion a number of instances from each class that keeps that
%ratio. (ejem. 729n, 276y... 729/276=2,4 => choose randomly 3n and 1y on 
%each iteration)

%load data
load('/Users/Sergio/Dropbox/PHD/guitarModelling/modelingCode/dataOut/score_descript.mat')

%create yes no indexes
no_idx=find(strcmp(score_all.emb,'n'));%get no indexes
yes_idx=find(strcmp(score_all.emb,'y'));

%split clases

score_n_ds=remove_instances(score_all,yes_idx); %Class no database, is all except yes clases
score_y_ds=remove_instances(score_all,no_idx);%viceversa

%% Randomization
% 
% score_n_ds_rand=rand_ds(score_n_ds,0);%randomize no class
% score_y_ds_rand=rand_ds(score_y_ds,0);%randomize yes class

%% attribute remove
remove_idx=[3,   5,     18   , 29             ,30,                 32              ];%Index of attributes to be reomoved
%                    vel, chn , key, file_name  embCount,     emb_label
attributes_list=fieldnames(score_n_ds);%get attributes names
score_n_ds=rmfield(score_n_ds,attributes_list(remove_idx));%remove indexed attributes
score_y_ds=rmfield(score_y_ds,attributes_list(remove_idx));%remove indexed attributes

ratio=round (length(score_n_ds.pitch)/length(score_y_ds.pitch));%number of instances resolution (100 points)

score_n_reduced_ds=score_n_ds;%initialize reduced data
score_y_reduced_ds=score_y_ds;

J_train=[];
J_cv=[];

for i=0:round(length(score_n_ds.pitch)/ratio)-10%or do a while here...

    if i==0 %if first loop use all data
        [~,~,CCI_precent_train,~]=predict_use_trainset(score_n_ds,score_y_ds);%predict using training set
        [~,~,CCI_percent_cv,~]=cross_val3(score_n_ds,score_y_ds);%predict using cross val

    else%remove data

        % perform the test reducing instances
        %choose randomly elements of each class
        rand_remove_idx_n=randperm(numel(score_n_reduced_ds.pitch),3);
        rand_remove_idx_y=randperm(numel(score_y_reduced_ds.pitch),1);

        score_n_reduced_ds=remove_instances(score_n_reduced_ds,rand_remove_idx_n );%select set of randomized "n" class 
        score_y_reduced_ds=remove_instances(score_y_reduced_ds,rand_remove_idx_y);%

        %run ML experiment
        [~,~,CCI_precent_train,~]=predict_use_trainset(score_n_reduced_ds,score_y_reduced_ds);%predict using training set
        [~,~,CCI_percent_cv,~]=cross_val3(score_n_reduced_ds,score_y_reduced_ds);%predict using cross val

    end
    %concatenate data
    J_train=[J_train,1-CCI_precent_train];
    J_cv=[J_cv,1-CCI_percent_cv];
end
%save('dataOut/modelValidation/crossFold.mat', 'emb_pred_fold','CCI_fold','CCI_percent_fold','CM_fold');

plot(flipud(J_train))
hold on;
plot(flipud(J_cv))

end

