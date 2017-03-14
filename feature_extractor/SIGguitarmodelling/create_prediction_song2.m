function create_prediction_song2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Embellishment note concatenation                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath('/Applications/MATLAB_R2013a.app/toolbox/miditoolbox')

load('dataOut/modelValidation/songFold.mat');

path_file_s='dataOut/scoreNmat/';
%path_file_p='dataOut/performanceNmat_alligned/';
path_file_p='/Users/sergio/Dropbox/PHD/guitarModelling/files2anotate/';
path_file_s2p='/Users/Sergio/Dropbox/PHD_1/guitarModelling/files2anotate/annotations/';
files=dir(path_file_s);%Get files names and attributes in a astructure array
numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files

%load emb data base
load('dataOut/noteDB/emb.mat','emb_all');


%create indexes for each song
[c1,ia1,~] = unique(score_all.fileName);
%ia1=[1,ia1'];
model.fileName=c1;

% %% attribute remove
% remove_idx=[5,   3,     18     ,32           ,29,                 31              ];%Index of attributes to be reomoved
% %           vel, chn , key, file_name  embCount,     emb_label
% attributes_list=fieldnames(score_all);%get attributes names
% score_reduced=rmfield(score_all,attributes_list(remove_idx));%remove indexed attributes

%%

for j=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(j,1).name(1),'.'))  &&~(strcmp(files(j,1).name(max(end-6,1):end),'p2s.mat'))%if to by pass . and .. DOS comands listed by dir as files
        %        if strcmp(files(i,1).name(end-2:end),'wav') &&  strcmp(files(i,1).name(end-5:end-4),'bt') %filter wav files only backing tracks
        
        i=find(strcmp(files(j,1).name(1:end-4),model.fileName));%get song index
        
        %% songs left and song out database split.
        if ia1(i)==1%conditionals for first song or last song indexing
            song_out_idx=[ia1(i):ia1(i+1)-1];%indexes of the notes of the song to use as test
            song_left_idx=[ia1(i+1):length(score_all.fileName)];
        else if ia1(i)==ia1(end)
                song_out_idx=[ia1(i):length(score_all.fileName)];%indexes of the notes of the song to use as test
                song_left_idx=[1:ia1(i)-1];
            else
                song_out_idx=[ia1(i):ia1(i+1)-1];%indexes of the notes of the song to use as test
                song_left_idx=[1:ia1(i)-1,ia1(i+1):length(score_all.fileName)];
            end
        end
        
        score_songs_left=remove_instances(score_all,song_out_idx);
        score_song_out=remove_instances(score_all,song_left_idx);
        
        %embellishment data base of remaining songs
        song_out_emb_idx=find(strcmp(files(j,1).name(1:end-4),emb_all.fileName));
        emb_song_left=remove_instances(emb_all,song_out_emb_idx);
        
        %% Convert to numerical data to do knn
        
        %Remove unrelevant attributes
        remove_idx=[5   ,3   ,18  ,32         ,29       ,31      ];%Index of attributes to be reomoved
        %           vel ,chn ,key ,file_name  ,embCount ,emb_label
        attributes_list=fieldnames(score_all);%get attributes names
        score_songs_left_r=rmfield(score_songs_left,attributes_list(remove_idx));%remove indexed attributes
        score_song_out_r=rmfield(score_song_out,attributes_list(remove_idx));%remove indexed attributes
        
        
        
        %This function transform struct to matrix and also, turns everything into numerical data.
        %descriptors are organized here in the same order as  showed in struct
        %window.
        score_m=struct2matix(score_songs_left_r);
        test_m=struct2matix(score_song_out_r);
        %       perform_m=struct2matix(perform_ds);%will be used for synthesis
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %    KNN note search and transformation   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        fprintf('KNN search\n');
        
        %read predicted values from Kstar model (weka)(first parse the file in order to erase : + * y and n characters)
        %emb_pred=dlmread('data_sets\predicted_emd_Kstar.txt','%*s %f %f %*s %*s');
        
        
        emb_pred_idx=find(strcmp('y',model.(['pred',num2str(i)]) ));%get the index of the notes wich are predicted to be ornamented (3rd column)
        
        emb_s_idx=find(score_m(:,27));%find index of embellished notes in the data base
        %             pitch    dur ,pre.dur ,nxt.dur ,onset_b.mod ,pre.int ,nxt.int, chordType, note2key, note2chord, tempo, phrase
        relevant=   [          5   ,8       ,10                   ,13      ,14                , 16       , 25   , 26    ];%choose relevant descriptors
        %relevant= 1:size(score_m,2);%use all!!!
        s       =1./[          1   ,1       ,1                    ,1       ,1                 ,1         , 1    , 1     ];%weight each descriptor
