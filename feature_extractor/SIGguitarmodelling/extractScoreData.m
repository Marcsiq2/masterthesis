function extractScoreData(batch)

% switch nargin
%     case 0
%         batch=input('perform batch proccessing?(y=1,n=0):');
%     case 1
%         batch=varargin{1};
%     case 2
%         batch=varargin{1};
%         arg_in=varargin{2};
% end

if batch==1
    %path_file_s=uigetdir('Choose the folder in which scores are stored');%Get the directory path where the midi and xml files are stored
    path_file_s = [pwd,'/dataIn/score/'];
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    
else
    [file,path_file_s]=uigetfile('*.xml','Choose a score file');%Get the directory path where the midi and xml files are stored
    files.name=file;
    numberOfFiles=1;
end


%% For each file:

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name,'.'))&& ~(strcmp(files(i,1).name,'..'))&& ~(strcmp(files(i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files
        
        if strcmp(files(i,1).name(end-2:end),'xml') %filter xml files only
            
            %%%%%%%%%%%%%%%%%%%%%%%%%
            %% PREPROCESS SCORE DATA %%
            %%%%%%%%%%%%%%%%%%%%%%%%%
            fprintf('Extracting score data for %s\n',files(i,1).name);
            fprintf(['   Parsing MusicXml score...']);
            %% Read xml file into nmat and nstruct
            %nstruct1=xmlMusicParse([path_file_s,'/',files(i,1).name]);%parse xml and save it into a structure
            %nmat1=nstruct2nmat(nstruct1);%parse nstruct data to obtain an nmat representation           
            [nmat1, nstruct1, notes_idx] = xmlMusicParse([path_file_s,'/',files(i,1).name]);
            fprintf('Done!\n');
            
            %% Extract note descriptors from midi, and chord information from xml file
            fprintf('   Extracting note descriptors....');
            score_s = extractScoreDescriptors(nmat1,nstruct1,notes_idx);
            fprintf('Done!\n');
            
%             %% Extract chord information from xml file
%             fprintf('Extracting chord descriptors....');
%             score_chords=extractChordDescriptors(nmat1,nstruct1);
%             fprintf('Done!\n');
            %% Save MIDI matrix, MIDI structure, and Descriptors structure
            fprintf('   Saving nmat file...');% in folder ',pwd,'/dataOut/scoreNmat as ',files(i,1).name(1:end-3),'mat...']);
            save( [pwd,'/dataOut/scoreNmat/',files(i,1).name(1:end-3),'mat'], 'nstruct1','nmat1','score_s');
        end
        fprintf('Done!\n');
    end
end
fprintf('Success!\n');
end

