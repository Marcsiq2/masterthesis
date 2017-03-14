function beatTrackCorrect(batch)

addpath('/Applications/MATLAB_R2012b.app/toolbox/MultiBT_Inf');

if batch==1
    
    %% Get performance directory path
    path_file_s = [pwd, '/dataIn/bt/'];
    path_file_beats = [pwd, '/dataOut/beats_txt/']% uigetdir('Choose the folder in which beat information files are stored');%Get the directory path where the midi and xml files are stored
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    
else
    
    %% Get score file path
    [file,path_file_s]=uigetfile('*.wav','Choose a performance wav file');%Get the directory path where the midi and xml files are stored
    path_file_beats=uigetdir('Choose the folder in which beat information files are stored');%Get the directory path where the midi and xml files are stored
    files.name=file;
    numberOfFiles=1;
end

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name,'.'))&& ~(strcmp(files(i,1).name,'..'))&& ~(strcmp(files(i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files
        if strcmp(files(i,1).name(end-2:end),'wav') %&&  strcmp(files(i,1).name(end-5:end-4),'bt') %filter wav files only backing tracks
            %% Do Beat tracking in backing track audio file and apply corrections if necessary
            fprintf(['Performing beat extraction from audio backing track: \n',files(i,1).name,'...\n']);
            beatTracking(path_file_s,files(i,1).name,path_file_beats);
            fprintf('Done!\n');
            
        end
    end
end
end
function beatTracking(pathName, wavFile, path_file_beats)

beatTextFile=[path_file_beats,'/', wavFile(1:end-4), '_beats.txt'];

%readtxtfile=input('Use beat information from txt file?...(y/n):\n','s');
readtxtfile='y';%always yes as data is already calculated

if strcmp(readtxtfile,'n')%perfrorm beat traking only if read option is not marked
    fprintf('Performing beat traking...\n');
    MultiBT_Inf([pathName,wavFile],beatTextFile);
end

beats=textread(beatTextFile);
%beats=beats(1,:)';

%% audio check of beat detection
%add clicks to the audio wave

%read wave
[x,fs]=audioread([pathName,'/', wavFile]);
if min(size(x,1),size(x,2))==2%if stereo
    x=x(:,1)*0.7+x(:,2)*0.7;%convert to mono
end

%%%%Correction interface%%%&

good='n';
%Listen to beats
while strcmp(good,'n')
    listen=input('Do you want to listen to beat detection result?...(y/n):','s');
    %    listen='n';%always no as data is already calculated
    
    if strcmp(listen,'y')
        fprintf(['listening to beats detected for:\n ',wavFile,'\n']);
        y=beat_track_test(x,fs,beats); %arguments: x=sound signal; fs=sample rate; beats=beats detected in seconds
        sound(y,fs);
        if input('overwrite text and wav beat files?.... (y=1; n=0)')
            wavwrite(y,fs,[pwd,'/dataOut/beats_wav/',wavFile]);
            dlmwrite([pwd,'/dataOut/beats_txt/',wavFile(1:end-4),'_beats.txt'],beats);
            fprintf('Done!\n');
        end
        %wavwrite(y,fs,   [wavFile(1:(find(wavFile=='/', 1, 'last' ))-17),'dataOut/beats_wav', wavFile(find(wavFile=='/', 1, 'last' ):end-7)   , '_beats.wav']);
        good=input('Is beat detection correct?...(y/n)','s');
        if ~strcmp(good,'y')
            opt=input('choose one of the following option:\n 1- First beat missing\n 2-Beat detected is half (down beat)\n 3-Beat detected is double\n 4-Beat detected is half (up beat)\n 5-Perform manual annotation\n');
            switch opt
                case 1%first beat missing
                    beats=[0.001;beats]; %(add first beat at zero)
                case 2 %half beat detected
                    beats=sort([beats; diff(beats)/2+beats(1:end-1)]);%This is: Difference betwen beats/2 + previous beat. The concatenate to initial beats values and then sort them
                case 3%double
                    beats(2:2:length(beats))=[];%pair beats (2,4,6...) are equal to empty
                case 4%half upbeat
                    beats=sort([beats; diff(beats(1:end))/2+beats(1:end-1)]);%This is same as before but starting from 2: Difference betwen beats/2 + previous beat. The concatenate to initial beats values and then sort them
                case 5
                     %pending...
                     fprintf('introduce markers in text file: %s\nPress enter when done\n',[pwd,'/dataOut/beats_txt/',wavFile(1:end-4),'_beats.txt']);
                     pause;
                     beats=textread([pwd,'/dataOut/beats_txt/',wavFile(1:end-4),'_beats.txt'],'%f%*[^\n]');
            end
            
        end
        
    else
        good='y';        
    end
    
end
end