%        s=ones(1,27);%use all!!!
        M=normalizesig(score_m(:,relevant));%set and normalize matrix of relevant descriptors
        
        
        
        
        fprintf('Performing embellishment transformation for %s\n',files(j,1).name);
        load([path_file_s,'/',files(j,1).name],'nmat1','score_s');%load score nmat
        
        learned_nmat=nmat1;%initialize new embellished file from the test file
        
        for k=1:length(emb_pred_idx),%for each predicted ornamented note:
            
            note_id=emb_pred_idx(k);%(i'st note to be ornamented)
            note_v=test_m(note_id,:);%get note descriptors
            
            %% plot embellish prediction for current song
            figure(1);
            nmat1(emb_pred_idx,3)=2;%assign channel 2 to predicted embellished notes to viualize them in different color
            nmat1(note_id,3)=3;%assign channell 3 to se wich note is being transformed
            pianoroll(nmat1,'num');
            title([files(j,1).name,': score predicted ornamented notes'])
            
            
            %------->>>>>
            %Normalize note vector
            V=note_v(relevant)./max(score_m(:,relevant));%Divide vector by matrix maximum
            
            %knn search
            [idxp, dist] = knnsearch(M,V,'k',length(emb_s_idx),'Distance','seuclidean','scale',s);%this uses euclidean distance as default
            
            %look for the closest wich are ornamented
            closest_emb=find(ismember(idxp,emb_s_idx));%find indexes of the closest notes which are ornamented
%            if (idxp(closest_emb(1))==note_id)&&strcmp(score_file,test_score_file)%if the closest embellished note is itself,and is t
%                idx=idxp(closest_emb(2));%use the next embellished
%            else
                idx=idxp(closest_emb(1));%get the closest embellished
%            end
            pairs{k}=[note_id,idx];%this is to get track of the similar notes found
            
            
            %% plot closest note found
            figure(2)
            nmats=load([path_file_s,'/',score_songs_left.fileName{idx},'.mat'],'nmat1');%load song in which similar note was found
            [~,ia2,~] = unique(score_songs_left.fileName);
            closest_note_idx=idx-ia2(find(ia2<idx, 1, 'last' ))+1;
            nmats.nmat1(closest_note_idx,3)=2;
            pianoroll(nmats.nmat1);
            title(['Closest note found in song:',score_songs_left.fileName{idx}])
            
            %% transformation
            
            %having the note closest index we look in our embellish data base for the
            %transformation for that particular note. The output should be a Midi
            %matrix.
            
            %song_left_no_idx=find(strcmp(score_songs_left.emb,'n'));
            
            %song_lent_y_ds=remove_instances(
            
            
            p2s_all=[p2sprocess(emb_song_left.p2s(:,1)) , p2sprocess(emb_song_left.p2s(:,2))];%index note correspondence of all database
            emb_idx=find(p2s_all(:,2)==idx);%find the embelished note(s) index(es) that correspond to the note
            
            %% plot performed note
            
            figure(3)
            nmats=load([path_file_p,'/',score_songs_left.fileName{idx},'/',score_songs_left.fileName{idx},'.mat'],'nmat2');%load song in which similar note was found
            [~,ia2,~] = unique(emb_song_left.fileName);
            emb_note_idx_nmat2=emb_idx-ia2(find(ia2<emb_idx(1), 1, 'last' ))+1;
            nmats.nmat2(emb_note_idx_nmat2,3)=2;
            pianoroll(nmats.nmat2);
            title(['Embellished notes of corresponding note in performed song:',score_songs_left.fileName{idx}])
            
            
            
            
            %Create the new set of notes, based on the current note description. We
            %will create only MIDI information.
            transf_notes=struct;%initialize transformation structure
            transf_notes.onset_b=score_song_out.onset_b(note_id)+emb_song_left.boff(emb_idx);%create new onsets (beats)
            transf_notes.duration_b=gettempo(nmat1)*emb_song_left.odd_r(emb_idx);%create new durations(beats)%14dic2014 will be done based on tempo
            %transf_notes.duration_b=abs(score_song_out.duration_b(note_id)*emb_song_left.odd_r(emb_idx));%create new durations(beats)
            %transf_notes.duration_b=score_m(emb_idx,2);%create new durations(beats)
            transf_notes.ch=ones(length(emb_idx),1)*score_all.ch(1)*3;%create chanell column (beats). Multiply by 3 to assign 3rd channel so we have a different color for viewing purposes
            transf_notes.pitch=score_song_out.pitch(note_id)+emb_song_left.ioff(emb_idx);%create new pitch
            transf_notes.vel=ones(length(emb_idx),1)*score_all.vel(1);%notes. However this should go in accordance to energy.
            transf_notes.onset_s=transf_notes.onset_b*60/score_song_out.tempo(1);%transformation factor to go form beat to seconds
            transf_notes.dur_s=transf_notes.duration_b*60/score_song_out.tempo(1);%transformation factor to go form beat to seconds
            
            %convert structure to matrix
            transf_notes_nmat=struct2matix(transf_notes);
            
            %find the replacement position based on the offset generated by the notes
            %that have been already replaced.(meaning how much the original length of the song has
            %groun up to the moment).
            ins_idx=note_id+length(learned_nmat)-length(test_m);%insert index
            
            %replace the current note with the new set of notes in the test file
            learned_nmat(ins_idx,:)=transf_notes_nmat(1,:);%transform curretn note with first transformed note
            if length(emb_idx)>1, %if embelishment uses more than 1 note, then insert the rest
                learned_nmat=insertrows(learned_nmat,transf_notes_nmat(2:end,:),ins_idx);%insert the rest of transformed notes
            end
            
            scrsz = get(0,'ScreenSize');
            %figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])
            
            
            figure(4);
            pianoroll(learned_nmat)
            title([files(j,1).name,': score transformed notes'])
            
