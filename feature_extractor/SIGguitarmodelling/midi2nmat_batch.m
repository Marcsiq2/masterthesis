function midi2nmat_batch(batch)

if batch==1
    
    %% Get performance directory path

    %path_file_s = uigetdir('Choose the folder in which midi are stored');%Get the directory path where the midi and xml files are stored
    path_file_s = [pwd, '/dataIn/performed/midi/'];
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    
else
%    else
        [file,path_file_s]=uigetfile('*.mid','Choose a midi file');%Get the directory path where the midi and xml files are stored
%     end
    %% Get socre file path
    files.name=file;
    numberOfFiles=1;
end


%% For each file:
fprintf('Converting Midi files to mat');
for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name,'.'))&& ~(strcmp(files(i,1).name,'..'))&& ~(strcmp(files(i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files
        
        if strcmp(files(i,1).name(end-2:end),'mid') %filter mid files only
            
            %%%%%%%%%%%%%%%%%%%%%%%%%
            %% PREPROCESS SCORE DATA %%
            %%%%%%%%%%%%%%%%%%%%%%%%%
            
            fprintf(['   Reading midi file: ',files(i,1).name,'...']);
            %% Read midi file into nmat
            nmat2=midi2nmat([path_file_s,'/',files(i,1).name]);%parse midi data to obtain an nmat representation
            fprintf('Done!\n');
            
            %% Save MIDI matrix, MIDI structure, and Descriptors structure
            fprintf('   Saving mat file...');
            save( [pwd,'/dataOut/performanceNmat/',files(i,1).name(1:end-3),'mat'],'nmat2');
            fprintf('Done!\n');
        end
    end
end
fprintf('Success!\n');







end