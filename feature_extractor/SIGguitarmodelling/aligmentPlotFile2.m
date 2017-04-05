function aligmentPlotFile2
%This function plots a piano roll of two songs one octave appart, and draw
%lines betwen correspondig notes, base on the aligment vector tbk. Input
%variables are:
%nmat: midi matrix of score (midi format based on midi toolbox [ref])
%namt: midi matrix of performance
%tbk: Aligment between notes of score and performance
%octShift: octave shift to plot betwen performance and score

%% Load data

[fileName, path_file_s]=uigetfile('*.mat','Choose the mat data file to plot');
nmat=load([path_file_s,fileName]);
path_file_s=path_file_s(1:end-1);
%      path_file_p=[path_file_s,'/Recordings'];
%songName=path_file_s(max(strfind(path_file_s,'/'))+1:end);%find last / string and read from it.

nmat1=nmat.nmat1;
nmat2=nmat.nmat2;

[all_x,all_y]=all_xy_From_s2p(nmat1,nmat2,nmat.p2s);



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