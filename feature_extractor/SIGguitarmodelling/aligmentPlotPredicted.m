function aligmentPlotPredicted
%This function plots a piano roll of two songs one octave appart, and draw
%lines betwen correspondig notes, base on the aligment vector tbk. Input
%variables are:
%nmat: midi matrix of score (midi format based on midi toolbox [ref])
%namt: midi matrix of performance
%tbk: Aligment between notes of score and performance
%octShift: octave shift to plot betwen performance and score

%% Load data

[fileName, path_file_s]=uigetfile('*.mat','Choose the mat data file to plot');
load([path_file_s,fileName]);
nmat2=nmat_learned;
load([pwd,'/dataOut/scoreNmat/',fileName]);%loads nmat1
load([path_file_s,fileName(1:end-4),'_p2s.mat']);%loads p2s
p2s_mat = cell2mat(p2s');

p2s_fill = fill_mat(p2s_mat,length(nmat2));%fill matrix
p2s_fill(:,[1,2])=p2s_fill(:,[2,1]);%swap columns

%octave shift
nmat2(:,4) = nmat2(:,4)-12;
nmat1(:,4) = nmat1(:,4)+12;


[all_x,all_y]=all_xy_From_s2p(nmat1,nmat2,p2s_fill);

%% Plot data
scrsz = get(0,'ScreenSize');% get screen size
%figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])

pnrll=figure('Position',[1 scrsz(4)/2 scrsz(3) scrsz(4)/2]);%plot piano roll in half of the screen

pianoroll(nmat1);%plot MIDI matrix 1
pianoroll(nmat2, 'g', 'hold','num','beat'); %Plot MIDI matrix 2
hold on;

plot(all_x,all_y);

%% dysplay note numbers
for i=1:size(nmat2,1)
    text(nmat2(i,1),nmat2(i,4)+1,num2str(i));
end

for i=1:size(nmat1,1)
    text(nmat1(i,1),nmat1(i,4)+1,num2str(i));
end

end

function [all_x,all_y]=all_xy_From_s2p(nmat1,nmat2,s2p)

all_x=zeros(2,length(s2p));
all_y=zeros(2,length(s2p));

for i=1:length(s2p)
    all_x(1,i)=nmat1(s2p(i,2),1)+(nmat1(s2p(i,2),2)/2);
    all_x(2,i)=nmat2(s2p(i,1),1)+(nmat2(s2p(i,1),2)/2);
    
    all_y(1,i)=nmat1(s2p(i,2),4);
    all_y(2,i)=nmat2(s2p(i,1),4);

end
end
function p2sOut = fill_mat(p2s,len)
i=1;
p2sOut(i,1)=p2s(i,1);
p2sOut(i,2)=p2s(1,2);

for i=2:length(p2s)-1
    if p2s(i,2)~=p2s(i+1,2)  
        if p2s(i,2)==p2s(i-1,2)+1    
            p2sOut=[p2sOut;p2s(i,:)];
        else
            %fill rows
            step = p2s(i,2)-p2s(i-1,2)-1;
            stepMat=[ones(step,1)*p2s(i-1,1),[p2s(i-1,2)+1:p2s(i,2)-1]'];
            p2sOut=[p2sOut;stepMat];
            %add current row
            p2sOut=[p2sOut;p2s(i,:)];       
        end
    end
end
% LAST FOR CYCLE:
%(this is bad programming i know...), but i need first
% condition of the loop until len(p2s)-1, this is a quick work arrounb
        i=i+1;
        if p2s(i,2)==p2s(i-1,2)+1    
            p2sOut=[p2sOut;p2s(i,:)];
        else
            %fill rows
            step = p2s(i,2)-p2s(i-1,2)-1;
            stepMat=[ones(step,1)*p2s(i-1,1),[p2s(i-1,2)+1:p2s(i,2)-1]'];
            p2sOut=[p2sOut;stepMat];
            %add current row
            p2sOut=[p2sOut;p2s(i,:)];       
        end
% end of for loop

if p2sOut(2,end)<len %fill last note if ornamented
    step = len - p2sOut(end,2);
    stepMat=[ones(step,1)*p2s(i,1),[p2s(i,2)+1:len]'];
    p2sOut=[p2sOut;stepMat]; 
end
    

end