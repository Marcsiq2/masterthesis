
function trbkSort=sort_sig(trkbk)
    trbkSort=trkbk;%initialize output vector equal to input vector
%     idx_a=1;%initialize first note sequence
%     idx_b=1;%initialize second note sequene
    cntVec=[];
    i=1;
    while i<=length(trbkSort(1,:))%for each note in sequence 1
        cnt=0;%initialize counter
        idx_a=trbkSort(1,i);%search first couple
        idx_b=trbkSort(2,i);
        j=1;
        flag=0;
        while j<=length(trbkSort)%check each cell on vector
            if (trbkSort(1,j)==idx_a)
                if (trbkSort(2,j)==idx_b)% If the same couple is found
                    cnt=cnt+1;%add one to counter
                    if flag~=0
                        trbkSort(:,j)=[[],[]];%clear the couple
                    end
                    flag=1;
                end
            end
            j=j+1;
        end
        i=i+1;
        cntVec=[cntVec,cnt];%create counter vector
    end
    trbkSort=[trbkSort;cntVec];
end