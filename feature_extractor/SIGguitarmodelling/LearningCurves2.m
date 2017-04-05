function LearningCurves2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        WEKA Experiment                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%In this setting we will perform the train test experiment adding new
%instances each time to obtain learning curves.  We call a function that
%perfrom the train test experiment in weka and returns accurracy for
%training set and stratified cross validation (check what that is!!!)

%load data
load('/Users/Sergio/Dropbox/PHD/guitarModelling/modelingCode/dataOut/score_descript.mat')

%% attribute remove
remove_idx=[3,   5,     18   , 29             ,30,                 32              ];%Index of attributes to be reomoved
%                    vel, chn , key, file_name  embCount,     emb_label
attributes_list=fieldnames(score_all);%get attributes names
score_ds=rmfield(score_all,attributes_list(remove_idx));%remove indexed attributes

%% split clases to calculate ratio

%create yes no indexes
no_idx=find(strcmp(score_ds.emb,'n'));%get no indexes
yes_idx=find(strcmp(score_ds.emb,'y'));
score_n_ds=remove_instances(score_ds,yes_idx); %Class no database, is all except yes clases
score_y_ds=remove_instances(score_ds,no_idx);%viceversa
ratio=round (length(score_n_ds.pitch)/length(score_y_ds.pitch));%number of instances resolution (100 points)

%% Randomization
% 
% score_n_ds_rand=rand_ds(score_n_ds,0);%randomize no class
% score_y_ds_rand=rand_ds(score_y_ds,0);%randomize yes class

%% reduce data and iterate

score_n_reduced_ds=score_n_ds;%initialize reduced data
score_y_reduced_ds=score_y_ds;

J_train_all=[];
J_cv_all=[];
y_r_train_all=[];
y_r_cv_all=[];

for i=0:round(length(score_n_ds.pitch)/ratio)-10%or do a while here...

    if i==0 %if first loop use all data
        
        [J_train,J_cv,Acu_train,Acu_cv,ynpr_train, ynpr_cv]=weka_Jtain_Jcv(score_ds);
     
    else%remove data

        % perform the test reducing instances
        %choose randomly elements of each class
        rand_remove_idx_n=randperm(numel(score_n_reduced_ds.pitch),ratio);
        rand_remove_idx_y=randperm(numel(score_y_reduced_ds.pitch),1);

        score_n_reduced_ds=remove_instances(score_n_reduced_ds,rand_remove_idx_n );%select set of randomized "n" class 
        score_y_reduced_ds=remove_instances(score_y_reduced_ds,rand_remove_idx_y);%
        
        score_ds_reduced=structCat(score_n_reduced_ds,score_y_reduced_ds);%
        
        %run ML experiment
        [J_train,J_cv,Acu_train,Acu_cv,ynpr_train, ynpr_cv]=weka_Jtain_Jcv(score_ds_reduced);

    end
    %concatenate data
    J_train_all=[J_train_all,J_train];
    J_cv_all=[J_cv_all,J_cv];
    y_r_train_all=[y_r_train_all,ynpr_train(2)];
    y_r_cv_all=[y_r_cv_all,ynpr_cv(2)];

end
%save('dataOut/modelValidation/crossFold.mat', 'emb_pred_fold','CCI_fold','CCI_percent_fold','CM_fold');

figure(1);
plot([1:4:length(J_train_all)*4],fliplr(J_train_all))
hold on;
plot([1:4:length(J_train_all)*4],fliplr(J_cv_all),'r')
xlabel('Number of instances')
ylabel('Error (%)')
text(800,15,'Error train');
text(700,25,'Error cross validation');

figure(2);
plot([1:4:length(J_train_all)*4],fliplr(y_r_train_all))
hold on;
plot([1:4:length(J_train_all)*4],fliplr(y_r_cv_all),'r')
xlabel('Number of instances')
ylabel('Error (%)')
text(800,15,'Recall train');
text(700,25,'Recall cross validation');


end

