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
%Find unique non repeated values
diff1=diff(emb.p2s(:,2));
diffcirc=circshift(diff(emb.p2s(:,2)),1);
diffcirc(1)=1;
uniqueidx=find(diff1.*diffcirc);

score_s2.emb(1:length(score_s2.pitch))={'y'};%initialize all notes valuies in "yes" ornamented
for i=1:length(uniqueidx),%for each non repeated note 
    %if the non repeated notes have no pitch changes is not ornamented.
    %(duration and onset will be modeled later.
    if emb.ioff(uniqueidx(i))==0 %&& emb.odd(uniqueidx(i))==0 && emb.boff(uniqueidx(i))==0,
        score_s2.emb{emb.p2s(uniqueidx(i),2)}='n';%the note is not ornamented
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

