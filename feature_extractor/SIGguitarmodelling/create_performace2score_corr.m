function create_performace2score_corr(batch)

if batch==1
    
    %% Get performance directory path
    %path_file_s=uigetdir('Choose the folder in which annotations are stored');%Get the directory path where the midi and xml files are stored
    path_file_s=[pwd,'/dataOut/annotations/'];
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    
else
    
    %% Get score file path
    path_file_s=uigetdir('*.wav','Choose a annotation folder');%Get the directory path where the midi and xml files are stored
    files.name=path_file_s(find(path_file_s=='/', 1, 'last' )+1:end);%Get files names and attributes in a astructure array
    path_file_s=path_file_s(1:find(path_file_s=='/', 1, 'last' )-1);%get previous folder path
    numberOfFiles=1;
end

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name(1),'.'))  &&~(strcmp(files(i,1).name(max(end-6,1):end),'p2s.mat'))%if to by pass . and .. DOS comands listed by dir as files
        %        if strcmp(files(i,1).name(end-2:end),'wav') &&  strcmp(files(i,1).name(end-5:end-4),'bt') %filter wav files only backing tracks
        %% Create aligment matrix
        fprintf(['Parsing song:', files(i,1).name,'...']);
        
        [p2s,nmat1,nmat2]=anotationsProcess2([path_file_s,'/',files(i,1).name]);%read all anotated data of one song
        
        swap=p2s(:,1);
        p2s(:,1)=p2s(:,2);
        p2s(:,2)=swap;
        
        p2s=sort(p2s,1);
        
        %note omisions... If a score note is omited in the performance
        %(or two notes of the score are related to one of the
        %performance, we ommit the second one... TO THINK!!!...
        p2s=unique_sig(p2s);
        p2s=unique_sig(p2s); %tree performance notes repeated.... doesnt work...!! 13 may 2014
        
        %plot correspondence
        %if(input('    plot alligment? (y=1,n=0):'))
%             fprintf(['    Printing score vs perform aligment.\n    Check for errors and press any key...\n']);
%             close all;
%             figure (2)
%             plot(p2s(:,2),p2s(:,1),'*');
%             set(gca,'YDir','reverse');
%             xlabel('score notes');
%             ylabel('performed notes (descending)');
%             hndl=colorbar;
%             ylabel(hndl,'Agreement');
%             hold off
% 
%             octShift=1;
%             pnrll=aligmentPlot(nmat1,nmat2,p2s,octShift);
        %end
        %% Save MIDI matrix, MIDI structure, and Descriptors structure
        
        fprintf(['    Saving p2sAlignment...']);
        save( [pwd,'/dataOut/p2sAlignment/',files(i,1).name,'_p2s.mat'], 'p2s','nmat1','nmat2');
        fprintf('Done!\n');
    end
end

fprintf('Success!\n');

end

function [p2s, nmat1 , nmat2]=anotationsProcess2(path_file)

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
    if ~(strcmp(fileList(i,1).name(1),'.'))  %if to by pass . and .. DOS comands listed by dir as files
        
        %    if length(fileList(i,1).name)>4
        if strcmp(fileList(i,1).name(end-2:end),'mat')&&~(strcmp(fileList(i,1).name(end-6:end),'p2s.mat'))%go through all the list of files and extract the note pairs stored in tbk vector
            data=load([path_file,'/',fileList(i,1).name]);
            %             if max(data.tbk(1,:))>max(data.tbk(2,:)) %if long sequence is first put it in second place
            %                 temp=data.tbk(1,:);
            %                 data.tbk(1,:)=data.tbk(2,:);
            %                 data.tbk(2,:)=temp;
            %             end
            if ~isempty(data.all_x) %debug
                s2p_from_data=create_s2p_FromAll_x_y(data.all_x,data.all_y,data.nmat1,data.nmat2);
                s2p=[s2p,s2p_from_data];%concatenate all the anotation vectors one after the other
            else
                fprintf('\n    Current annotation file %s has no data', fileList(i,1).name)
                fprintf('\n    ...skipping file\n')
            end
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
    if s2pSort2(1,i)~=0
        H(s2pSort2(2,i),s2pSort2(1,i))=s2pSort2(3,i);
    end
end
H(H>numOfSongs)=numOfSongs;

%% get maximum values or eah performance note (row). Maximum agreement
i=1;
%get maximun agreement in vector
while i<=length(s2pSort2)
    %get maximun agreement in vector
    idx=find(s2pSort2(2,:)==s2pSort2(2,i));%find all annotations of each note
    idx_max=idx(s2pSort2(3,idx)==max(s2pSort2(3,idx)));%find de maximum agreement for each note in subvector
    idx_max=idx_max(end);%if two notes have same maximum agreement we chose the second one (cause first one may be an orfan note)
    
    %if maximun agreement is an ofran note we aasigne it to the closest one
    %in the score. (we will assing it to the closest human annotation which
    %has more sense)
    
    if s2pSort2(1,idx_max)==0%if maximum agreement is 0 (orfan note)
        s2pSort2(:,idx(idx_max))=[];
        %             idx(idx_max)=[];
        % %            i=i-1;
        %             idx=find(s2pSort2(2,:)==s2pSort2(2,i));%find all annotations of each note
        %             idx_max=idx(s2pSort2(3,idx)==max(s2pSort2(3,idx)));%find de maximum agreement for each note in subvector
        %             idx_max=idx_max(end);%if two notes have same maximum agreement we chose the second one (cause first one may be an orfan note)
        %s2pSort2(:,idx)=[];%delete all annotations
    else
        idx_idx_max=(find(s2pSort2(3,idx)==max(s2pSort2(3,idx))));%maximum idx form anotated notes (if two notes have same maxumum agreement we select the second one)
        idx(idx_idx_max(end))=[];%remove maximun index agreement form anotations index
        s2pSort2(:,idx)=[];%delete all annotations which are not maximum agreement
    end
    if ~isempty(find(idx==i))
        i=i-1;
    end
    i=i+1;
end
%remove orfan notes if they have maximun agreement
p2s=s2pSort2(1:2,:)';

%% previous approach
%create Hmax

% [Hmax,Idx]=max(H');%get max values and indexs per row
% perfVect=1:size(H,1);%create a vector for perfoemance notes
% p2s=[perfVect',Idx'];%concatenate performance vecto with max index per row. this is note correspondance
% %
% H2=zeros(size(H));%initialize new matrix
% for i=1:size(H,1)
%     H2(i,Idx(i))=Hmax(i);%fill new matrix with max values
% end

%change H axis direction
%H=flipud(H);

%plot matrix
%         figure (1)
%         image(H, 'CDataMapping','scaled');
%         set(gca,'YDir','normal')
%         set(gca,'FontSize',12)
%         figure(gcf);
%         xlabel('Score note number','FontSize',14);
%         ylabel('Performed note number','FontSize',14);
%         hndl=colorbar;
%         ylabel(hndl,'Agreement level','FontSize',14);
%         title(path_file);
%         hold off


% plot (tbk(:,2),tbk(:,1),'k*')

%tbk=load('tbk.mat');
%plot (tbk.tbk2(:,2),tbk.tbk2(:,1),'k*');

nmat1=data.nmat1;
nmat2=data.nmat2;

end

function s2p=create_s2p_FromAll_x_y(all_x,all_y,nmat1,nmat2)

%% it will be done in mainAllignCollect_data
%%put all pair points in ascending order (users may have pick points in one
%%direction or the other).
%[all_x , all_y]=orderPairsAscending(all_x,all_y);

%% initilize trbk
s2p=zeros(size(all_x));


for i=1:(length(s2p))
    
    if all_y(2,i) > all_y(1,i) %swap pair annotation in case the user has annotated in reverse order (this was done somewhere elese!)
        swap = all_y(2,i);
        all_y(2,i) = all_y(1,i);
        all_y(1,i) = swap;
        swap = all_x(2,i);
        all_x(2,i) = all_x(1,i);
        all_x(1,i) = swap;
    end
    
    note1_idx=findNotePosition(all_x(1,i),all_y(1,i),nmat1);%find note 1 position in MIDI matrix 1
    note2_idx=findNotePosition(all_x(2,i),all_y(2,i),nmat2);%find note 2 position in MIDI matrix 2
    s2p(1,i)=note1_idx;%Asign note position to s2p vector
    s2p(2,i)=note2_idx;
end

%% put zeros to orfan performed notes

for i=1:length(nmat2)%go trhough performance notes matrix
    if isempty(find (s2p(2,:)==i))%if a note was not annotated
        s2p=[s2p,[0;i]];%set the correspondance pair to zero
    end
end

end

function timeVecIdx=findNotePosition(onset,note,nmat1);
timeVecIdx=find(nmat1(:,1)<=onset,1,'last');%find onset time interval in nmat (if polifonic could be many positions)
%note_idx=find(nmat1(timeVecIdx,4)==note);%find note pitch in time intervals found in nmat matrix previously
end

% it will be done in mainAllignCollect_data
% function [all_x,all_y]=orderPairsAscending(all_x,all_y)
% for i=1:length(all_x)
%     if all_y(1,i)<all_y(2,i)
%         %swap all_y
%         swap=all_y(1,i);
%         all_y(1,i)=all_y(2,i);
%         all_y(2,i)=swap;
%         %swap all_x
%         swap=all_x(1,i);
%         all_x(1,i)=all_x(2,i);
%         all_x(2,i)=swap;
%     end
% end
% end


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
                    trbkSort(:,j)=[];%clear the couple
                    j=j-1;%If cell was erased j position should be reduced by 1
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
function p2s2=unique_sig(p2s)
%function similar to unique but works with matrices. It deletes the second
%ocurrence in the fist column if repeated. Assumes that the matrix is
%sorted by first colum.
p2s2=p2s;
for i=1:length(p2s2)
    if i>length(p2s2)-1
        break;
    end
    if p2s2(i+1,1)==p2s2(i,1)
        p2s2(i,:)=[];
        i=i-1;
    end
end
end

function pnrll=aligmentPlot(nmat,nmat2,tbk,octShift)
%This function plots a piano roll of two songs one octave appart, and draw
%lines betwen correspondig notes, base on the aligment vector tbk. Input
%variables are:
%nmat: midi matrix of score (midi format based on midi toolbox [ref])
%namt: midi matrix of performance
%tbk: Aligment between notes of score and performance
%octShift: octave shift to plot betwen performance and score

nmat=shift(nmat,'pitch',octShift*12);
nmat2=shift(nmat2,'pitch',-octShift*12);
%subplot(2,1,1)
scrsz = get(0,'ScreenSize');% get screen size
%figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])

