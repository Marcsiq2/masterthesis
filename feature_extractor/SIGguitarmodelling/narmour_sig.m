function nar=narmour_sig(nmat),
%This function calculates the Narmour strucutres on a midi file in nmat
%format. It parses the nmat matrix and for each note it classify the
%corresponding narmour structure for each of the three posible positions. 
%The classification is based on the work by Ramirez et al. 2006 and we have
%add two more classifiers: two long intervals in the same direction, and, a
%short interval followed by a long interval in the opposite direction.
%Long and short interval limit was set to 6 semitones. 

pc=pitch(nmat);% get pitch information in a vector.
nar=cell(length(pc),3);%Initialize an empty matrix of three columns for Narmour class for each note.
for i=1:length(pc)-2, %for each note
    notewin=pc(i:i+2); %create a note window of 3 notes
    dif1=diff(notewin); %diferentiate pitch to get intervals
    %tis=intsize2(notewin);
    if strcmp(intsize2(notewin),'ss')&&samedir(notewin) %get interval size and check direction.
        nar{i,1}='P';
    else
    if strcmp(intsize2(notewin),'ls')&&~samedir(notewin)
        nar{i,1}='R';
    else
    if dif1(1)==0&&dif1(2)==0
        nar{i,1}='D';
    else
    if dif1(1)==dif1(2) && dif1(1)<6
        nar{i,1}='ID';
    else
    if strcmp(intsize2(notewin),'ss')&&~samedir(notewin)
        nar{i,1}='IP';
    else
    if strcmp(intsize2(notewin),'sl')&&samedir(notewin)
        nar{i,1}='VP';
    else
    if strcmp(intsize2(notewin),'ls')&&samedir(notewin)
        nar{i,1}='IR';
    else
    if strcmp(intsize2(notewin),'ll')&&~samedir(notewin)
        nar{i,1}='VR';
    else
    if strcmp(intsize2(notewin),'ll')&&samedir(notewin)
        nar{i,1}='SA';
    else
    if strcmp(intsize2(notewin),'sl')&&~samedir(notewin)
        nar{i,1}='SB';
    else
        nar{i,1}='NA';
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
end
nar(1:end-1,2)=nar(2:end,1);
nar(1:end-2,3)=nar(3:end,1);
%fill out last columns
%1 col
nar{end-1,1}='NA';
nar{end,1}='NA';
%2 col
nar{end-2,2}='NA';
nar{end-1,2}='NA';
nar{end,2}='NA';
%3 col
nar{end-3,3}='NA';
nar{end-2,3}='NA';
nar{end-1,3}='NA';
nar{end,3}='NA';
end

function tis=intsize2(notewin)

%Given three notes' pitch, this function classify each of the two intervals
%betuen the notes as large or small, defining the limit in 6 semitones. 

dif1=diff(notewin);
if abs(dif1(1))<6&&abs(dif1(2))<6
    tis='ss';
else if abs(dif1(1))<6&&abs(dif1(2))>=6
    tis='sl';
else if abs(dif1(1))>=6&&abs(dif1(2))<6
    tis='ls';
    else
        tis='ll';
    end
    end
end
end
function sd=samedir(notewin)
%Given a set of three notes' pitch, this function returns 1 if the
%intervals betwen the two notes go in the same direction and zero
%otherwise. 

dif1=diff(notewin);
if dif1(1)*dif1(2)>0
    sd=1;
else
    sd=0;
end
end
        
            

