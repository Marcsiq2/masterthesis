function score_s_pa = perfactions(score_s, nmat_s, nmat_p, p2s, score_fn) 

        
             
        %Shift both sequences to same octave
        octaveOffset=round((mean(nmat_p(:,4))-mean(nmat_s(:,4)))/12)*12;%mean of notes of first sequence minus mean of notes of second sequence
        nmat_s(:,4)=nmat_s(:,4)+octaveOffset;%shift octave
        
        transformation_ds = trans_ds_calc(nmat_s,nmat_p,p2s); %returns a structure
        transformation_ds = addAttribute(transformation_ds, score_fn, 'fileName');  %set constant descriptors (ej. tempo) to each not
        
        
        %% calculate performance actions
        % is note embellished {yes , no}
        score_s_pa = isEmbellished(score_s,transformation_ds);
        % average duration_rat, onset_dev, pitch_dev, and energy_rat
        score_s_pa = averagePas(score_s_pa, nmat_s, nmat_p, transformation_ds);
        
        score_s_pa=addAttribute(score_s_pa, score_fn, 'fileName');  %set constant descriptors (ej. tempo) to each n
end


% %%delete irrelevant attributes
% score_s_pa = rmfield(score_s_pa, 'ch'); %midi channel... irrelevant.
% score_s_pa = rmfield(score_s_pa, 'vel'); %In the escore there are not 
% %dynamic indications so this value is always constant.
% score_s_pa = rmfield(score_s_pa, 'measure'); %Measure..... I think this 
% %is irrelevant. Does a mucisian is going to ornament more at the beguining 
% %of the piece than in the end, or in the middle? However the last note is
% %always ornamneted... but is not abuolute...
% score_s_pa = rmfield(score_s_pa, 'chord');%...this is a label that has too many values!



function transformation_ds = trans_ds_calc(nmat_s,nmat_p,p2s)
%Given a midi score and a midi performance of that score, we use the
%midi2ds to calculate note descriptors for each file, and then characterize
%the embelishments (transformations done) to each note of the score.

transformation_ds=struct;%create embelishment estucture
transformation_ds.p2s=p2s;

%Performance Actions: each note can be replaced by one or many set of notes, which are
%transformations with respect of the original note. For each note of the performed we know to which note corresponds,
%and the ornamentation. Performance actions are calulated as follows:

%Duration ratio: Duration_b_perform/Duration_b_score (%).
transformation_ds.duration_rat_b=nmat_p(p2s(:,1),2)./nmat_s(p2s(:,2),2);
%when a new note is presented, tranformation is calculated as:
%Duration_b_newnote * Dur_rat

%Onset deviation: Onset_b_performance - Onset_b_score
transformation_ds.onset_dev_b=nmat_p(p2s(:,1),1) - nmat_s(p2s(:,2),1);
%when a new note is presented, tranformation is calculated as:
%Onset_newnote + Onset_dev

%Energy ratio: Energy_perform/Energy_score
transformation_ds.energy_rat=nmat_p(p2s(:,1),5) ./ nmat_s(p2s(:,2),5);
%when a new note is presented, tranformation is calculated as:
%Vel_newnote * Energy_rat

%Pitch deviation: Pitch_performance - Pitch_score.
transformation_ds.pitch_dev=nmat_p(p2s(:,1),4) - nmat_s(p2s(:,2),4);
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

function score_s_pa = averagePas(score_s_pa, nmat_s, nmat_p, transformation_ds)
% see compy book notes feb 5 2016
[~,ia,~] = unique(transformation_ds.p2s(:,2));%find unique notes indexes in p2s
if length(ia)~=length(transformation_ds.p2s(:,2))%if (not) all notes are unique
    ia = [ia;length(transformation_ds.p2s)];%add last index position to index intevals of equal notes
end


