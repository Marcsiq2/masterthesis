function performance_actions_db_create
%% %%%%%%%%%This function should work always as batch!!!!
%if batch==1

%% Get performance directory path
%path_file_s=uigetdir('Choose the folder in which annotations are stored');%Get the directory path where the midi and xml files are stored
path_file_s=[pwd,'/dataOut/annotations'];%Get the directory path where the midi and xml files are stored
files=dir(path_file_s);%Get files names and attributes in a astructure array
numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files

% else
%
%     %% Get socre file path
%     path_file_s=uigetdir('Choose a annotation folder');%Get the directory path where the midi and xml files are stored
%     files.name=path_file_s(find(path_file_s=='/', 1, 'last' )+1:end);%Get files names and attributes in a astructure array
%     path_file_s=path_file_s(1:find(path_file_s=='/', 1, 'last' )-1);%get previous folder path
%     numberOfFiles=1;
% end

%path_scores=uigetdir('Get nmat score directory');
path_scores=[pwd,'/dataOut/scoreNmat/'];
flag1=0;
flag2=0;

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name(1),'.'))  &&~(strcmp(files(i,1).name(max(end-6,1):end),'p2s.mat'))%if to by pass . and .. DOS comands listed by dir as files
        %        if strcmp(files(i,1).name(end-2:end),'wav') &&  strcmp(files(i,1).name(end-5:end-4),'bt') %filter wav files only backing tracks
        %% Create aligment matrix
        fprintf(['    Creating Performance Actions database for: ', files(i,1).name],'....');
        
        load([pwd,'/dataOut/p2sAlignment/',files(i,1).name,'_p2s.mat'],'p2s','nmat1','nmat2');%read all anotated data of one song
        load([path_scores,'/',files(i,1).name,'.mat'],'score_s');
        
        %Shift both sequences to same octave
        octaveOffset=round((mean(nmat2(:,4))-mean(nmat1(:,4)))/12)*12;%mean of notes of first sequence minus mean of notes of second sequence
        nmat1(:,4)=nmat1(:,4)+octaveOffset;%shift octave
        
        transformation_ds = trans_ds_calc(nmat1,nmat2,p2s); %returns a structure
        transformation_ds = addAttribute(transformation_ds, files(i,1).name, 'fileName');  %set constant descriptors (ej. tempo) to each not
        
        
        %% calculate performance actions
        % is note embellished {yes , no}
        score_s_pa = isEmbellished(score_s,transformation_ds);
        % average duration_rat, onset_dev, pitch_dev, and energy_rat
        score_s_pa = averagePas(score_s_pa, nmat1, nmat2, transformation_ds);
        
        score_s_pa=addAttribute(score_s_pa, files(i,1).name, 'fileName');  %set constant descriptors (ej. tempo) to each n
        
        
        %% Concatenate with previous data of files already parsed SCORE
        
        if flag1==0%if first loop
            score_all_pa=score_s_pa;
            flag1=1;
        else
            score_all_pa=structCat(score_all_pa,score_s_pa);
        end
        %% concatenate data.... embellishments data base
        
        if flag2==0%if first loop
            transformation_all=transformation_ds;
            flag2=1;
        else
            transformation_all=structCat(transformation_all,transformation_ds);
        end
        fprintf('Done!\n');
    end
end

%%delete irrelevant attributes

score_all_pa = rmfield(score_all_pa, 'ch'); %midi channel... irrelevant.
score_all_pa = rmfield(score_all_pa, 'vel'); %In the escore there are not 
%dynamic indications so this value is always constant.
score_all_pa = rmfield(score_all_pa, 'measure'); %Measure..... I think this 
%is irrelevant. Does a mucisian is going to ornament more at the beguining 
%of the piece than in the end, or in the middle? However the last note is
%always ornamneted... but is not abuolute...
score_all_pa = rmfield(score_all_pa, 'chord');%...this is a label that has too many values!

fprintf('    Saving Performance Actions database....');
save([pwd,'/dataOut/noteDB/performanceActions.mat'],'transformation_all');
save([pwd,'/dataOut/noteDB/score_descriptors.mat'],'score_all_pa');
fprintf('Done!\n');

