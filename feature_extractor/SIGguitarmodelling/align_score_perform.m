function align_score_perform(batch)

if batch==1
    
    %% Get performance directory path
    path_file_s=[pwd,'/dataOut/files_to_annotate'];
    %path_file_s=uigetdir('Choose the folder in which files to anotate are stored');%Get the directory path where the midi and xml files are stored
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    
else
    
    %% Get score file path
    [file,path_file_s]=uigetfile('*.mat','Choose a Nmat performance file');%Get the directory path where the midi and xml files are stored
    files.name=file;
    numberOfFiles=1;
end

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name(1),'.'))  && (strcmp(files(i,1).name(max(end-3,1):end),'.mat'))%if to by pass . and .. DOS comands listed by dir as files
        %        if strcmp(files(i,1).name(end-2:end),'wav') &&  strcmp(files(i,1).name(end-5:end-4),'bt') %filter wav files only backing tracks
        %% Ask if perform manual or automatic alignment
        
 %       if (input('Perform manual (0) or automatic alignment (1)'))
            %if automatic....
 %       else           
        %if manual....
        %load main_align collect data (update function to work inside this framework -ago2015)
            mainAllingCollectData_mac(path_file_s, files(i,1).name);
 %       end
    
        
    fprintf('Done!\n');    
    end
end

fprintf('Success!\n');

end