pnrll=figure('Position',[1 scrsz(4)/2 scrsz(3) scrsz(4)/2]);%plot piano roll in half of the screen

pianoroll(nmat);
%subplot(2,1,2)
pianoroll(nmat2, 'g', 'hold','num','beat');
hold on;
%find pairs
%         onset(beat)         + half duration in beats (so marking will be at the middle of note box)
all_x=[(nmat2(tbk(:,1),1)'+nmat2(tbk(:,1),2)'/2); ...
    (nmat(tbk(:,2),1)' +nmat(tbk(:,2),2)'/2)];        %first set of ponts (notes) from second matrix (performed)

all_y=[nmat2(tbk(:,1),4)'; ...
    nmat(tbk(:,2),4)'];%second set of ponts (notes) from second matrix (score)


% % % x = [0 1 1 0; ...
% % %      1 1 0 0];
% % % y = [0 0 1 1; ...
% % %      0 1 1 0];
% % % plot(x,y);
% % % This will plot each line in a different color. To plot all of the lines as black, do this:
% % %
plot(all_x,all_y);

%% dysplay note numbers
for i=1:size(nmat2,1)
    text(nmat2(i,1),nmat2(i,4)+1,num2str(i));
end

for i=1:size(nmat,1)
    text(nmat(i,1),nmat(i,4)+1,num2str(i));
end

end