%score_all_pa = rmfield(score_all_pa, 'onset_b');%...the same happens with onset?
%NOTE: I'm skipping onset_b for modeling (because of previous reason),
%however I'm keeping it in the "mat" files because I need it at the synthesis stage. 

%create arfs
fprintf('    Creating arff files...\n');
fprintf('       Writin allEPAs.arff...\n');
%Write all PAs in one data base

atrib=attributes(score_all_pa,score_all_pa);%create atribute list
arff_write([pwd,'/dataOut/arffs/allEPAs.arff'],score_all_pa,'train',atrib,'all_EPAS');%write train data set for embellishment

%Create a data base for each EPA
    PA = {'embellish',...
        'durRat',...
        'onsetDev',...
        'pitchDev',...
        'energyRat',...
        'embellish_nom'...
        'duration_dev_nom',...
        'onset_dev_nom',...
        'energy_dev_nom'...
        };
    
for i=1:length(PA)
    fprintf('       Writting %s arff file...\n',PA{i});
    attribute2remove = prepareData(PA{i});
    score_all_pa_i = rmfield(score_all_pa,attribute2remove);%remove indexed attributes
    atrib=attributes(score_all_pa_i,score_all_pa_i);%create atribute list
    arff_write([pwd,'/dataOut/arffs/',PA{i},'.arff'],score_all_pa_i,'train',atrib,PA{i});%write train data set for embellishment
end


fprintf('Done!\n');


fprintf('SUCCESS!!!\n')


end

function transformation_ds = trans_ds_calc(nmat1,nmat2,p2s)
%Given a midi score and a midi performance of that score, we use the
%midi2ds to calculate note descriptors for each file, and then characterize
%the embelishments (transformations done) to each note of the score.

transformation_ds=struct;%create embelishment estucture
transformation_ds.p2s=p2s;

%Performance Actions: each note can be replaced by one or many set of notes, which are
%transformations with respect of the original note. For each note of the performed we know to which note corresponds,
%and the ornamentation. Performance actions are calulated as follows:

%Duration ratio: Duration_b_perform/Duration_b_score (%).
transformation_ds.duration_rat_b=nmat2(p2s(:,1),2)./nmat1(p2s(:,2),2);
%when a new note is presented, tranformation is calculated as:
%Duration_b_newnote * Dur_rat

%Onset deviation: Onset_b_performance - Onset_b_score
transformation_ds.onset_dev_b=nmat2(p2s(:,1),1) - nmat1(p2s(:,2),1);
%when a new note is presented, tranformation is calculated as:
%Onset_newnote + Onset_dev

%Energy ratio: Energy_perform/Energy_score
transformation_ds.energy_rat=nmat2(p2s(:,1),5) ./ nmat1(p2s(:,2),5);
%when a new note is presented, tranformation is calculated as:
%Vel_newnote * Energy_rat

%Pitch deviation: Pitch_performance - Pitch_score.
transformation_ds.pitch_dev=nmat2(p2s(:,1),4) - nmat1(p2s(:,2),4);
%when a new note is presented, tranformation is calculated as:
%Pitch_newnote + Pitch_dev

end

function score_s2=isEmbellished(score_s,emb)

score_s2=score_s;

%% count whit how many notes each note was embellish
count_vec=zeros(length(score_s.pitch),1);%initialize count vector with size of note matrix
j=1;%initialize note counter
i=1;
while i<length(emb.p2s)
    k=emb.p2s(i,2);%initialize note vector position
    while  (i<length(emb.p2s))&&(emb.p2s(i+1,2)==k)%if current note is equal to next note
        j=j+1;
        i=i+1;
        
    end
    count_vec(k)=j;%assign counted notes to current note vector position
    j=1; %inizialize note counter
    i=i+1;
    
end
score_s2.emb_count=count_vec;

%% Is the note embellished?
% %Find unique non repeated values
% diff1=diff(emb.p2s(:,2));
% diffcirc=circshift(diff(emb.p2s(:,2)),1);
% diffcirc(1)=1;
% uniqueidx=find(diff1.*diffcirc);

