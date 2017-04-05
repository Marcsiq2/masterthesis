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
        fprintf('\n    Creating arff files...');
        %score_all_2=struct_cell_parse(score_all);%parse cell fields to cell char
        %mkdir([pwd,'/dataOut/leaveOneOut/']);
        atrib=attributes(score_all_pa,score_all_pa);%create atribute list
        arff_write([pwd,'/dataOut/arffs/embellish.arff'],score_all_pa,'train',atrib);%write train data set for embellishment

        fprintf('Done!\n');
    end
end

%%open pre calculated data
%     cd(pwd)
%     [filename,pathname]=uigetfile();
%     load([pathname,filename]);

%create arfs
fprintf('Done!\n');


fprintf('SUCCESS!!!')


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

score_s_pa.duration_rat = zeros(length(nmat1),1);
score_s_pa.onset_dev = zeros(length(nmat1),1);
score_s_pa.pitch_dev = zeros(length(nmat1),1);
score_s_pa.energy_rat = zeros(length(nmat1),1);

ia = [ia;length(nmat2)];%add last index position to index intevals of equal notes

for i = 1:length(ia)-1
    score_s_pa.duration_rat(transformation_ds.p2s(ia(i),2)) = sum(nmat2(ia(i):ia(i+1),2))/nmat1(i,2);
    score_s_pa.onset_dev(transformation_ds.p2s(ia(i),2)) = nmat2(ia(i),1) - nmat1(i,1);
    score_s_pa.energy_rat(transformation_ds.p2s(ia(i),2)) = (1/length(ia(i):ia(i+1))) * sum(nmat2(ia(i):ia(i+1),5))/nmat1(i,5);
    score_s_pa.pitch_dev(transformation_ds.p2s(ia(i),2)) = (1/length(ia(i):ia(i+1))) * sum(nmat2(ia(i):ia(i+1),5))/nmat1(i,5);
end

end

