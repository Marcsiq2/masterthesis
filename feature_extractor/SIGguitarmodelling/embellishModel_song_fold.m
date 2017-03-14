 %function embellishModel_song_fold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        WEKA Experiment                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%load data


load('dataOut/noteDB/score_descript.mat')

%create indexes for each song
[c1,ia1,~] = unique(score_all.fileName);
ia1=[ia1'];
model.fileName=c1;

%initialize output
model.Acu=[[],[],[]];


%% attribute remove
remove_idx=[5,   3,     18   , 32             ,29,                 31              ];%Index of attributes to be reomoved
%                    vel, chn , key, file_name  embCount,     emb_label
attributes_list=fieldnames(score_all);%get attributes names
score_reduced=rmfield(score_all,attributes_list(remove_idx));%remove indexed attributes


for i=1:length(ia1)
    %remaining songs used as train.
    %conditionals for first song or last song indexing
    if ia1(i)==1%if first song
        song_out_idx=[ia1(i):ia1(i+1)-1];%indexes of the notes of the song to use as test
        song_left_idx=[ia1(i+1):length(score_all.fileName)];
    else if ia1(i)==ia1(end)%if last song
            song_out_idx=[ia1(i):length(score_all.fileName)];%indexes of the notes of the song to use as test
            song_left_idx=[1:ia1(i)-1];
        else%if song is in the middle
            song_out_idx=[ia1(i):ia1(i+1)-1];%indexes of the notes of the song to use as test
            song_left_idx=[1:ia1(i)-1,ia1(i+1):length(score_all.fileName)];
        end
    end
    score_songs_left=remove_instances(score_reduced,song_out_idx);
    score_song_out=remove_instances(score_reduced,song_left_idx);
    
    emb_y=length(find(strcmp(score_songs_left.emb,'y')));
    emb_n=length(find(strcmp(score_songs_left.emb,'n')));
    Base_line=max(emb_y,emb_n)/(length(score_songs_left.emb));
    %% Embellish prediction
    fprintf('Running weka experiment for embelishment prediction for %s\n',model.fileName{i});
    
    %    atrib=attributes(score_songs_left,score_song_out);
    %     arff_write('/Users/Sergio/Dropbox/PHD/guitarModelling/modelingCode/weka_files/train.arff',score_songs_left,'train',atrib);
    %     arff_write('/Users/Sergio/Dropbox/PHD/guitarModelling/modelingCode/weka_files/test.arff',score_song_out,'test',atrib);
    
    [pred , J_train,J_cv,Acu_train,Acu_test, ynpr_train, ynpr_cv]=weka_run(score_songs_left,score_song_out,model.fileName{i});
    
    model.(['pred',num2str(i)])=pred;
    model.Acu=[model.Acu; [Acu_train,Acu_test,Base_line*100],emb_y,emb_n];%train, test, baseline
    
    % if strcmp(score_file_train,test_score_file)%if train and test files are the same predict using cross val
end


%
% CCI_percent_max=0;
% %10 Cross fold validation experiment
%
% [emb_pred,CCI,CCI_percent,CM]=cross_val2(score_n_ds_rand_reduced,score_y_ds_rand,10);%structure data, folds, same seed(yes not)
%
% %store data of each fold
% emb_pred_fold=[emb_pred_fold;emb_pred];
% CCI_fold=[CCI_fold;CCI];
% CCI_percent_fold=[CCI_percent_fold;CCI_percent];
% CM_fold=[CM_fold;CM];
%
% %choose maximun accuracy data
% if CCI_percent_max<CCI_percent
%     emb_pred=emb_pred;
%     CCI_percent_max=CCI_percent;
%     CCI_max=CCI;
%     CM_max=CM;
%     fold_max=i;
% end
% else %else use train_test approach
%     train_ds=score_ds;
%     %test_ds=test_ds; was setted at line 83
%     atrib=attributes(train_ds,test_ds);
%     emb_pred=weka_run(train_ds,test_ds,atrib,'kStar',1);

save('dataOut/modelValidation/songFold.mat', 'model','score_all');


%end