score_s2.emb(1:length(score_s2.pitch))={'n'};%initialize all notes valuies in "yes" ornamented
for i=1:length(score_s2.emb),%for each note
    
    %oct 2014: Here we have comented the if, cause we have decided to asume that non
    %repeated notes are not ornamented, even if there are pitch changes.
    %This is to take into account as embellishments notes that are
    %transformed to 2 or more notes only.
    
    
    if count_vec(i)~=1
        score_s2.emb{i}='y';%the note is ornamented
    end
end
score_s2.emb=score_s2.emb';%transpose the vector

%% Lable embellishments based on its complexity
% if embellished with one to three note: simple
% if embellished with more than three notes: complex
% if ommited:omited
% if not ormanemnted: n
score_s2.emb_label=[];
for i=1:length(score_s.pitch)
    if strcmp(score_s2.emb(i),'y')
        switch (score_s2.emb_count(i))
            case 0
                score_s2.emb_label{i}=['omited'];
            case 1
                score_s2.emb_label{i}=['simple'];
            case 2
                score_s2.emb_label{i}=['simple'];
            case 3
                score_s2.emb_label{i}=['simple'];
            otherwise
                score_s2.emb_label{i}=['complex'];
        end
    else
        score_s2.emb_label{i}=['n'];
    end
end
score_s2.emb_label=score_s2.emb_label';
end

function score_s_pa = averagePas(score_s_pa, nmat1, nmat2, transformation_ds)
% see compy book notes feb 5 2016
[~,ia,~] = unique(transformation_ds.p2s(:,2));%find unique notes indexes in p2s
if length(ia)~=length(transformation_ds.p2s(:,2))%if (not) all notes are unique
    ia = [ia;length(transformation_ds.p2s)];%add last index position to index intevals of equal notes
end


score_s_pa.duration_rat = zeros(length(nmat1),1);
score_s_pa.onset_dev = zeros(length(nmat1),1);
score_s_pa.pitch_dev = zeros(length(nmat1),1);
score_s_pa.energy_rat = zeros(length(nmat1),1);
score_s_pa.energy_dev = zeros(length(nmat1),1);
score_s_pa.duration_dev = zeros(length(nmat1),1);
score_s_pa.duration_dev_nom(1:size(nmat1,1)) = {'none'};
score_s_pa.onset_dev_nom(1:size(nmat1,1)) = {'none'};
score_s_pa.energy_dev_nom(1:size(nmat1,1)) = {'none'};

