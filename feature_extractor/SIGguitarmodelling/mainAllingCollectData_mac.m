function mainAllingCollectData_mac(path_file_s, fileName)
% This script is to collect anottations from professional muscians. It presents
% the score aligned to the performance and the user manually selects which
% notes correspond with each other.

%% Read a folder and get a list of all de midi and xml files

% The final approach would be to generate the nmat matrix from the xml
% file, so we only need xml files.

if (input(['anotate file ',fileName,' ? (y=1,n=0): ']))
    
    new=input('Choose one of the following:\n1 - Start a new annotattion\n2 - Continue with previous annotattion\n');
    
    %new=1 %If annotated file does not exist (check how to do this!)
    %new=2 %if annotated file exists already
    
    switch new
        case 1
            user=input('Pleasel write your name: \n','s');
            %        [fileName, path_file_s]=uigetfile('*.*','Choose the song to anotate');%Get the file and  directory path where the midi and xml files are stored
            %path_file_p=uigetdir('Choose the folder in which performances were recorded');%Get performance folder
            %        path_file_p=[path_file_s,'/Recordings'];
            songName=fileName(1:end-4);
            nmat=load([path_file_s,'/',songName,'.mat'],'nmat*');
            all_x=[];
            all_y=[];
            nmat1=nmat.nmat1;
            nmat2=nmat.nmat2;
            
            
            nmat1=shift(nmat1,'pitch',12);
            nmat2=shift(nmat2,'pitch',-12);
        case 2
            user=input('User Name: \n','s');
            songName=fileName(1:end-4);
            fileName= [user,'_',songName,'_NoteCorrManual.mat'];
            %         [fileName, path_file_s]=uigetfile('*.mat','Choose the file to keep on annotatting');
            nmat=load([pwd,'/dataOut/annotations/',songName,'/',fileName]);
            %         path_file_s=path_file_s(1:end-1);
            %         path_file_p=[path_file_s,'/Recordings'];
            %
            all_x=nmat.all_x;
            all_y=nmat.all_y;
            nmat1=nmat.nmat1;
            nmat2=nmat.nmat2;
    end
    %%%%%%%%%%%%%%%

    if ~isempty(all_x)
        %%put all pair points in ascending order (users may have pick points in one direction or the other).
        [all_x , all_y]=orderPairsAscending(all_x,all_y);
    end
    
    pnrll=plotAlignment (nmat1,nmat2,all_x,all_y, new);
    
    if ~input('is key correct? (y:1, n:0)')
        correctTransp=0;
        while ~correctTransp
            transp= input('\nInput semitones to transpose:');
            nmat1(:,4)= nmat1(:,4)+transp;
            if new==2
                all_y(1,:)=all_y(1,:)+transp;  
            end
            pnrll=plotAlignment (nmat1,nmat2,all_x,all_y, new);           
            correctTransp=input('\nIs transposition correct? (y:1, n:0=)');
        end
        save([path_file_s,'/',songName,'.mat'],'nmat1','nmat2','all_x','all_y');
    end
    fprintf('\nc: conect notes\nr: erase last \nz: use zoom/move tools \ns: save\nq: to quit')
    
    while 1
        
        w=waitforbuttonpress;
        key = get(pnrll,'CurrentCharacter');
        switch key
            
            case 'q'
                fprintf('Anotattion terminated')
                break;
                
            case 'c'
                [x,y]=correctNotePoint(nmat1, nmat2);
                while isempty(x)||isempty(y)
                    [x,y]=correctNotePoint(nmat1, nmat2);
                end
                all_x=[all_x,x];
                all_y=[all_y,y];
                plot(all_x,all_y);
                fprintf('c: conect notes\nr: erase last \nz: use zoom/move tools \ns: save\nq: to quit\n->')
                
            case 'r'
                all_x(:,end)=[];
                all_y(:,end)=[];
                pnrll=plotAlignment (nmat1,nmat2,all_x,all_y, 2);
                fprintf('c: conect notes\n r: erase last \nz: use zoom/move tools \ns: save\nq: to quit')               

            case 's'
                if new==1
                    mkdir([pwd,'/dataOut/annotations/',songName]);
                    pathAndFileName=[pwd,'/dataOut/annotations/',songName,'/',user,'_',songName,'_NoteCorrManual.mat'];
                else
                    %warn ovewrite data
                    pathAndFileName=[pwd,'/dataOut/annotations/',songName,'/',user,'_',songName,'_NoteCorrManual.mat'];
                end
                saveFileAs(pathAndFileName,all_x,all_y,nmat1,nmat2);
                fprintf('Press c to continue, r to erase, z to zoom or move, s to save or q to quit')
                
            case 'z'
                fprintf('Choose zoom tool or move tool to change figure view')
                fprintf('After editing unselect the tool used berfore continuing')
                fprintf('c: conect notes\n r: erase last \nz: use zoom/move tools \ns: save\nq: to quit')
                %waitfor(pnrll,'CurrentCharacter',1);
                %              pause;
                
                waitfor(pnrll, 'KeyPressFcn');
            otherwise
                fprintf('Choose zoom tool or move tool to change figure view')
        end
    end
    
    if new==1
        mkdir([pwd,'/dataOut/annotations/',songName]);
        pathAndFileName=[pwd,'/dataOut/annotations/',songName,'/',user,'_',songName,'_NoteCorrManual.mat'];
    else
        %warn ovewrite data
        pathAndFileName=[pwd,'/dataOut/annotations/',songName,'/',user,'_',songName,'_NoteCorrManual.mat'];
    end
    
    saveFileAs(pathAndFileName,all_x,all_y,nmat1,nmat2);
    
    close (pnrll);
    
