function leaveOneOutArffCreate
    %Function to create regression experiment
    %Create option for classification experiment
    PA = {'embellishment',...
        'durRat',...
        'onsetDev',...
        'pitchDev',...
        'energyRat',...
        ...'duration_dev_nom',...
        ...'onsetDev_nom',...
        ...'energyDev_nom'...
        };
    for i=1:length(PA)
        leaveOneOutArffCreatePA(PA{i});
    end
end

function leaveOneOutArffCreatePA(PA)

%PA: performance action:
%   - embellishment
%   - durRat
%   - onsetDev
%   - pitchDev
%   - energyRat

load([pwd,'/dataOut/noteDB/score_descriptors.mat']);

%create indexes for each song
[c1,ia1,~] = unique(score_all_pa.fileName);
ia1=[ia1'];
model.fileName=c1;


%% attribute remove

%remove atrributes
attribute2remove = prepareData(PA);

%attributes_list=fieldnames(score_all_pa);%get attributes names
score_reduced=rmfield(score_all_pa,attribute2remove);%remove indexed attributes
atrib=attributes(score_reduced,score_reduced);

%%% arff write all songs for each Performance Action
PA_file=[pwd,'/dataOut/arffs/',PA,'.arff'];
arff_write(PA_file,score_reduced,'train',atrib);
%%feature selection... this is to include feature selection here, but the problem is to clean the output data...
% % 
% % scheme = 'weka.attributeSelection.CfsSubsetEval -M -s "weka.attributeSelection.BestFirst -D 1 -N 5"';
% % 
% % system(['unset DYLD_FRAMEWORK_PATH DYLD_LIBRARY_PATH; java -cp /Applications/weka-3-6-13-oracle-jvm.app/Contents/Java/weka.jar -Xmx1024m ',scheme,' -i ',PA_file,' >> ',pwd,'/dataOut/weka_tmp_files/output.txt']);
% % 
% % fid=fopen([pwd,'/dataOut/weka_tmp_files/output.txt']);
% % textscan(fid,'*%s',1, 'headerlines' , 18);
% % if 
% %     format = '%s %s %f, %f, %f, %*[^\n]';
% % else
% %     format = '%f %f %f %f';
% % end
% % pred = textscan(fid, format);
% % fclose(fid);

%%leave one out
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
    
    %arff write for leave one out
    fprintf('   Creating %s leave One Out train and test arff files for: %s\n', PA, model.fileName{i,1});
    atrib=attributes(score_songs_left,score_song_out);
    
    arff_write([pwd,'/dataOut/arffs/leaveOneOut/',PA,'/train/',model.fileName{i,1},'_train.arff'],score_songs_left,'train',atrib);
    arff_write([pwd,'/dataOut/arffs/leaveOneOut/',PA,'/test/',model.fileName{i,1},'_test.arff'],score_song_out,'test',atrib);
end
end

