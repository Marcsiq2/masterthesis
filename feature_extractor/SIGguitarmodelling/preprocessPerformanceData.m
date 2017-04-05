function preprocessPerformanceData(varargin)

%Add path to yin function
batch=varargin{1};
if nargin==2
    w_sec=varargin{2};
else
    w_sec=0.015;
end
if nargin==3
    thre=varargin{3};
else
    thre=0.3;
end

addpath('/Users/Sergio/Dropbox/PHD/Melody_extraction/experiment1/MATLABLIB/toolbox/yin')

if batch==1
    
    %% Get performance directory path
    path_file_s=uigetdir('Choose the folder in which recordings are stored');%Get the directory path where the midi and xml files are stored
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    idx=12;
else
    
    %% Get socre file path
    [file,path_file_s]=uigetfile('*.wav','Choose a performance wav file');%Get the directory path where the midi and xml files are stored
    files.name=file;
    numberOfFiles=1;
    idx=13;
end


%% For each file:

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name,'.'))&& ~(strcmp(files(i,1).name,'..'))&& ~(strcmp(files(i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files
        
        if strcmp(files(i,1).name(end-2:end),'wav') &&  ~strcmp(files(i,1).name(end-5:end-4),'bt') %filter wav files only and no backing track
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% PREPROCESS PERFORMANCE DATA %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %% Read wav performance
            fprintf(['Converting performance wav file in to MIDI matix: ',files(i,1).name,'...']);
            
            %% Get tempo from score structure
            load([path_file_s(1:end-idx),'Out/scoreNmat/',files(i,1).name(1:end-3),'mat'],'nstruct1');
            
            %% Here we will use the function to transcribe audio to midi by Helena
            nmat2 = create_nmat_gt([path_file_s,'/',files(i,1).name], nstruct1.tempo,w_sec,thre);
            fprintf('Done!\n');
            
            %% Save MIDI matrix, MIDI structure, and Descriptors structure
            fprintf(['Saving in folder dataOut/performanceNmat as ',files(i,1).name(1:end-3),'mat...']);            
            save( [path_file_s(1:end-idx),'Out/performanceNmat/',files(i,1).name(1:end-3),'mat'],'nmat2');
            fprintf('Done!\n');
        end
    end
end
fprintf('Success!\n');
end