%            pause;
        end
        
        fprintf('Correcting duration of notes...\n');
        learned_nmat_c=dur_correct(learned_nmat);%correct duration (avoid overlaped notes) this is not working!!!
        figure (2)
        pianoroll(learned_nmat_c)
        save (['dataOut/leanrtSongs/',files(j,1).name(1:end-4),'.nmat'],'learned_nmat_c');
        pairs=pairs';%this is to get track of the pair of similar notes found
        

    end
end

end

function score_m = struct2matix(score);
%This function transform the score array into a regular matrix in order to
%make possible the use of the knnsearch function. It also changes
%everything into numerical data: y=1, n=0, mtr:0,1,2,3.

%if myIsField(score, 'tempo')
%  score.tempo=ones(length(score.pitch),1)*score.tempo;%create tempo column
%end

if myIsField(score, 'chord')
    score=rmfield(score,'chord');%remove chord text info, as we have it numerically as chord_id and type
end

[ext_id, ext_c]=chordExtensions('data_sets/chords_extensions.txt');%get chord type information

%change string values to numerical values y=1, n=0, mtr:0,1,2,3
temp=struct; %we create a temporal struct to easier handling
for i=1:length(score.onset_s)
    if myIsField(score, 'isChordN')
        switch score.isChordN{i}
            case 'y'
                temp.isChordN(i)=1;
            otherwise % case 'n'
                temp.isChordN(i)=0;
        end
    end
    if myIsField(score, 'emb')
        switch score.emb{i}
            case 'y'
                temp.emb(i)=1;
            otherwise %case 'n'
                temp.emb(i)=0;
        end
    end
    if myIsField(score, 'mtr')
        switch score.mtr{i}
            case 'ww'
                temp.mtr(i)=0;
            case 'w'
                temp.mtr(i)=1;
            case 's'
                temp.mtr(i)=2;
            otherwise % case 'ss'
                temp.mtr(i)=3;
        end
    end
    if myIsField(score, 'phrase')
        switch score.phrase{i}
            case 'i'
                temp.phrase(i)=-1;
            case 'm'
                temp.phrase(i)=0;
            case 'f'
                temp.phrase(i)=1;
        end
    end
    
    if myIsField(score, 'chord_type')
        if score.chord_type{i}=='c';
            temp.chord_type(i)=0;
        else
            temp.chord_type(i)=find(strcmp(ext_id{1},score.chord_type{i}));
            
        end
    end
    
    if myIsField(score, 'nar')
        for k=1:3
            if isempty(score.nar{i,k})%to avoid empty values be sent to switch op
                score.nar{i,k}=0;
            end
            switch score.nar{i,k}
                case 'P'
                    temp.nar(i,k)=1;
                case 'R'
                    temp.nar(i,k)=2;
                case 'D'
                    temp.nar(i,k)=3;
                case 'ID'
                    temp.nar(i,k)=4;
                case 'IP'
                    temp.nar(i,k)=5;
                case 'VP'
                    temp.nar(i,k)=6;
                case 'IR'
                    temp.nar(i,k)=7;
                case 'VR'
                    temp.nar(i,k)=8;
                otherwise
                    temp.nar(i,k)=0;
            end
        end
    end
