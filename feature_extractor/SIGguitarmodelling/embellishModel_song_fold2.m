%function embellishModel_song_fold



load([pwd,'/dataOut/noteDB/score_descriptors.mat']);

%create indexes for each song
[c1,ia1,~] = unique(score_all_pa.fileName);
ia1=[ia1'];
model.fileName=c1;


%% attribute remove
remove_idx=[3,   5,     20   , 40       ,42,                 ];%Index of attributes to be reomoved
%           chn, vel , chord,  embCount, emb_label, File Name (47)
attributes_list=fieldnames(score_all_pa);%get attributes names
score_reduced=rmfield(score_all_pa,attributes_list(remove_idx));%remove indexed attributes


for i=1:length(ia1)
    %remaining songs used as train.
    %conditionals for first song or last song indexing
    if ia1(i)==1%if first song
        song_out_idx=[ia1(i):ia1(i+1)-1];%indexes of the notes of the song to use as test
        song_left_idx=[ia1(i+1):length(score_all_pa.fileName)];
    else if ia1(i)==ia1(end)%if last song
            song_out_idx=[ia1(i):length(score_all_pa.fileName)];%indexes of the notes of the song to use as test
            song_left_idx=[1:ia1(i)-1];
        else%if song is in the middle
            song_out_idx=[ia1(i):ia1(i+1)-1];%indexes of the notes of the song to use as test
            song_left_idx=[1:ia1(i)-1,ia1(i+1):length(score_all_pa.fileName)];
        end
    end
    score_songs_left=remove_instances(score_reduced,song_out_idx);
    score_song_out=remove_instances(score_reduced,song_left_idx);
    
    %aarff write
    atrib=attributes(score_songs_left,score_song_out);

    arff_write([pwd,'/dataOut/arffs/leaveOneOut/train/',model.fileName{i,1},'_train.arff'],score_songs_left,'train',atrib);
    arff_write([pwd,'/dataOut/arffs/leaveOneOut/test/',model.fileName{i,1},'_test.arff'],score_song_out,'test',atrib);
    
end


