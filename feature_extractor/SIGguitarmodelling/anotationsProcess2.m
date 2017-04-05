function p2s=anotationsProcess2(path_file)

%this code process all the annotations done by musicians. It reads each of
%the stored data of one song and sume the pairs choosen by each musician.
%The output is a matrix in which each cell is the sume of votations of the
%currenr pair of notes. Ej.:
%                                         Seq2
%                                _______^_______
%                              /                          \
%
%                 /           Note1 Note2 Note3
%                 | note1 [   2        1        0    ]
% H=seq1  < note2 [   0        3        0    ]
%                 | note3 [   0        1        2    ]
%                 \


%path_file=uigetdir('*.*','Choose the folder of the anotated song');%Get the file and directory path where the mat files are stored
fileList=dir(path_file); 
fileListLen=length(fileList);
s2p=[];%initialize vector of pairs
numOfSongs=0;%initialize number of songs counter
for i=1:fileListLen
    if length(fileList(i,1).name)>4
        if strcmp(fileList(i,1).name(end-2:end),'mat')%go through all the list of files and extract the note pairs stored in tbk vector
            data=load([path_file,'/',fileList(i,1).name]);
%             if max(data.tbk(1,:))>max(data.tbk(2,:)) %if long sequence is first put it in second place
%                 temp=data.tbk(1,:);
%                 data.tbk(1,:)=data.tbk(2,:);
%                 data.tbk(2,:)=temp;
%             end
            s2p_from_data=create_s2p_FromAll_x_y(data.all_x,data.all_y,data.nmat1,data.nmat2);
            s2p=[s2p,s2p_from_data];%concatenate all the anotation vectors one after the other
            numOfSongs=numOfSongs+1; %increement number of songs
        end
    end
end


s2pSort=sort_sig(s2p); %This function searches each occurrence of each annotatted pair and sumes it.

[~,Idx]=sort(s2pSort(1,:));%use the column indices from sort() to sort all columns of trkbksort.  
s2pSort2=s2pSort(:,Idx);

%% Create matrix

 H=zeros(max(s2pSort2(2,:)),max(s2pSort2(1,:)));

for i=1:length(s2pSort2)
        H(s2pSort2(2,i),s2pSort2(1,i))=s2pSort2(3,i);
end
H(H>numOfSongs)=numOfSongs;

%get maximum values or eah performance note (row). Maximum agreement

[Hmax,Idx]=max(H');%get max values and indexs per row
perfVect=1:size(H,1);%create a vector for perfoemance notes
p2s=[perfVect',Idx'];%concatenate performance vecto with max index per row. this is note correspondance

H2=zeros(size(H));%initialize new matrix
for i=1:size(H,1)
    H2(i,Idx(i))=Hmax(i);%fill new matrix with max values
end
        

%plot matrix
 figure
 image(H, 'CDataMapping','scaled');figure(gcf);
 xlabel('score notes');
 ylabel('performed notes (descending)');
 hndl=colorbar;
 ylabel(hndl,'Agreement');
 title(path_file);
 hold off
 
 

plot (tbk(:,2),tbk(:,1),'k*')

tbk=load('tbk.mat');
plot (tbk.tbk2(:,2),tbk.tbk2(:,1),'k*');