for i = 1:length(ia)-1
    
    %av duration ratio = [sum(duration of notes of ornament) + sum(gaps
    %betwen notes of the ornamnet)] / duration of the score note
    
    ornament_length = length(transformation_ds.p2s(ia(i):ia(i+1)))-1;
    gap_dur = 0;
    if (ornament_length > 1)
        for note_orn_i = ia(i):(ia(i) + ornament_length -1)-1
            gap_dur = gap_dur + ... %increase gap dur
                      nmat2(transformation_ds.p2s(note_orn_i+1,1),1)-... %onset of next ornamnent note minus
                      (nmat2(transformation_ds.p2s(note_orn_i,1),1) + nmat2(transformation_ds.p2s(note_orn_i,1),2));%offset current ornament note (onset + dur)    
        end
    end
    score_s_pa.duration_rat(transformation_ds.p2s(ia(i),2)) = (sum(nmat2(transformation_ds.p2s(ia(i):ia(i+1)-1,1),2))...sum of duration of the notes of the ornamnent
                                                                +gap_dur)/...duration of gaps between note ornaments
                                                                nmat1(transformation_ds.p2s(ia(i),2),2);%duration of note score
    
    %duration deviation nominal
    %duration difference = [sum(duration of notes of ornament) + sum(gaps
    %betwen notes of the ornamnet)] - duration of the score note
    duration_diff = (sum(nmat2(transformation_ds.p2s(ia(i):ia(i+1)-1,1),2))+gap_dur)- nmat1(transformation_ds.p2s(ia(i),2),2);
    score_s_pa.duration_dev(transformation_ds.p2s(ia(i),2)) = duration_diff;
    
    durationDiffMean = -0.3968;%values obtained after proscessing
    durationDiffStd  = 1.0622;
    
    if duration_diff >= durationDiffMean + 0.2 * durationDiffStd
        score_s_pa.duration_dev_nom{transformation_ds.p2s(ia(i),2)} = 'lengthen';
    else
        if duration_diff <= durationDiffMean - 0.2 * durationDiffStd
            score_s_pa.duration_dev_nom{transformation_ds.p2s(ia(i),2)} = 'shorten';
        else
            score_s_pa.duration_dev_nom{transformation_ds.p2s(ia(i),2)} = 'none';
        end
    end
            
    %av onset dev = (onset of the first note of the ornament) - (onset of the score note)
    score_s_pa.onset_dev(transformation_ds.p2s(ia(i),2)) = nmat2(transformation_ds.p2s(ia(i),1),1) - nmat1(transformation_ds.p2s(ia(i),2),1);
    
    %onset deviation nominal
    if score_s_pa.onset_dev(transformation_ds.p2s(ia(i),2)) >= 1/16%if onset deviation is...
        score_s_pa.onset_dev_nom{transformation_ds.p2s(ia(i),2)} = 'delay';
    else
        if score_s_pa.onset_dev(transformation_ds.p2s(ia(i),2)) <= -1/16
            score_s_pa.onset_dev_nom{transformation_ds.p2s(ia(i),2)} = 'advance';
        else
            score_s_pa.onset_dev_nom{transformation_ds.p2s(ia(i),2)} = 'none';
        end
    end
    
    % Wighted average for av enervy rat, y av pitch dev
    e_v = nmat2(transformation_ds.p2s(ia(i):ia(i+1)-1,1),5); %energy values
    p_v = nmat2(transformation_ds.p2s(ia(i):ia(i+1)-1,1),4); %pitch values
    w = nmat2(transformation_ds.p2s(ia(i):ia(i+1)-1,1),2); %weights based on duration
    
    %Energy dev
    %score_s_pa.energy_dev(transformation_ds.p2s(ia(i),2)) =...
    %round(sum(e_v.*w)/sum(w)) -...
    %nmat1(transformation_ds.p2s(ia(i),2),5);%based on score velocity (80) 
    
    %energy mean
    energyMeanNmat2 = sum(nmat2(:,5).*nmat2(:,2))/sum(nmat2(:,2));
    %energyMeanNmat2 = mean(nmat2(:,5))
    
    score_s_pa.energy_dev(transformation_ds.p2s(ia(i),2)) = round(sum(e_v.*w)/sum(w)) - energyMeanNmat2;%asi no dependemos de normalizar el audio!
    
    %Pitch dev
    score_s_pa.pitch_dev(transformation_ds.p2s(ia(i),2)) = round(sum(p_v.*w)/sum(w)) - nmat1(transformation_ds.p2s(ia(i),2),4);
    
    
    %energy_thres=max(nmat2(:,5))-min(nmat2(:,5));
    energy_thres=std(nmat2(:,5));
    
    %energy deviation nominal
    noteEnergyMean = sum(e_v.*w)/sum(w);
    if noteEnergyMean-energyMeanNmat2 <= -0.4*energy_thres
        score_s_pa.energy_dev_nom{transformation_ds.p2s(ia(i),2)} = 'piano';
    else
        if round(sum(e_v.*w)/sum(w))-energyMeanNmat2 >= 0.4*energy_thres
            score_s_pa.energy_dev_nom{transformation_ds.p2s(ia(i),2)} = 'forte';
        else
            score_s_pa.energy_dev_nom{transformation_ds.p2s(ia(i),2)} = 'none';
        end
    end

end
 score_s_pa.duration_dev_nom = score_s_pa.duration_dev_nom';  
 score_s_pa.onset_dev_nom = score_s_pa.onset_dev_nom';
 score_s_pa.energy_dev_nom = score_s_pa.energy_dev_nom';
% score_s_pa.energy_dev = score_s_pa.energy_dev';
 score_s_pa.energy_rat = (80 + score_s_pa.energy_dev)/80;
end