end
if myIsField(score, 'isChordN')
    score.isChordN=temp.isChordN';%transpose and asign numerical value to each descriptor
end
if myIsField(score, 'emb')
    score.emb=temp.emb';
end
if myIsField(score, 'mtr')
    score.mtr=temp.mtr';
end
if myIsField(score, 'phrase')
    score.phrase=temp.phrase';
end
if myIsField(score, 'chord_type')
    score.chord_type=temp.chord_type';
end
if myIsField(score, 'nar')
    score.nar=temp.nar;
end
score_c=struct2cell(score);%convert struct to cell
score_m=cell2mat(score_c');%concert struc to matrix
end

function isFieldResult = myIsField (inStruct, fieldName)
% inStruct is the name of the structure or an array of structures to search
% fieldName is the name of the field for which the function searches
isFieldResult = 0;
f = fieldnames(inStruct(1));
for i=1:length(f)
    if(strcmp(f{i},strtrim(fieldName)))
        isFieldResult = 1;
        return;
    elseif isstruct(inStruct(1).(f{i}))
        isFieldResult = myIsField(inStruct(1).(f{i}), fieldName);
        if isFieldResult
            return;
        end
    end
end
end

function Mn=normalizesig(M)
Mn=M;%assign initial values and size to the resulting matrix
[x,y]=size(M);%get matrix size            p2s_all=p2sprocess(p2s(:,1))

for i=1:x%for each row
    Mn(i,:)=M(i,:)./max(M);%divide each row by each column maximum
end
end

function p2s_all=p2sprocess(p2s)
acum=0;
min_len=10;%minimum song length
len=0;
p2s_all=zeros(size(p2s));

for i=1:(length(p2s)-1)
    if p2s(i)==1&&len>min_len
        acum=acum+p2s(i-1);
        len=0;
    end
    p2s_all(i)=p2s(i)+acum;
    len=len+1;
end
end

function nmat2=dur_correct(nmat)
% This function searches for notes with a duration longer than the onset
% difference from the current note and the next note, and adjust the length
% of the note to this value.

nmat2=nmat;%initialiaze nmat2
for i=1:(length(nmat)-1)%for each note of the midi file:
    offset=nmat(i,1)+nmat(i,2);%define offset as: onset+duration
    if ~nmat(i+1,1)<nmat(i,1)
        if offset>nmat(i+1)%if onset is higher than next onset (overlap)
            nmat2(i,2)=nmat(i+1,1)-nmat(i,1);%duration = onset(next note)-onset(current note)
            nmat2(i,7)=nmat(i+1,6)-nmat(i,6);%same in seconds
        end
    end
end
end
