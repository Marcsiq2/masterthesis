function beatTrackMidiAlign(batch)

if batch==1
    
    %% Get performance directory path
    %path_file_s=uigetdir('Choose the folder in which Nmat performances are stored');%Get the directory path where the midi and xml files are stored
    path_file_s=[pwd, '/dataOut/performanceNmat/'];
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    idx=16;
else
    
    %% Get socre file path
    [file,path_file_s]=uigetfile('*.mat','Choose a Nmat performance file');%Get the directory path where the midi and xml files are stored
    files.name=file;
    numberOfFiles=1;
    idx=17;%idx +1
end

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name,'.'))&& ~(strcmp(files(i,1).name,'..'))&& ~(strcmp(files(i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files
        if strcmp(files(i,1).name(end-2:end),'mat')  %filter wav files only mat files
            
            %load score nstruct1 to get beats per bar
            load([path_file_s(1:end-idx),'/scoreNmat/',files(i,1).name(1:end-3),'mat'],'nmat1','nstruct1');
            beatsPerBar=nstruct1.timeBeats;
            %load performance nmat2 (un aligned)
            load([path_file_s(1:end-idx),'/performanceNmat/',files(i,1).name(1:end-3),'mat'],'nmat2');
            %Read beats extracted from backing track
            beats=textread([path_file_s(1:end-idx),'/beats_txt/',files(i,1).name(1:end-4),'_beats.txt']);
            
            %% Align midi beat information to detected beats
            
            fprintf('Performing beat alingment to nmat1 of file %s.... ', files(i,1).name);
            for j=1:size(nmat2,1)
                %Calculate beat
                if beats(1)>nmat2(1,6) %initial beat shluod be always lower than first onset%
                    beats(1)=nmat2(1,6);
                end
                beat_ini=find(beats<=nmat2(j,6), 1, 'last' );
                beat_end=beat_ini+1;%find next beat
                if beat_end>length(beats) %if end beat is higer than last beat detecte (is the last one)
                    beat_length=beats(beat_end-1)-beats(beat_ini-1);%use previous beat lenght
                else
                    beat_length=beats(beat_end)-beats(beat_ini);%use current beat lenght
                end
                
                beat_frac=(nmat2(j,6)-beats(beat_ini))/beat_length;
                beat_mod=mod(beat_ini-1,beatsPerBar);%find modulus of beat (zero indexed, so beat ini-1)
                if i==11
                    a=0;
                end
                onsetBeat=beat_ini-1+beat_frac;%onset in beats is the sume of the beat modulus plus the beat fraction
                nmat2(j,1)=onsetBeat;%asign onset beat to midi matrix
                %Calculate duration
                durBeat=nmat2(j,7)/beat_length;%duration in seconds over duration of current beat
                nmat2(j,2)=durBeat;%assign duration beat to midi matrix
            end
            %            nmat=nmat1;%write result to output matrix
            fprintf('Done!\n');
            %% Save MIDI matrix, MIDI structure, and Descriptors structure
            fprintf(['Saving in folder dataOut/performanceNmat_alligned as ',files(i,1).name(1:end-3),'mat...']);
            save( [pwd,'/dataOut/performanceNmat_alligned/',files(i,1).name(1:end-3),'mat'],'nmat2');
            fprintf('Done!\n');         
        end
    end
end
fprintf('Success!\n');
end