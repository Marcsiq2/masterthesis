function pnrll=aligmentPlot(varargin)
%This function plots a piano roll of two songs one octave appart, and draw
%lines betwen correspondig notes, base on the aligment vector tbk. Input
%variables are:
%nmat: midi matrix of score (midi format based on midi toolbox [ref])
%namt: midi matrix of performance
%tbk: Aligment between notes of score and performance
%octShift: octave shift to plot betwen performance and score

% Arguments: (nmat,nmat2,p2s,octShift, position, [left bottom wide
% height])


nmat = varargin{1};
nmat2 = varargin{2};
p2s = varargin{3};
scrsz = get(0,'ScreenSize');% get screen size
octShift = varargin{4};
if length(varargin) > 4
    screen_pos = varargin{5};
else
    screen_pos = [1 scrsz(4)/2 scrsz(3) scrsz(4)/2];
end



nmat=shift(nmat,'pitch',octShift*12);
nmat2=shift(nmat2,'pitch',-octShift*12);
%subplot(2,1,1)
%scrsz = get(0,'ScreenSize');% get screen size
%figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])

pnrll=figure;%plot piano roll in half of the screen

pianoroll(nmat);
%subplot(2,1,2)
pianoroll(nmat2, 'g', 'hold','num','beat');
hold on;
 %find pairs
%         onset(beat)         + half duration in beats (so marking will be at the middle of note box)
all_x=[(nmat2(p2s(:,1),1)'+nmat2(p2s(:,1),2)'/2); ...
           (nmat(p2s(:,2),1)' +nmat(p2s(:,2),2)'/2)];        %first set of ponts (notes) from second matrix (performed)
       
all_y=[nmat2(p2s(:,1),4)'; ... 
           nmat(p2s(:,2),4)'];%second set of ponts (notes) from second matrix (score)


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