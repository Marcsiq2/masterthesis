function arff_write(filename,s,trainOrTest,atrib, relationName)
%This function writes a arff file form a structure array and a cell array of
%attributes. The trainOrtest indicator defines if the last colum should be
%filled with actual values or by interrogation marks "?".
%filename
%structure
%[train, test]
%atrib (vector)
%relationName

%if isfield(s,'tempo')
%    s=rmfield(s,'tempo');
%end

cell_class=struct_class(s);%clasify class double=0 cell=1

header=fieldnames(s);

if isfield(s,'nar')%this is to add 3 narmour class descriptors to the header
    id=find(strcmp('nar',header));%find nar position on header vector
    cell_class=[cell_class(1:id);1;1;cell_class(id+1:end)];
    headend=['nar1' 'nar2' 'nar3' header(id+1:end)']';
    header=[header(1:id-1);headend];
end


c=s2c(s);

%Set up text and numbers format
format2=[];%initialize instances format

for i=1:(length(header))%we will concatenate strings to the size of headers
    if i~=(length(header))%if is not the last
        if cell_class(i)==0
            format2=[format2,'%f,'];%if not cell class use float format
        else
            format2=[format2,'%s,'];%else use string format
        end
    else
        
        if cell_class(i)==0
            format2=[format2,'%f\r\n,'];%if not cell class use float format
        else
            format2=[format2,'%s\r\n,'];%else use string format
        end
        
        % %        if isfield(s,'emb')&&strcmp(trainOrTest,'test')
        %             format2=[format2,'%s\r\n'];
        %  %       else
        %   %          format2=[format2,'%f\n'];
        %    %     end
    end
end
%c=c';

%c2(:,18)=c{:,18};

%include headers format for arff check them out!!! and then a printf for
%each....
%slash_idx = strfind(filename,'/');
%undscore_idx = strfind(filename,'_');
%if isempty(undscore_idx)
title=['@relation ',relationName];
%else
    
%    title=['@relation ',filename(slash_idx(end):undscore_idx(end)-1)];
    
%end

%written to
%Write text file
fid=fopen(filename,'w');
fprintf(fid,'%s\n','% This data was collected by Sergio Giraldo, MTG, Pompeu Fabra University, 2016 (sergio.giraldo@upf.edu). If you make use of this data please refer to the following citattions:');
fprintf(fid,'%s\n%s\n\n','% Giraldo, Sergio, and Ramirez, Rafael (2015). Computational modeling of ornamentation in jazz guitar music, In proc. of International Symposium in Performance Science, ISPS 2015, September, Kyoto, Japan.','% Giraldo, Sergio, and Ramirez, Rafael(2015) . Computational Generation and Synthesis of Jazz Guitar Ornaments using Machine Learning Modeling. In proc. of International Workshop in Machine Learning and Music MML 2015, August, Vancouver, Canada.');
fprintf(fid,'%s\n\n',title);
fprintf(fid,'%s\n',atrib{:});
fprintf(fid,'%s\n','');
fprintf(fid,'%s\n','@data');
for i=1:size(c,1)
    fprintf(fid,format2,c{i,:});
end
fclose(fid);
end

function cell_class=struct_class(s)
%This function retrieves a vector of the same length of the number of
%fields of a structure, containing and indicator of the class of the cells
%of a particular field, being 1 for cell class, and zero other wise.
header=fieldnames(s);
cell_class=zeros(length(header),1);
for i=1:length(header)
    switch class(s.(header{i}))
        case 'cell'
            cell_class(i)=1;
        otherwise
            cell_class(i)=0;
    end
end
end

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
            else
                %                 i
                %                 j
                %                 if (i==1378 && j==33)
                %                     lkjlk=0;
                %                 end
                if (i==744 && j==43)
                    sdfsd=1;
                end
                if isa(sc{j,1}(i),'cell')
                    c{i,j+k-1}=sc{j,1}{i};
                else
                    
                    if isinf(sc{j,1}(i))
                        c{i,j+k-1} = NaN;
                    else
                        c{i,j+k-1}=sc{j,1}(i);
                    end
                    %c{i,j+k-1}=sc{j,1}(i);
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
                if isinf(sc{i,1}(j))
                    c{j,i} = NaN;
                else
                    c{j,i}=sc{i,1}(j);
                end
            end
        end
    end
end
end



