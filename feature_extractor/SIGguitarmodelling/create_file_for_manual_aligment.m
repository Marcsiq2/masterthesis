function create_file_for_manual_aligment(batch)

if batch==1
    
    %% Get performance directory path
%    path_file_s=uigetdir('Choose the folder in which Nmat performances are stored');%Get the directory path where the midi and xml files are stored
    path_file_s=[pwd,'/dataOut/performanceNmat/'];
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    idx=16;
else
    
    %% Get socre file path
    [file,path_file_s]=uigetfile('*.mat','Choose a Nmat performance file');%Get the directory path where the midi and xml files are stored
    files.name=file;
    numberOfFiles=1;
    idx=26;%idx +1
end

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name,'.'))&& ~(strcmp(files(i,1).name,'..'))&& ~(strcmp(files(i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files
        if strcmp(files(i,1).name(end-2:end),'mat')  %filter wav files only mat files
            
            %load score nstruct1 to get beats per bar
            load([pwd,'/dataOut/scoreNmat/',files(i,1).name(1:end-3),'mat'],'nmat1');
            %load performance nmat2 (un aligned)
            load([pwd,'/dataOut/performanceNmat_alligned/',files(i,1).name(1:end-3),'mat'],'nmat2');
            
%             %put both files in same key
%             if (round (mean(nmat1(:,4)))~=round (mean(nmat2(:,4))))
%                 transp=mean(nmat2(:,4))-round (mean(nmat1(:,4)));
%                 nmat2= nmat2(:,4)-transp;
%             end
            
            %% Save MIDI matrix, MIDI structure, and Descriptors structure
            fprintf(['Saving in folder dataOut/files_to_annotate ',files(i,1).name(1:end-3),'mat...']);
            save( [pwd,'/dataOut/files_to_annotate/',files(i,1).name(1:end-3),'mat'],'nmat1','nmat2');
            fprintf('Done!\n');                  
        end
    end
end
fprintf('Success!\n');
end