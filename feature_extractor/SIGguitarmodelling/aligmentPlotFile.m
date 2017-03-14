function aligmentPlotFile
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
songName=path_file_s(max(strfind(path_file_s,'/'))+1:end);%find last / string and read from it.
all_x=nmat.all_x;
all_y=nmat.all_y;
nmat1=nmat.nmat1;
nmat2=nmat.nmat2;

%% Plot data
scrsz = get(0,'ScreenSize');% get screen size
%figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])

pnrll=figure('Position',[1 scrsz(4)/2 scrsz(3) scrsz(4)/2]);%plot piano roll in half of the screen

pianoroll(nmat1);%plot MIDI matrix 1
pianoroll(nmat2, 'g', 'hold','num','beat'); %Plot MIDI matrix 2
hold on;

%subplot(2,1,1)
%pnrll=figure(1);
%pianoroll(nmat);
%subplot(2,1,2)
%pianoroll(nmat2, 'g', 'hold','num','beat');
%hold on;
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