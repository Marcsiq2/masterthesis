function create_prediction_song_app_1(batch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Predicted note concatenation                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if batch==1
    %path_file_s=uigetdir('Choose the folder in which scores are stored');%Get the directory path where the midi and xml files are stored
    path_file_s = [pwd,'/dataIn/score/'];
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    
else
    [file,path_file_s]=uigetfile('*.xml','Choose a score file');%Get the directory path where the midi and xml files are stored
    files.name=file;
    numberOfFiles=1;
end


%% Load PAs data base
load([pwd,'/dataOut/noteDB/performanceActions.mat']);
load([pwd,'/dataOut/noteDB/score_descriptors.mat']);


%create indexes for each song
[c1,ia1,~] = unique(score_all_pa.fileName);
%ia1=[1,ia1'];
model.fileName=c1;

%% For each file:

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name,'.'))&& ~(strcmp(files(i,1).name,'..'))&& ~(strcmp(files(i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files
        
        if strcmp(files(i,1).name(end-2:end),'xml') %filter xml files only
            
            %% songs left and song out database split.
            for j=1:length(ia1)
                %remaining songs used as train.
                %conditionals for first song or last song indexing
                if ia1(j)==1%if first song
                    song_out_idx=[ia1(j):ia1(j+1)-1];%indexes of the notes of the song to use as test
                    song_left_idx=[ia1(j+1):length(score_all_pa.fileName)];
                else if ia1(j)==ia1(end)%if last song
                        song_out_idx=[ia1(j):length(score_all_pa.fileName)];%indexes of the notes of the song to use as test
                        song_left_idx=[1:ia1(j)-1];
                    else%if song is in the middle
                        song_out_idx=[ia1(j):ia1(j+1)-1];%indexes of the notes of the song to use as test
                        song_left_idx=[1:ia1(j)-1,ia1(j+1):length(score_all_pa.fileName)];
                    end
                end
                score_songs_left=remove_instances(score_all_pa,song_out_idx);
                score_song_out=remove_instances(score_all_pa,song_left_idx);
                
                %embellishment data base of remaining songs
       %???         song_out_emb_idx=find(strcmp(files(j,1).name(1:end-4),emb_all.fileName));
       %???         emb_song_left=remove_instances(emb_all,song_out_emb_idx);
       
                %% Load Predictions
                emb_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/embellishment/predictions/',files(i,1).name(1:end-4),'.txt'],'%s');
                durRat_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/durRat/predictions/',files(i,1).name(1:end-4),'.txt'],'%f');
                energyRat_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/energyRat/predictions/',files(i,1).name(1:end-4),'.txt'],'%f');
                onsetDev_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/onsetDev/predictions/',files(i,1).name(1:end-4),'.txt'],'%f');
                pitchDev_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/pitchDev/predictions/',files(i,1).name(1:end-4),'.txt'],'%f');
                
                %% Data preparation
             
                %Attribute selection
                remove_idx = [...
                    ...DESCRIPTORS
                    1,...onset_b
                    2,...duration_b
                    3,...chn
                    ...4,...pitch
                    5,...vel
                    6,...onset_s
                    ...7,...dur_s
                    8,...measure
                    9,...pre_dur_b
                    10,...pre_dur_s
                    11,...nxt_dur_b
                    12,...nxt_dur_s
                    13,...onset_b_mod
                    14,...pitch_mod
                    15,...prev_int
                    16,...next_int
                    17,...keyFifts
                    18,...keyMode
                    19,...note2key
                    20,...chord
                    21,...chord_root
                    22,...chord_type
                    23,...note2chord
                    24,...isChordN
                    25,...mtr
                    26,...nar_rd
                    27,...nar_rr
                    28,...nar_id
                    29,...nar_cl
                    30,...nar_pr
                    31,...nar_co
                    32,...ton_stab
                    33,...mel_atract
                    34,...tessitura
                    35,...mobility
                    36,...complex_trans
                    37,...complex_expec
                    38,...tempo
                    39,...phrase
                    ...PAS
                    40,...embCount
                    41,...emb
                    42,...embLabel
                    43,...durRat
                    44,...onsetDev
                    45,...pitchDev
                    46,...energyRat
                    ...File Name for reference
                    47,...FileName
                    ];%Index of attributes to be reomovedattributes_list=fieldnames(score_all_pa);%get attributes names
                
                attributes_list=fieldnames(score_all_pa);%get attributes names
                score_train=rmfield(score_songs_left,attributes_list(remove_idx));%remove indexed attributes
                score_test=rmfield(score_song_out,attributes_list(remove_idx));%remove indexed attributes
                
                
                
                %This function transform struct to matrix and turns everything into numerical data.
                score_m=struct2matix(score_train);
                test_m=struct2matix(score_test);

%                 %       perform_m=struct2matix(perform_ds);%will be used for synthesis 
%                 %read predicted values from Kstar model (weka)(first parse the file in order to erase : + * y and n characters)
%                 %emb_pred=dlmread('data_sets\predicted_emd_Kstar.txt','%*s %f %f %*s %*s');
                
                
                test_emb_y_pred_idx=find(strcmp('y',emb_pred));%get the index of the notes wich are predicted to be ornamented (3rd column)                
                train_emb_y_idx=find(strcmp('y',score_songs_left.emb));%find index of 'yes' embellished notes in the data base
                train_emb_n_idx=find(strcmp('n',score_songs_left.emb));%find index of 'no' embellished notes in the data base
%Attrib sel       %             pitch    dur ,pre.dur ,nxt.dur ,onset_b.mod ,pre.int ,nxt.int, chordType, note2key, note2chord, tempo, phrase
%will be done in  %relevant=   [          5   ,8       ,10                   ,13      ,14                , 16       , 25   , 26    ];%choose relevant descriptors
%line 68          %s       =1./[          1   ,1       ,1                    ,1       ,1                 ,1         , 1    , 1     ];%weight each descriptor
                
                relevant= 1:size(score_m,2);%use all!!!
                s=ones(1,size(score_m,2));%use all!!!
                M=normalizesig(score_m(:,relevant));%set and normalize matrix of relevant descriptors
                
                
                
                
                fprintf('Performing embellishment transformation for %s\n',files(j,1).name);
                
                %% load inexpressive score
                load([pwd,'/dataOut/scoreNmat/',files(i,1).name(1:end-4),'.mat'],'nmat1');%load score nmat
                nmat_score=nmat1;
                nmat_learned=nmat_score;%initialize new embellished file from the test file
                
                for note_i=1:length(nmat_score),%for each note:
                    
                    note_v=test_m(note_i,:);%get note descriptors vector
                                     
                        
                        
                        
%                    note_id=emb_pred_idx(k);%(i'st note to be ornamented)
%                    note_v=test_m(note_id,:);%get note descriptors
                    
                    %% plot embellish prediction for current song
                    close all;
                    scrn_size=get(0,'Screensize');
                    figure('Name','Fig1','Position',[scrn_size(1) scrn_size(4)*5/4 scrn_size(3) scrn_size(4)/7]);
                    nmat_score(test_emb_y_pred_idx,3)=2;%assign channel 2 to predicted embellished notes to viualize them in different color
                    nmat_score(note_i,3)=3;%assign channell 3 to se wich note is being transformed
                    pianoroll(nmat_score);
                    str=[[files(i,1).name,' score.'],' Green: predicted ornamented notes.',' Red:note being transformed'];
                    title(str)
                    
                    
                    %------->>>>>
                    %Normalize note vector
                    V=note_v(relevant)./max(score_m(:,relevant));%Divide vector by matrix maximum
                    
                    %knn search
                    [idxp, dist] = knnsearch(M,V,'k',length(train_emb_y_idx),'Distance','seuclidean','scale',s);%this uses euclidean distance as default
                    
                    if strcmp(emb_pred(note_i),'y')%note emb pred = y
                         closest_emb=find(ismember(idxp,train_emb_y_idx));%find indexes of the closest notes which are ornamented
                         idx=idxp(closest_emb(1));%get the closest embellished
               
                    else %emb pred = n
                         closest_emb=find(ismember(idxp,train_emb_n_idx));%find indexes of the closest notes which are ornamented
                         idx=idxp(closest_emb(1));%get the closest embellished
                    end
        
                    pairs{note_i}=[note_i,idx];%this is to get track of the similar notes found
                    
                    
                    %% plot closest note found
                    figure('Name','Fig2','Position',[scrn_size(1) scrn_size(4)*1/2 scrn_size(3) scrn_size(4)/7]);
                    load([pwd,'/dataOut/scoreNmat/',score_songs_left.fileName{idx},'.mat'],'nmat1');%load song in which similar note was found
                    nmat_closest=nmat1;
                    [~,ia2,~] = unique(score_songs_left.fileName);
                    closest_note_idx=idx-ia2(find(ia2<=idx, 1, 'last' ))+1;
                    nmat_closest(closest_note_idx,3)=2;
                    pianoroll(nmat_closest);
                    title(['Closest note found in song:',score_songs_left.fileName{idx}])
                    
                    %% transformation
                    
                    %having the note closest index we look in our embellish data base for the
                    %transformation for that particular note. The output should be a Midi
                    %matrix.
                    
                    %song_left_no_idx=find(strcmp(score_songs_left.emb,'n'));
                    
                    %song_lent_y_ds=remove_instances(
                    
                    
                    %p2s_all=[p2sprocess(emb_song_left.p2s(:,1)) , p2sprocess(emb_song_left.p2s(:,2))];%index note correspondence of all database
                    %emb_idx=find(p2s_all(:,2)==idx);%find the embelished note(s) index(es) that correspond to the note
                    p2s_foundSong=load([pwd,'/dataOut/p2sAlignment/',score_songs_left.fileName{idx},'_p2s.mat'],'p2s');
                    
                    %% plot performed note
                    figure('Name','Fig3','Position',[scrn_size(1) scrn_size(4)*1/4 scrn_size(3) scrn_size(4)/7]);                 
                    load([pwd,'/dataOut/p2sAlignment/',score_songs_left.fileName{idx},'_p2s.mat'],'nmat2');%load song in which similar note was found
                    nmat_performed = nmat2;
                    %                   [~,ia2,~] = unique(emb_song_left.fileName);
%                    emb_note_idx_nmat2=emb_idx-ia2(find(ia2<emb_idx(1), 1, 'last' ))+1;
                    child_nmat_performed_idx=find(p2s_foundSong.p2s(:,2)==closest_note_idx);
                    transformation_foundSong_idx = find(strcmp([transformation_all.fileName],score_songs_left.fileName{idx}));
                    child_transformation_idx = transformation_foundSong_idx(child_nmat_performed_idx);
                    nmat_performed(child_nmat_performed_idx,3)=2;
                    pianoroll(nmat_performed);
                    title(['Corresponding notes in performed song:',score_songs_left.fileName{idx}])
                    
                    
                    
                    
                    %Create the new set of notes, based on the current note description. We
                    %will create only MIDI information.
                    transf_notes_nmat = zeros(length(child_nmat_performed_idx),7);%initialize nmat of transformed notes
                    %onset beats col:1
                    transf_notes_nmat(:,1) = score_song_out.onset_b(note_i) + transformation_all.onset_dev_b(child_transformation_idx);%create new onsets (beats)
                    %duration Beats col:2
                    transf_notes_nmat(:,2) = score_song_out.duration_b(note_i) * transformation_all.duration_rat_b(child_transformation_idx);%create new durations(beats)%14dic2014 will be done based on tempo
                    %onset sec col:6
                    transf_notes_nmat(:,6) = transf_notes_nmat(:,1)*60/score_song_out.tempo(note_i);%transformation factor to go form beat to seconds
                    %dur Sec col:7
                    transf_notes_nmat(:,7) = transf_notes_nmat(:,2)*60/score_song_out.tempo(note_i);%transformation factor to go form beat to seconds
                    %vel col:5
                    transf_notes_nmat(:,5) = transformation_all.energy_rat(child_transformation_idx) * score_all_pa.vel(1);%notes. 
                    %pitch col:4
                    transf_notes_nmat(:,4) = score_song_out.pitch(note_i) + transformation_all.pitch_dev(child_transformation_idx);%create new pitch
                    %chnn col:3
                    transf_notes_nmat(:,3) = ones(length(child_transformation_idx),1)*score_all_pa.ch(note_i)*3;%create chanell column (beats). Multiply by 3 to assign 3rd channel so we have a different color for viewing purposes
                          
                    %find the replacement position based on the offset generated by the notes
                    %that have been already replaced.(meaning how much the original length of the song has
                    %groun up to the moment).
                    ins_idx=note_i+length(nmat_learned)-length(test_m);%insert index
                    
                    %replace the current note with the new set of notes in the test file
                    nmat_learned(ins_idx,:)=transf_notes_nmat(1,:);%transform curretn note with first transformed note
                    if length(child_transformation_idx)>1, %if embelishment uses more than 1 note, then insert the rest
                        nmat_learned=insertrows(nmat_learned,transf_notes_nmat(2:end,:),ins_idx);%insert the rest of transformed notes
                    end
                    
                    %scrsz = get(0,'ScreenSize');
                    %figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])
                    
                   %% plot performed note
                    figure('Name','Fig4','Position',[scrn_size(1) scrn_size(1) scrn_size(3) scrn_size(4)/7]);                 
                    pianoroll(nmat_learned);
                    title([files(j,1).name,': score transformed notes'])
                    
                    %            pause;
                end
                
                fprintf('Correcting duration of notes...\n');
                learned_nmat_c=dur_correct(nmat_learned);%correct duration (avoid overlaped notes) this is not working!!!
                figure (2)
                pianoroll(learned_nmat_c)
                save (['dataOut/leanrtSongs/',files(j,1).name(1:end-4),'.nmat'],'learned_nmat_c');
                pairs=pairs';%this is to get track of the pair of similar notes found
                
                
            end
        end
        
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
        
        [ext_id, ext_c]=chordExtensions('/Users/chechojazz/Dropbox/PHD/Libraries/SIGGuitarModelling/data_sets/chords_extensions.txt');%get chord type information
        
        %change string values to numerical values y=1, n=0, mtr:0,1,2,3
        temp=struct; %we create a temporal struct to easier handling
        fieldNames = fieldnames(score);
        for i=1:length(score.(fieldNames{1}))
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
           if myIsField(score, 'keyMode')
                switch score.keyMode{i}
                    case 'major'
                        temp.keyMode(i)=1;
                    otherwise %case 'minor'
                        temp.keyMode(i)=0;
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
        if myIsField(score, 'keyMode')
            score.keyMode=temp.keyMode';
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