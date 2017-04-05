function create_prediction_song_app_1_seq_mod(batch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Predicted note concatenation
% Approach 1.
% - Notes are predicted to be ornamented with a learning algorithm
% - Retrieval is done based on knn for all notes (ornamented and no
% ornamented)
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

plot_op = input('Plot piano roll? (y=1,n=0):');fprintf('\n');

%% Load PAs data base
load([pwd,'/dataOut/noteDB/performanceActions.mat']);
load([pwd,'/dataOut/noteDB/score_descriptors.mat']);


%create indexes for each song
[c1,ia1,~] = unique(score_all_pa.fileName);
%ia1=[1,ia1'];
j=1;
model.fileName=c1;

%% For each file:

for file_i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(file_i,1).name,'.'))&& ~(strcmp(files(file_i,1).name,'..'))&& ~(strcmp(files(file_i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files
        
        if strcmp(files(file_i,1).name(end-2:end),'xml') %filter xml files only
            
            fprintf('Performing embellishment transformation for %s\n',files(file_i,1).name);            
            
            %% add prev duration ratio and prev onset dev for sequential modeling
            score_all_pa.prev_duration_rat = circshift(score_all_pa.duration_rat,1);
            score_all_pa.prev_duration_rat(ia1) = 0; %for the first note of each song previous PAs = 0
            score_all_pa.prev_onset_dev = circshift(score_all_pa.onset_dev,1);
            score_all_pa.prev_onset_dev(ia1) = 0; %for the first note of each song previous PAs = 0
            score_all_pa.prev_emb = circshift(score_all_pa.emb,1);
            score_all_pa.prev_emb(ia1) = {NaN}; %previous embellishment is null: como manejo esto?
 
            %% songs left and song out database split.
%            for j=1:length(ia1)
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
                j=j+1;
%            end
            score_songs_left=remove_instances(score_all_pa,song_out_idx);
            score_song_out=remove_instances(score_all_pa,song_left_idx);
                        
            %% Load Predictions
            emb_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/embellishment/predictions/',files(file_i,1).name(1:end-4),'.txt'],'%s');
            durRat_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/durRat/predictions/',files(file_i,1).name(1:end-4),'.txt'],'%f');
            energyRat_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/energyRat/predictions/',files(file_i,1).name(1:end-4),'.txt'],'%f');
            onsetDev_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/onsetDev/predictions/',files(file_i,1).name(1:end-4),'.txt'],'%f');
            pitchDev_pred = textread([pwd,'/dataOut/arffs/leaveOneOut/pitchDev/predictions/',files(file_i,1).name(1:end-4),'.txt'],'%f');
            
            %% Data preparation
            
            %Attribute selection for KNN
            remove_idx = [...
                ...DESCRIPTORS
                1,...onset_b
                ...2,...duration_b
                ...3,...pitch
                4,...onset_s
                5,...dur_s
                ...6,...pre_dur_b
                7,...pre_dur_s
                8,...nxt_dur_b
                9,...nxt_dur_s
                10,...onset_b_mod
                11,...pitch_mod
                ...12,...prev_int
                13,...next_int
                14,...keyFifts
                15,...keyMode
                16,...note2key
                17,...chord_root
                18,...chord_type
                19,...note2chord
                20,...isChordN
                21,...mtr
                22,...nar_rd
                23,...nar_rr
                24,...nar_id
                25,...nar_cl
                26,...nar_pr
                27,...nar_co
                28,...ton_stab
                29,...mel_atract
                30,...tessitura
                31,...mobility
                32,...complex_trans
                33,...complex_expec
                ...34,...tempo
                ...35,...phrase
                ...PAS
                36,...embCount
                37,...emb
                38,...embLabel
                39,...durRat
                40,...onsetDev
                41,...pitchDev
                42,...energyRat
                43,...durDevNom
                44,...onsetDevNom
                45,...EnergyDevNom
                46,...EnergyDev
                47,...File Name for reference
                48,...FileName
                ...49,...prev_duration_rat
                ...50,...prev_onset_dev
                ...51,...prev_emb
            ];
        
            % Remove indexed of attributes
            attributes_list=fieldnames(score_all_pa);%get attributes names
            score_train=rmfield(score_songs_left,attributes_list(remove_idx));%remove indexed attributes
            score_test=rmfield(score_song_out,attributes_list(remove_idx));%remove indexed attributes           
            
            % This function transform struct to matrix and turns everything into numerical data.
            matrix_train=struct2matix(score_train);
            matrix_test=struct2matix(score_test);
                        
            % Find indexes of embellished and non emebellished notes 
            test_emb_y_pred_idx=find(strcmp('y',emb_pred));%get the index of the notes wich are predicted to be ornamented (3rd column)
            train_emb_y_idx=find(strcmp('y',score_songs_left.emb));%find index of 'yes' embellished notes in the data base
            train_emb_n_idx=find(strcmp('n',score_songs_left.emb));%find index of 'no' embellished notes in the data base
            
            %% load inexpressive score
            load([pwd,'/dataOut/scoreNmat/',files(file_i,1).name(1:end-4),'.mat'],'nmat1');%load score nmat
            nmat_score=nmat1;
            nmat_learned=nmat_score;%initialize new embellished file from the test file
            
            %% KNN search
            fprintf('   concatenative sinth...\n')
            for note_i=1:length(nmat_score),%for each note:
                fprintf('      note %f: knn search...',note_i)
                %preprare data: create marices and vectors to use knn
                %matlab function
                if isnan(matrix_test(note_i,end))
                    note_v=matrix_test(note_i,1:end-1);
                    s=ones(1,size(matrix_train,2)-1);
                    M=normalizesig(matrix_train(:,1:end-1));
                    V=note_v./max(matrix_train(:,1:end-1));%Normalize note vector%Divide vector by matrix maximum
                else
                    note_v=matrix_test(note_i,:);%get note descriptors vector
                    s=ones(1,size(matrix_train,2));%weights
                    M=normalizesig(matrix_train);%set and normalize matrix of relevant descriptors
                    V=note_v./max(matrix_train);%Normalize note vector%Divide vector by matrix maximum
                end
                
                
                %                    note_id=emb_pred_idx(k);%(i'st note to be ornamented)
                %                    note_v=test_m(note_id,:);%get note descriptors
                %fprintf('done!\n')
                %% plot embellish prediction for current song
                if plot_op
                    close all;
                    scrn_size=get(0,'Screensize');
                    h(1) = figure('Name','Fig1','Position',[scrn_size(1) scrn_size(4)*3/4 scrn_size(3) scrn_size(4)/4]);%[left bottom width height]
                    nmat_score(test_emb_y_pred_idx,3)=2;%assign channel 2 to predicted embellished notes to viualize them in different color
                    nmat_score(note_i,3)=3;%assign channell 3 to se wich note is being transformed
                    pianoroll(nmat_score);
                    str=[[files(file_i,1).name,' score.'],' Green: predicted ornamented notes.',' Red:note being transformed'];
                    title(str)
                    win1 = nmat_score(note_i,1)-10;
                    wout1 = nmat_score(note_i,1)+10;
                    %axis([win1 wout1 ylim]);
                end
                %------->>>>>
                
                % knn search
                [idxp, dist] = knnsearch(M,V,'k',length(train_emb_y_idx),'Distance','seuclidean','scale',s);%this uses euclidean distance as default
                
                if strcmp(emb_pred(note_i),'y')%note emb pred = y
                    closest_emb=find(ismember(idxp,train_emb_y_idx));%find indexes of the closest notes which are ornamented
                    idx=idxp(closest_emb(1));%get the closest embellished
                    
                else %emb pred = n
                    closest_emb=find(ismember(idxp,train_emb_n_idx));%find indexes of the closest notes which are ornamented
                    idx=idxp(closest_emb(1));%get the closest embellished
                end
                
                
                % load closest song midi matrix and find the index of
                % the closest note in this matrix
                load([pwd,'/dataOut/scoreNmat/',score_songs_left.fileName{idx},'.mat'],'nmat1');%load song in which similar note was found
                nmat_closest=nmat1;
                [~,ia2,~] = unique(score_songs_left.fileName);
                closest_note_idx=idx-ia2(find(ia2<=idx, 1, 'last' ))+1;
                nmat_closest(closest_note_idx,3)=2;
                %% transformation
                fprintf('transforming note...',note_i);
                
                %having the note closest index we look in our embellish data base for the
                %transformation for that particular note. The output should be a Midi
                %matrix.
                
                %load score to performance note correspondence of song
                %containing the closest note
                p2s_foundSong=load([pwd,'/dataOut/p2sAlignment/',score_songs_left.fileName{idx},'_p2s.mat'],'p2s');
                
                load([pwd,'/dataOut/performanceNmat_alligned/',score_songs_left.fileName{idx},'.mat'],'nmat2');%load song in which similar note was found
                nmat_performed = nmat2;
                load([pwd,'/dataOut/p2sAlignment/',score_songs_left.fileName{idx},'_p2s.mat'],'nmat2');%load song in which similar note was found
                nmat_performed2 = nmat2;
                % TO DO
%                 if length(nmat_performed) ~= length(nmat_performed2) %3may2016 There is ane error in the data base: nmat2 of p2s is different form nmat 2 perfomed. TO DO...
%                     asdf=0;
%                 end
                % Work around: read nmat performed from p2s, and fix octave difrence
                oct_shift = round(mean(nmat_performed(:,4))) - round(mean(nmat_performed2(:,4)));
                nmat_performed2(:,4) = nmat_performed2(:,4)+ oct_shift;
                nmat_performed = nmat_performed2;
                               
                %find indexes of the transformed notes in the
                %performance MIDI matrix
                child_nmat_performed_idx=find(p2s_foundSong.p2s(:,2)==closest_note_idx);
                transformation_foundSong_idx = find(strcmp([transformation_all.fileName],score_songs_left.fileName{idx}));
                child_transformation_idx = transformation_foundSong_idx(child_nmat_performed_idx);
                
                % plot closest note found and its corresponding transformation;
                if note_i==14
                    asd=2;
                end
                if plot_op
                    
                    nmat_performed(child_nmat_performed_idx,3)=2;
                    h(2) = aligmentPlot(nmat_closest, nmat_performed,p2s_foundSong.p2s,1, [scrn_size(1) scrn_size(4)*1/4 scrn_size(3) scrn_size(4)*2/6]);
                    title(['Corresponding notes in performed song:',score_songs_left.fileName{idx}])
                    if ~isempty(child_nmat_performed_idx)
                        win = nmat_performed(child_nmat_performed_idx(1),1)-10;
                        wout = nmat_performed(child_nmat_performed_idx(1),1)+10;
                        %axis([win wout ylim]);
                    end
                end
                
                
                %Create the new set of notes, based on the current note description. We
                %will create only MIDI information.
                transf_notes_nmat = zeros(length(child_nmat_performed_idx),7);%initialize nmat of transformed notes
                %onset beats col:1
                transf_notes_nmat(:,1) = score_song_out.onset_b(note_i) + transformation_all.onset_dev_b(child_transformation_idx);%create new onsets (beats)
                %duration Beats col:2
                %26Abr2016,in the case of ornamets we will impose the real duration of the notes in beats.
            
                if strcmp(emb_pred(note_i),'y')%note emb pred = y
                    transf_notes_nmat(:,2) = nmat_performed(child_nmat_performed_idx,2);
                else
                    transf_notes_nmat(:,2) = score_song_out.duration_b(note_i) * transformation_all.duration_rat_b(child_transformation_idx);%create new durations(beats)%14dic2014 will be done based on tempo
                end
                %onset sec col:6
                transf_notes_nmat(:,6) = transf_notes_nmat(:,1)*60/score_song_out.tempo(note_i);%transformation factor to go form beat to seconds
                %dur Sec col:7
                transf_notes_nmat(:,7) = transf_notes_nmat(:,2)*60/score_song_out.tempo(note_i);%transformation factor to go form beat to seconds
                %vel col:5
                transf_notes_nmat(:,5) = transformation_all.energy_rat(child_transformation_idx) * 80;%notes velocity base line is 80 (midi number).
                %pitch col:4
                %2 may 2016: if not ornamented preserv original pitch
                if ~strcmp(emb_pred(note_i),'y') %If not ornamented
                    transf_notes_nmat(:,4) = score_song_out.pitch(note_i);%preserv original pitch
                else
                    transf_notes_nmat(:,4) = score_song_out.pitch(note_i) + transformation_all.pitch_dev(child_transformation_idx);%create new pitch
                end
                %chnn col:3
                transf_notes_nmat(:,3) = ones(length(child_transformation_idx),1)*4;%create chanell column (beats). Multiply by 4 to assign 4rd channel which is usually guitar chanell
                
                %% update prev dur rat and prev onset dev of the next note
                if note_i<size(nmat_score, 1)%if not the last note of the score
                    if size(transf_notes_nmat,1)==0%if closest note found is embellised as omited
                        matrix_test (note_i+1, end - 2) = 0;%applied duration rat
                        matrix_test (note_i+1, end - 1) = 0;%applied onset dev
                    else
                        matrix_test (note_i+1, end - 2) = sum(transf_notes_nmat(:,2))/nmat_score(note_i,2);%applied duration rat
                        matrix_test (note_i+1, end - 1) = transf_notes_nmat(1,1) - nmat_score(note_i,1);%applied onset dev
                    end
                    if size(transf_notes_nmat,1)==1%applied ornamentation (yes or no)
                        matrix_test (note_i+1, end) = 0;
                    else
                        matrix_test (note_i+1, end) = 1;
                    end
                end
                %% find the replacement position based on the offset generated by the notes
                %that have been already replaced.(meaning how much the original length of the song has
                %grown up to the moment).
                ins_idx=note_i+length(nmat_learned)-length(matrix_test);%insert index
                
                %% replace the current note with the new set of notes in the test file
                if size(transf_notes_nmat,1)==0%if closest note found is embellised as omited
                    nmat_learned(ins_idx,:)=[];
                else
                    nmat_learned(ins_idx,:)=transf_notes_nmat(1,:);%transform curretn note with first transformed note
                    if length(child_transformation_idx)>1, %if embelishment uses more than 1 note, then insert the rest
                        nmat_learned=insertrows(nmat_learned,transf_notes_nmat(2:end,:),ins_idx);%insert the rest of transformed notes
                    end
                end
                %scrsz = get(0,'ScreenSize');
                %figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])

                p2s{note_i}=[note_i,ins_idx];%this is to get track of the similar notes found

                %% plot performed note
                if plot_op
                    h(3) = figure('Name','Fig4','Position',[scrn_size(1) scrn_size(1) scrn_size(3) scrn_size(4)/5]);
                    pianoroll(nmat_learned);
                    title([files(j,1).name,': score transformed notes'])
                    %axis([win1 wout1 ylim]);
                end
                %            pause;
                
                %% Transform and concatenate audio samples
%                 if j==6
%                     qwsde=9;
%                 end
                if ~isempty(child_nmat_performed_idx) %if ornament is not "omitt note"
                    %sinthesize....
                
                    fprintf('sinthesizing and concatenating...')
                    % load wav of performed song in which the most similar note was found.
                    [performance_wav, fs] = audioread([pwd,'/dataIn/performed/wav/',score_songs_left.fileName{idx},'.wav']);
                    % extract the audio portion of the note
                    time_in = nmat_performed(child_nmat_performed_idx(1),6); %onset of the first note in seconds
                    time_out = nmat_performed(child_nmat_performed_idx(end),6) + ...onset of the last note in second plus
                        nmat_performed(child_nmat_performed_idx(end),7); % duration of the last note 8n seconds
                    if round(time_out*fs)>length(performance_wav)%if selected ornament is the last note and midi offset exceeds wav length...
                        time_out = length(performance_wav)/fs;%asign wave lenght to offset of the ornament
                    end
                    note_i_wav = performance_wav(round(time_in*fs):round(time_out*fs));

                    %Pitch transformation
                    %2 may 2016
                    if strcmp(emb_pred(note_i),'n') %if note is not ornamented, and pitch deviation !=0 => 
                        fscale = midi2hz(nmat_score(note_i,4))/midi2hz(nmat_performed(child_nmat_performed_idx(1),4));%fscale = original pitch/(pitch_performed)
                    else
                        fscale=(midi2hz(nmat_closest(closest_note_idx,4))/midi2hz(nmat_score(note_i,4)))^(-1);%calculate scaling factor
                    end
                    if (fscale ~= 1) %if pitch factor betwen performance and score is different to one
                        %transform pitch
                        [note_i_wav_p,~,~]= sps_edited(note_i_wav,fs,blackman(1001),2048,-113,20,16,fscale);%Transform note sps model
                    else
                        note_i_wav_p = note_i_wav;%else dont do transformation
                    end

                    %Duration transformation
                    %- in approach 1 duration transformation is only based on tempo
                    %- we assume no tempo changes whithin a piece
                    tscale = score_song_out.tempo(1)/score_songs_left.tempo(idx);
                    %transform duration
                    %[note_i_wav_p_t,~,~] =
                    %sps_timescale(note_i_wav_pitch,fs,w,N,t,maxnS,stocf,tscale);%Transform note sps model
                    note_i_wav_p_t = sigProc_pvoc(note_i_wav_p,tscale,2048);

                    %Concatenation
                    %create silence to first onset
                    offset_of_all = round((nmat_learned(end,6)+...onset of last note of learned nmat plus..
                        nmat_learned(end,7))*fs);%duration of last note of learned nmat
                    if note_i==1%if is the first note initilalize output vector to zeros
                        out_wav = zeros (offset_of_all,1);
                    end
                    
                    
                    onset_of_new =round( nmat_learned(ins_idx,6)*fs);%onset of first note of note/ornament being concatenated
                    if onset_of_new <= 0%if onset of first note is advanced we will force it to zero...
                        onset_of_new = 1;
                    end
                    temp_out = zeros(offset_of_all,1); %temporal vector of total length as the output
                    temp_out(onset_of_new : onset_of_new + length(note_i_wav_p_t)-1) = note_i_wav_p_t; %Insert new note/ornament at position in temporal output

                    if length(out_wav)~=length(temp_out)
                        lenDiff = length(out_wav)-length(temp_out);
                        if lenDiff>0
                            temp_out = [temp_out; zeros(lenDiff, 1)]; %add (as needed) zeros to the output vector
                        else
                            out_wav = [out_wav; zeros(-lenDiff, 1)]; %add (as needed) zeros to the output vector
                        end
                    end
                    out_wav = out_wav + temp_out; %sum previous notes to temporal output (update notes in output vec)
                    if plot_op
                        %pause(10);
                        %figure(5)
                        %plot(out_wav)
                    end
                    %Uncomment for debuging: listen to each sinthesized note/ornament
                    %sound(out_wav,fs)
                    fprintf('done!\n')
                else
                fprintf('note ommited... done!\n');    
                end
            end
            
            fprintf('   Saving learnt song...');
            %                learned_nmat_c=dur_correct(nmat_learned);%correct duration (avoid overlaped notes) this is not working!!!
            %                figure (2)
            %                pianoroll(learned_nmat_c)
            tsig1 = 4;%defaults but has to be retrieved from xml
            tsig2 =4;%defaults but has to be retrieved from xml
            writemidi_java(nmat_learned,[pwd,'/dataOut/learntSongs/approach_1/',files(file_i,1).name(1:end-4),'.mid'],120,score_song_out.tempo(1),tsig1,tsig2);
            %writemidi(nmat_learned,[pwd,'/dataOut/learntSongs/approach_1/',files(j,1).name(1:end-4),'.mid'],120,score_song_out.tempo(1));
            save ([pwd,'/dataOut/learntSongs/approach_1/',files(file_i,1).name(1:end-4),'.mat'],'nmat_learned');
            audiowrite([pwd,'/dataOut/learntSongs/approach_1/',files(file_i,1).name(1:end-4),'.wav'],out_wav,fs);
            save ([pwd,'/dataOut/learntSongs/approach_1/',files(file_i,1).name(1:end-4),'_p2s.mat'],'p2s');            
%            savefig(h, [pwd,'/dataOut/learntSongs/approach_1/',files(file_i,1).name(1:end-4),'.fig']);
            %pairs=pairs;%this is to get track of the pair of similar notes found
            fprintf('done!\n');            
            
        end
    end    
end
end
function score_m = struct2matix(score)
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
    if myIsField(score, 'prev_emb')
        switch score.prev_emb{i}
            case 'y'
                temp.prev_emb(i)=1;
            case 'n'
                temp.prev_emb(i)=0;
            otherwise %case 'null'
                temp.prev_emb(i) = NaN;
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
if myIsField(score, 'prev_emb')
    score.prev_emb=temp.prev_emb';
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