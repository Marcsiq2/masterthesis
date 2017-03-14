function [chords]=chordBeatMat(nstruct)

j=1; %chord root index

%create notes vector
notes='CsDsEFsGsAsB';%%'s' character is used to handle enarmonics

chords=struct;
chordName={};
%% Build chords
for i=1:length(nstruct.rootAlter)
    switch nstruct.rootAlter{i}
        case 0
            chordName{i}= [char(nstruct.root(i)),char(nstruct.kindAbreviate(i))];
        case 1
            chordName{i}= [char(nstruct.root(i)),'#',char(nstruct.kindAbreviate(i))];
        case -1
            chordName{i}= [char(nstruct.root(i)),'b',char(nstruct.kindAbreviate(i))];
    end
end

%% Create matrix of chords (bar x beats).

 for i=1:max(nstruct.measure_n)%for 1 to number of bars
%    blank_id=find(isspace(chords.names{1,1}{i}));
    chordsXbar=length(find(nstruct.measure_c==i));%Calculate how many chords are at current bar
    
    if chordsXbar==0 && i~=1,
        for k=1:nstruct.timeBeats
        chords.mat{i,k}=chordName{j-1};
        end
    else if chordsXbar==0,
        continue
    else if chordsXbar==1,%if only one chord
        for k=1:nstruct.timeBeats
            chords.mat{i,k}=chordName{j};
        end
        j=j+1;
    else if chordsXbar==2,%if 2 chords at bar
        for k=1:nstruct.timeBeats
            if k==3,j=j+1;end
            chords.mat{i,k}=chordName{j};
        end
        j=j+1;
    else if chordsXbar==3,%if three chords (only 3/4 time signature case)
        if nstruct.timeBeats==4
            chords.mat{i,1}=chordName{j};
            chords.mat{i,2}=chordName{j};
            chords.mat{i,3}=chordName{j+1};
            chords.mat{i,4}=chordName{j+2};
        end
        if nstruct.timeBeats==3
            chords.mat{i,1}=chordName{j};
            chords.mat{i,2}=chordName{j+1};
            chords.mat{i,3}=chordName{j+2};
        end
        j=j+3;
   else if chordsXbar==4,%if four chords
        chords.mat{i,1}=chordName{j};
        chords.mat{i,2}=chordName{j+1};
        chords.mat{i,3}=chordName{j+2};
        chords.mat{i,4}=chordName{j+3};
        j=j+4;
   else %if more chords
       fprintf('%s\n','Error: max 1 chords per beat is allowed!');
       break;
       end
       end
        end 
        end
       end
       end
 end
    %eliminate inversions!!! (chech if how xml format handles inversions)
%      for i=1: size(chords.mat,1),
%         for j=1: size(chords.mat,2),
%             if strfind(chords.mat{i,j},'/')>0
%                 id=strfind(chords.mat{i,j},'/');%index where the "/" appears
%                 chords.mat{i,j}=chords.mat{i,j}(1:id-1);%assign base chord info only (symbol before the "/" idx)
%             end
%         end
%      end
%%get the chord root index
%chords.id=zeros(size(chords.mat,1),size(chords.mat,2))
 for i=1: size(chords.mat,1),
   for j=1: size(chords.mat,2),
       currentChord=char(chords.mat{i,j});
       if isempty(chords.mat{i,j})
           chords.id(i,j)=NaN;
           chords.mat{i,j}='nc';
       else if numel(currentChord==1)%if chord is only one letter (major chord such as C)
            chords.id(i,j)=strfind(notes,currentChord(1));%search for the root in vector
            else if (strcmp(currentChord(2),'b'))%If the root is flattern
            chords.id(i,j)=strfind(notes,currentChord(1))-1;%search for the root in vector minus 1 semitone
                else if (strcmp(currentChord(2),'#'));%if the root is sharp
                    chords.id(i,j)=strfind(notes,currentChord(1))+1; %search for the root in vector plus one semitone
                    else
                    chords.id(i,j)=strfind(notes,currentChord(1));%search for the root in vector
                    end 
                end
           end
       end
   end
 end
chords.id=chords.id-1;%substract 1 to get zero indexing
end