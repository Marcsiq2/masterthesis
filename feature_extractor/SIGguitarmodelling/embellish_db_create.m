function embellish_db_create
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
        
        emb = embellish(nmat1,nmat2,p2s); %returns a structure
        emb=addAttribute(emb, files(i,1).name, 'fileName');  %set constant descriptors (ej. tempo) to each not
        
        
        %% is the note embellished?
        
        score_s=isEmbellished(score_s,emb);
        score_s=addAttribute(score_s, files(i,1).name, 'fileName');  %set constant descriptors (ej. tempo) to each n
        
        
        %% Concatenate with previous data of files already parsed SCORE
        
        if flag1==0%if first loop
            score_all=score_s;
            flag1=1;
        else
            score_all=structCat(score_all,score_s);
        end
        %% concatenate data.... embellishments data base
        
        if flag2==0%if first loop
            emb_all=emb;
            flag2=1;
        else
            emb_all=structCat(emb_all,emb);
        end
        fprintf('Done!\n');
    end
end

fprintf('    Saving Performance Actions database....');
save([pwd,'/dataOut/noteDB/performanceActions.mat'],'emb_all');
save([pwd,'/dataOut/noteDB/score_descriptors.mat'],'score_all');
fprintf('Done!\n');
%%open pre calculated data
%     cd(pwd)
%     [filename,pathname]=uigetfile();
%     load([pathname,filename]);

%create arfs
fprintf('    Creating arff files...');
%score_all_2=struct_cell_parse(score_all);%parse cell fields to cell char
atrib=attributes(score_all,score_all);%create atribute list
arff_write([pwd,'/dataOut/arffs/epas_all.arff'],score_all,'train',atrib);%write train data set for all performance actions
fprintf('Done!\n');


fprintf('SUCCESS!!!')


end

function emb = embellish(nmat1,nmat2,p2s)
%Given a midi score and a midi performance of that score, we use the
%midi2ds to calculate note descriptors for each file, and then characterize
%the embelishments (transformations done) to each note of the score.

emb=struct;%create embelishment estucture
emb.p2s=p2s;

%Embelishments: each note can be ornamented by a set of notes that are
%transformations with respect of the original note,  acording to the music
%context. For each note of the performed we know to which note corresponds,
%and the ornamentation is measured by beat offset (boff), interval offset (ioff), and
%duration in beats (already calculated as dur), with respect of the original note.
%We also calculated ornament duration difference (odd), and number of notes used to ornament.


%Interval offset with respect to original note: difference betwen the pitch of
%the each performance note and the pitch of its corresponding note in the
%original score.
emb.ioff=nmat2(p2s(:,1),4) - nmat1(p2s(:,2),4);

%Beat onset with respect to original note: here we rest the beat onset of
%each performed note and its corresponding note in the score. This way we
%measure anticipations or ritardations.
emb.boff=nmat2(p2s(:,1),1) - nmat1(p2s(:,2),1);

%ratio (with respect to the onset of the note)
emb.boff_r=(nmat2(p2s(:,1),1) - nmat1(p2s(:,2),1))./nmat1(p2s(:,2),1);

%Duration difference with respect to the original note (odr)... relevant? The problem
%here are the ornament notes that are the same duration regardless the
%original duration. (difference or ratio?)
emb.odd=nmat2(p2s(:,1),2) - nmat1(p2s(:,2),2);

%ratio(with respect to the duration of the note) 
%%% emb.odd_r=nmat2(p2s(:,1),2) ./nmat1(p2s(:,2),2);

%11 dic 2014: this ratio
%should be measured based on tempo and not duration of note. Because the in
%the case of long embellishments, this can affect articulation or even lead
%to overlaped notes. 
emb.odd_r=nmat2(p2s(:,1),2)./gettempo(nmat2);

emb.vel_r=(nmat2(p2s(:,1),5) - nmat1(p2s(:,2),5))/80; %energy variation (deviation) based on score velocity (80 midi num)

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
    
    
    if count_vec(i)>1
        score_s2.emb{i}='y';%the note is not ornamented
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
