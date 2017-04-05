function s2p=create_s2p_FromAll_x_y(all_x,all_y,nmat1,nmat2)

%%put all pair points in ascending order (users may have pick points in one
%%direction or the other).

[all_x , all_y]=orderPairsAscending(all_x,all_y);

%initilize trbk
s2p=zeros(size(all_x));


for i=1:(length(s2p))
    note1_idx=findNotePosition(all_x(1,i),all_y(1,i),nmat1);%find note 1 position in MIDI matrix 1
    note2_idx=findNotePosition(all_x(2,i),all_y(2,i),nmat2);%find note 2 position in MIDI matrix 2
    s2p(1,i)=note1_idx;%Asign note position to s2p vector
    s2p(2,i)=note2_idx;
end    
    

end

function timeVecIdx=findNotePosition(onset,note,nmat1);
timeVecIdx=find(nmat1(:,1)<=onset,1,'last');%find onset time interval in nmat (if polifonic could be many positions)
%note_idx=find(nmat1(timeVecIdx,4)==note);%find note pitch in time intervals found in nmat matrix previously
end


function [all_x,all_y]=orderPairsAscending(all_x,all_y)
for i=1:length(all_x)
    if all_y(1,i)<all_y(2,i)
        %swap all_y
        swap=all_y(1,i);
        all_y(1,i)=all_y(2,i);
        all_y(2,i)=swap;
        %swap all_x
        swap=all_x(1,i);
        all_x(1,i)=all_x(2,i);
        all_x(2,i)=swap;
    end
end
end

        