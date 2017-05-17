function [H, tbk] = dtwSig(nmat,nmat2, pitchW, durW,onsetW,iniLegatoW,lastLegatoW, inv,th, plot_figs)

%   legato onset cost: Here we are assuming that when an ornament of a note
%   is composed by a grup of notes, these notes are played in legato. So
%   when we have the case of a long note follwed by another note (long or
%   short) and an group note ornament is present, two possibilites can be
%   possible: the ornament belongs to the first (long) note, or is a
%   prepraration for the second (target) note. To infer which is the case,
%   we set a ornament onset descriptor. This is the onset of the first note
%   of the notes that compose the ornament. This improves the ornament
%   recognition in a high percent, still evaluation must be done. A similar
%   approach will be done for ornament offset.  The idea behind is that if
%   we take into account only the ornament cost the first half of the grup of
%   ornamented notes will be correlated to the fisrt note, whereas the
%   second half will be correlated to the secon (if pitch cost is similar
%   for the two notes). So if we use the ornament onset cost, if the group
%   of notes belong to fisrt note the ornament ....

%% Create matrix


H=zeros(size(nmat2,1)+1,size(nmat,1)+1);
H(1,1)=0;
tbk=[];
for i=2:size(nmat2,1)+1
    H(i,1)=inf;
end
for j=2:size(nmat,1)+1
    H(1,j)=inf;
end

for j=2:size(nmat,1)+1
    for i=2:size(nmat2,1)+1
        
        costPitch=pitchW*(nmat2(i-1,4)-nmat(j-1,4))^2; %pitch difference multiplid by a weight factor
        costDur=durW*(nmat2(i-1,2)-nmat(j-1,2))^2;%duration difference multiplied by a weight factor
        costOnset=onsetW*(nmat2(i-1,1)-nmat(j-1,1))^2;%onset difference multiplied by a weight factor
        costIniLegatoOnset=iniLegatoW*(findLegatoOnset(nmat2,i-1,th)-nmat(j-1,1))^2;%legato onset cost
        costLastLegatoOnset=lastLegatoW*(findLastLegatoOnset(nmat2,i-1,th)-nmat(j-1,1))^2;%last legato onset cost
        cost=costPitch+costDur+costOnset+costIniLegatoOnset+costLastLegatoOnset;%total cost
        H(i,j)=cost+min([H(i-1,j),H(i,j-1),H(i-1,j-1)]);
    end
end

%% Trace back

i= size(nmat2,1)+1;% go to top left corner
j= size(nmat,1)+1;% go to top left corner

tbk=[i,j];%initilize trace back
minDir=1;%inizialize minumun path value
while  (minDir~=0 && minDir~=inf)
    minDir=min ([H(i-1,j),H(i-1,j-1),H(i,j-1)]) ;%find minumun path value
    switch minDir % seatch for minimu value from top, top left and left cells
        case H(i-1,j) %if top cell is less then
          tbk=[tbk;i-1,j];% (insertion)
          i=i-1;%go to previous top cell
        case H(i-1,j-1)%match
          tbk=[tbk;i-1,j-1];
          i=i-1;%go to previous top left cell
          j=j-1;  
        case H(i,j-1)% deletion
             tbk=[tbk;i,j-1];
             j=j-1;%go back to left cell
     end
end

