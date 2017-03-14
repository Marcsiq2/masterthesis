function melodyTranscriptionCorrect()


%% Read a folder and get a list of all de midi and xml files

% The final approach would be to generate the nmat matrix from the xml
% file, so we only need xml files.
clear all;
clc;

[fileName, path_file_s]=uigetfile('*.mat','Choose the file to keep on annotatting');
load([path_file_s,fileName],'nmat2');
path_file_s=path_file_s(1:end-1);
songName=path_file_s(max(strfind(path_file_s,'/'))+1:end);%find last / string and read from it.

%%%%%%%%%%%%%%%
%% LOAD DATA %%
%%%%%%%%%%%%%%%

scrsz = get(0,'ScreenSize');
%figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])

pnrll=figure('Position',[1 scrsz(4)/2 scrsz(3) scrsz(4)/2]);
pianoroll(nmat2,'num','beat');
hold on;

%% dysplay note numbers

for i=1:size(nmat2,1)
    text(nmat2(i,1),nmat2(i,4)+1,num2str(i));
end

display('Press c to clear note, p to change pitch, m to merge with next note, z to zoom or move, s to save or q to quit')
%display note correction menu

while 1
    
    w=waitforbuttonpress;
    key = get(pnrll,'CurrentCharacter');
    switch key
        
        case 'q'
            display('Correction terminated')
            break;
            
        case 'c'
            note_idx=getNotePoint(nmat2);
            while isempty(note_idx)
                note_idx=getNotePoint(nmat2);
            end
            nmat2(note_idx,:)=[];
            display('Press c to clear note, p to change pitch, m to merge with next note, z to zoom or move, s to save or q to quit')
            pianoroll(nmat2,'num','beat');
            hold on;
            %% dysplay note numbers
            
            for i=1:size(nmat2,1)
                text(nmat2(i,1),nmat2(i,4)+1,num2str(i));
            end
            
        case 'p'
            note_idx=getNotePoint(nmat2);
            while isempty(note_idx)
                note_idx=getNotePoint(nmat2);
            end
            fprintf('current note pitch is: %d\n', nmat2(note_idx,4));
            pitch=input('type new notw pitch:');
            nmat2(note_idx,4)=pitch;
            pnrll=figure(1);
            hold off;
            pianoroll(nmat2);
            hold on;
            %% dysplay note numbers
            
            for i=1:size(nmat2,1)
                text(nmat2(i,1),nmat2(i,4)+1,num2str(i));
            end
            display('Press c to clear note, p to change pitch, m to merge with next note, z to zoom or move, s to save or q to quit')
            
        case 'm'
            note_idx=getNotePoint(nmat2);
            while isempty(note_idx)
                note_idx=getNotePoint(nmat2);
            end
            nmat2(note_idx,5)=max(nmat2(note_idx,5),nmat2(note_idx+1,5));
            nmat2(note_idx,2)=nmat2(note_idx,2)+nmat2(note_idx+1,2);
            nmat2(note_idx,7)=nmat2(note_idx,7)+nmat2(note_idx+1,7);
            nmat2(note_idx+1,:)=[];
            
            pnrll=figure(1);
            hold off;
            pianoroll(nmat2);
            hold on;
            %% dysplay note numbers
            
            for i=1:size(nmat2,1)
                text(nmat2(i,1),nmat2(i,4)+1,num2str(i));
            end
            display('Press c to clear note, p to change pitch, m to merge with next note, z to zoom or move, s to save or q to quit')
            
        case 'l' %listen
            note_idx=getNotePoint(nmat2);
            while isempty(note_idx)
                note_idx=getNotePoint(nmat2);
            end
            nmat_l=nmat2(note_idx,:);
            playsound(nmat_l);
            display('Press c to clear note, p to change pitch, m to merge with next note, z to zoom or move, s to save or q to quit')
            
        case 's'
            %             if batch==0
            save([path_file_s,'/',fileName],'nmat2');
            %             else
            %             save([path_file_s,fileName],'nmat2');
            %             end
            %
            display('Press c to clear note, p to change pitch, m to merge with next note, z to zoom or move, s to save or q to quit')
            
        case 'z'
            display('Choose zoom tool or move tool to change figure view')
            display('After editing unselect the tool used berfore continuing')
            display('Press c to clear note, p to change pitch, m to merge with next note, z to zoom or move, s to save or q to quit')
            waitfor(pnrll, 'KeyPressFcn');
        otherwise
            display('Choose zoom tool or move tool to change figure view')
    end
end

save([path_file_s,'/',fileName],'nmat2');

close (pnrll);

end

function nmat2_idx=getNotePoint(nmat2)
[x,y]=ginput(1);
nmat2_idx=find((x>=nmat2(:,1)).* (round(y)==nmat2(:,4)),1,'last');
if isempty(nmat2_idx)
    fprintf('Any note was selected, Please try again\n')
    nmat2_idx=[];
    return;
end

end