score_s_pa.duration_rat = zeros(length(nmat_s),1);
score_s_pa.onset_dev = zeros(length(nmat_s),1);
score_s_pa.pitch_dev = zeros(length(nmat_s),1);
score_s_pa.energy_rat = zeros(length(nmat_s),1);
score_s_pa.energy_dev = zeros(length(nmat_s),1);
score_s_pa.duration_dev = zeros(length(nmat_s),1);
score_s_pa.duration_dev_nom(1:size(nmat_s,1)) = {'none'};
score_s_pa.onset_dev_nom(1:size(nmat_s,1)) = {'none'};
score_s_pa.energy_dev_nom(1:size(nmat_s,1)) = {'none'};

for i = 1:length(ia)-1
    
    %av duration ratio = [sum(duration of notes of ornament) + sum(gaps
    %betwen notes of the ornamnet)] / duration of the score note
    
    ornament_length = length(transformation_ds.p2s(ia(i):ia(i+1)))-1;
    gap_dur = 0;
    if (ornament_length > 1)
        for note_orn_i = ia(i):(ia(i) + ornament_length -1)-1
            gap_dur = gap_dur + ... %increase gap dur
                      nmat_p(transformation_ds.p2s(note_orn_i+1,1),1)-... %onset of next ornamnent note minus
                      (nmat_p(transformation_ds.p2s(note_orn_i,1),1) + nmat_p(transformation_ds.p2s(note_orn_i,1),2));%offset current ornament note (onset + dur)    
        end
    end
    score_s_pa.duration_rat(transformation_ds.p2s(ia(i),2)) = (sum(nmat_p(transformation_ds.p2s(ia(i):ia(i+1)-1,1),2))...sum of duration of the notes of the ornamnent
                                                                +gap_dur)/...duration of gaps between note ornaments
                                                                nmat_s(transformation_ds.p2s(ia(i),2),2);%duration of note score
    
    %duration deviation nominal
    %duration difference = [sum(duration of notes of ornament) + sum(gaps
    %betwen notes of the ornamnet)] - duration of the score note
    duration_diff = (sum(nmat_p(transformation_ds.p2s(ia(i):ia(i+1)-1,1),2))+gap_dur)- nmat_s(transformation_ds.p2s(ia(i),2),2);
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
    score_s_pa.onset_dev(transformation_ds.p2s(ia(i),2)) = nmat_p(transformation_ds.p2s(ia(i),1),1) - nmat_s(transformation_ds.p2s(ia(i),2),1);
    
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
    e_v = nmat_p(transformation_ds.p2s(ia(i):ia(i+1)-1,1),5); %energy values
    p_v = nmat_p(transformation_ds.p2s(ia(i):ia(i+1)-1,1),4); %pitch values
    w = nmat_p(transformation_ds.p2s(ia(i):ia(i+1)-1,1),2); %weights based on duration
    
    %Energy dev
    %score_s_pa.energy_dev(transformation_ds.p2s(ia(i),2)) =...
    %round(sum(e_v.*w)/sum(w)) -...
    %nmat_s(transformation_ds.p2s(ia(i),2),5);%based on score velocity (80) 
    
    %energy mean
    energyMeannmat_p = sum(nmat_p(:,5).*nmat_p(:,2))/sum(nmat_p(:,2));
    %energyMeannmat_p = mean(nmat_p(:,5))
    
    score_s_pa.energy_dev(transformation_ds.p2s(ia(i),2)) = round(sum(e_v.*w)/sum(w)) - energyMeannmat_p;%asi no dependemos de normalizar el audio!
    
    %Pitch dev
    score_s_pa.pitch_dev(transformation_ds.p2s(ia(i),2)) = round(sum(p_v.*w)/sum(w)) - nmat_s(transformation_ds.p2s(ia(i),2),4);
    
    
    %energy_thres=max(nmat_p(:,5))-min(nmat_p(:,5));
    energy_thres=std(nmat_p(:,5));
    
    %energy deviation nominal
    noteEnergyMean = sum(e_v.*w)/sum(w);
    if noteEnergyMean-energyMeannmat_p <= -0.4*energy_thres
        score_s_pa.energy_dev_nom{transformation_ds.p2s(ia(i),2)} = 'piano';
    else
        if round(sum(e_v.*w)/sum(w))-energyMeannmat_p >= 0.4*energy_thres
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