%% Invert correlated notes
  if strcmp(inv,'yes')%if inverted, correlated inversion must be done this way
      tbk(:,1)=(max(tbk(:,1))-tbk(:,1)+1)+1;%max-num+1... ej.: 12233345 -> 54333221(+1 cause indexes start from 2)
      tbk(:,2)=(max(tbk(:,2))-tbk(:,2)+1)+1;%max-num+1... ej.: 12233345 -> 54333221
  else%else just flip up down the vector
      tbk=flipud(tbk);
  end
 
 %% Complete gaps in trace back vector
 % Notes previous to first aligned couple are considered to be part of the
 % first note
 if tbk(1,1)~=2%if trace back of first position is different to 2 (first note) (i dimension)
     for  i=tbk(1,1)-1:-1:2 %from starting value on first sequence
         tbk=[i,tbk(1,2);tbk]; %fill out initial notes with first corresponcence notes couple
     end
 else if tbk(1,2)~=2%if trace back of first position is different to 2 (first note)(j dimension)
        for  i=tbk(1,2)-1:-1:2 %from starting value on first sequence
             tbk=[tbk(1,1),i;tbk]; %fill out initial notes with first corresponcence notes couple
        end
     end
 end
    
 %similar thing to final notes...
  if tbk(end,1)~=size(H,1)%if trace back of first position is different to the lenght of i dimension
     for  i=tbk(end,1)+1:size(H,1) %from starting value on first sequence to end
         tbk=[tbk;i,tbk(end,2)]; %fill out initial notes with first corresponcence notes couple
     end
 else if tbk(end,2)~=size(H,2)%if trace back of first position is different to 2 (first note)(j dimension)
        for  i=tbk(end,2)+1:size(H,2) %from starting value on second sequence to end
             tbk=[tbk;tbk(end,1),i]; %fill out initial notes with first corresponcence notes couple
        end
     end
  end
 
  %gap filling (on first sequence): do the same for second sequence)!
  i=1;
  while i<=length(tbk)-1
      tbkDif= tbk(i+1,1)-tbk(i,1);
      if tbkDif>1
        for j=1:tbkDif-1
            tbk=[tbk(1:i,:);tbk(i,1)+1,tbk(i,2);tbk(i+1:end,:)];
            i=i+1;
        end
      end
      i=i+1;
  end
  %gap filling (on second sequence)
    i=1;
  while i<=length(tbk)-1
      tbkDif= tbk(i+1,2)-tbk(i,2);
      if tbkDif>1
        for j=1:tbkDif-1
            tbk=[tbk(:,1:i);tbk(i,1),tbk(i,2)+1;tbk(:,i+1:end)];
            i=i+1;
        end
      end
      i=i+1;
  end
%  tbk=tbk-1;%reduce one index position as we used a initial row and column of zeros to create H matrix
  %Invert tbk
  
%remove first coumn (first position of H matrix set to zero) and reduce 1 index as H is zero indexed
tbk=tbk(2:end,:)-1;

 %% Plot aligment
 if plot_figs == 1
     figure;
     image(sqrt(H(2:end,2:end)), 'CDataMapping','scaled');
     figure(gcf);
     hold on
     plot (tbk(:,2),tbk(:,1),'k*');
     xlabel('score notes');
     ylabel('performed notes (descending)');
     hndl=colorbar;
     ylabel(hndl,'Cost');

     %plot piano roll
     aligmentPlot(nmat,nmat2,tbk,1);
 end
end
function legatoOnset=findLegatoOnset(nmat,i,th)

if i==1
    legatoOnset=nmat(i,1);
else
%    th=0.1;%threshold for legaro betwen notes 1/10 of beat
    gap=0;%
       while gap<th
           legatoOnset=nmat(i,1);%onset is the onset of previous legated note
           if i>1
               offsetPrevNote=nmat(i-1,1)+nmat(i-1,2);%offset = onset+duration
               gap=nmat(i,1)-offsetPrevNote;%onset of current note minus offset previous note
               i=i-1;%go backone note
           else
               break;
           end
       end
end
        
        

end
function lastLegatoOnset=findLastLegatoOnset(nmat,i,th)

if i==size(nmat,1);
    lastLegatoOnset=nmat(i,1);
else
%    th=0.1;%threshold for legaro betwen notes 1/10 of beat
    gap=0;%
       while gap<th
           lastLegatoOnset=nmat(i,1);%onset is the onset of next legated note
           if i<size(nmat,1);
               offsetCurrntNote=nmat(i,1)+nmat(i,2);%offset = onset+duration
               gap=nmat(i+1,1)-offsetCurrntNote;%onset of next note minus offset current note
               i=i+1;%advance one note
           else
               break;
           end
       end
end
        
        

end
