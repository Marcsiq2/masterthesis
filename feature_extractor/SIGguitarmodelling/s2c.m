function c=s2c(s)
sc=struct2cell(s);
N=length(fieldnames(s));
M=length(sc{1});
if isfield(s,'nar')
    c=cell(M,N+2);
    narId=find(strcmp('nar',fieldnames(s)));
    for i=1:M
        k=1; 
        for j=1:N
            if j==narId
                for k=1:3
                    c{i,j+k-1}=sc{j,1}{i,k};   
                end
            else if isa(sc{j,1}(i),'cell')
                    c{i,j+k-1}=sc{j,1}{i};
            else
                    c{i,j+k-1}=sc{j,1}(i);
            end
            end
        end
    end
else
    c=cell(M,N);
    for i=1:N
        for j=1:M
            if iscell(sc{i,1}(j))
                c{j,i}=sc{i,1}{j};
            else
                c{j,i}=sc{i,1}(j);
           end
        end
    end
end
end
    