end

end %function end

function [a, b]=correctNotePoint(nmat1,nmat2)
[x,y]=ginput(2);
a=zeros(size(x));
b=zeros(size(y));

if y(1)>y(2)% which cordinate is nmat1 or nmat2 (user may have pick up points in inverse order!)
    nmatIdx=1;
else
    nmatIdx=2;
end

if nmatIdx==1 %nmat1 is on the fist position
    nmat1_idx=find((x(1)>=nmat1(:,1)).* (round(y(1))==nmat1(:,4)),1,'last');
    nmat2_idx=find((x(2)>=nmat2(:,1)).* (round(y(2))==nmat2(:,4)),1,'last');
    if isempty(nmat1_idx) || isempty(nmat2_idx)
        fprintf('One or both notes were not selected, Please try again\n')
        a=[];
        b=[];
        return;
    end
    a(1)=nmat1(nmat1_idx,1)+(nmat1(nmat1_idx,2)/2);
    b(1)=nmat1(nmat1_idx,4);
    
    a(2)=nmat2(nmat2_idx,1)+(nmat2(nmat2_idx,2)/2);
    b(2)=nmat2(nmat2_idx,4);
else
    nmat2_idx=find((x(1)>=nmat2(:,1)).* (round(y(1))==nmat2(:,4)),1,'last');
    nmat1_idx=find((x(2)>=nmat1(:,1)).* (round(y(2))==nmat1(:,4)),1,'last');
    
    if isempty(nmat1_idx) || isempty(nmat2_idx)
        fprintf('Any note was selected, Please try again\n')
        a=[];
        b=[];
        return;
    end
    
    a(1)=nmat2(nmat2_idx,1)+(nmat2(nmat2_idx,2)/2);
    b(1)=nmat2(nmat2_idx,4);
    
    a(2)=nmat1(nmat1_idx,1)+(nmat1(nmat1_idx,2)/2);
    b(2)=nmat1(nmat1_idx,4);
end
end
function saveFileAs(pathAndFileName,all_x,all_y,nmat1,nmat2)

fprintf(['Saving data as: ',pathAndFileName,'\n'])
%%%%%% the conversion from all_x and all_y may not be working correcty!
%trbk will be calculated in a separate function using
%all_x, all_y, nmat1 and namt2 data: s2p=create_s2p_FromAll_x_y(all_x,all_y,nmat1,nmat2)
%                 tbk=zeros(size(all_x));
%                 if all_y(1)>all_y(2)% which cordinate is nmat1 or nmat2 (user may have pick up points in inverse order!)
%                     nmatIdx=1;
%                 else
%                     nmatIdx=2;
%                 end
%
%                 if nmatIdx==2;
%                     for i=1:max(size(all_x))
%                         tbk(1,i)=find((all_x(1,i))>=nmat2(:,1), 1, 'last' );%this works only for monophonic no pitch inofrmation is taken into account
%                         tbk(2,i)=find((all_x(2,i))>=nmat1(:,1), 1, 'last' );%this works only for monophonic no pitch inofrmation is taken into account
% %                    saveFile=[path_file_s,'/',user,'_',songName,'_NoteCorrManual.mat'];
%                     end
%                 else
%                     for i=1:max(size(all_x))
%                         tbk(1,i)=find((all_x(1,i))>=nmat1(:,1), 1, 'last' );%this works only for monophonic no pitch inofrmation is taken into account
%                         tbk(2,i)=find((all_x(2,i))>=nmat2(:,1), 1, 'last' );%this works only for monophonic no pitch inofrmation is taken into account
%   %                  saveFile=[path_file_s,'/',user,'_',songName,'_NoteCorrManual.mat'];
%                     end
%                 end
%                 %%%%%%%%%%%%%%%%%%%%%%%%%
save(pathAndFileName,'nmat1','nmat2','all_x','all_y')
fprintf('done!\n')
end

function pnrll = plotAlignment (nmat1,nmat2,all_x,all_y, new)
    close all;

    scrsz = get(0,'ScreenSize');
    %figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])
    
    pnrll=figure('Position',[1 scrsz(4)/2 scrsz(3) scrsz(4)/2]);
    pianoroll(nmat1);
    
    pianoroll(nmat2, 'g', 'hold','num','beat');
    hold on;
    
    %% dysplay notes
    for i=1:size(nmat2,1)
        text(nmat2(i,1),nmat2(i,4)+1,notename(nmat2(i,4)));
    end
    
    for i=1:size(nmat1,1)
        text(nmat1(i,1),nmat1(i,4)+1,notename(nmat1(i,4)));
    end
    
    if new==2 %dysplay previous recorded data
        plot(all_x,all_y);
    end

end

function [all_x,all_y]=orderPairsAscending(all_x,all_y)
for i=1:length(all_x)
    if all_y(1,i)<all_y(2,i)
        %swap all_y
        swap=all_y(1,i);
        all_y(1,i)=all_y(2,i);
        all_y(2,i)=swap;
        %swap all_x
        swap=all_x(1,i);
        all_x(1,i)=all_x(2,i);
        all_x(2,i)=swap;
    end
end
end