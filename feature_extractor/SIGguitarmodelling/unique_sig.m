function p2s2=unique_sig(p2s)
%function similar to unique but works with matrices. It deletes the second
%ocurrence in the fist column if repeated. Assumes that the matrix is
%sorted by first colum.
p2s2=p2s;
for i=2:length(p2s2) 
    if i>length(p2s2)
        break;
    end
    if p2s2(i,1)==p2s2(i-1,1)
        p2s2(i,:)=[];
    end
end
end