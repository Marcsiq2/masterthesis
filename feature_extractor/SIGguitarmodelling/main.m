%Main code to read data collection. We get the files names from the scores
%directory.  Then we use the name list to get the path to each score, and
%audio - midi performance data in xml, wav and midi respectively. Finally
%we call the functions to parse everything.

%Add path to yin function


%% Print menu to choose to parse all data set or only one file!


%% Get socre directory path
path_file_s=uigetdir('Choose the folder in which scores are stored');%Get the directory path where the midi and xml files are stored
files=dir(path_file_s);%Get files names and attributes in a astructure array
numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files)

%% For each file:
flag1=0;
flag2=0;
for i=1:numberOfFiles, %for each file (do not count . and .. 
  if ~(strcmp(files(i,1).name,'.'))&& ~(strcmp(files(i,1).name,'..'))&& ~(strcmp(files(i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files        

    if strcmp(files(i,1).name(end-2:end),'xml') %filter xml files only
        
%%%%%%%%%%%%%%%%%%%%%%%%%
%% PREPROCESS SCORE DATA %%
%%%%%%%%%%%%%%%%%%%%%%%%%

        fprintf(['Reading socre midi files in to matix and structures: ',files(i,1).name,'...']);
  %% Read xml file into nmat and nstruct
        [nmat1, nstruct1]=xml2nmat([path_file_s,'/',files(i,1).name]);%Read xml file into nmat!!! (by me!)
%          nstruct=xmlMusicParse([path_file,'/',files(i,1).name]);%read data from xml file
        fprintf('Done!\n');

  %% Extract note descriptors from midi, and chord information from xml file
        fprintf(['Extracting descriptors of file: ',files(i,1).name,'...']);
        score_s=midi2ds2(nmat1,nstruct1);
        fprintf('Done!\n');

  % Add file name to note descriptors (needed? just forinformation)
        score_s=addAttribute(score_s, files(i,1).name, 'fileName');  %set constant descriptors (ej. tempo) to each n



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% PREPROCESS PERFORMANCE DATA %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

           %% Read midi performance
           fprintf(['Converting performance wav file in to MIDI matix: ',files(i,1).name,'...']);
           nmat2=midi2nmat([path_file_s(1:end-11),'/extracted_midi/',files(i,1).name(1:end-4),'.mid',]);%Read midi file into nmat!!! (by me!)
           
           %%%%Here wi will use the function to transcribe audio to midi by
           %Helena
            %nmat2 = create_nmat_gt([path_file_s(1:end-5),'performed/',files(i,1).name(1:end-4),'.wav'], nstruct1.tempo);
           
           fprintf('Done!\n');

           %% Read backing track file path
           %wavFile=[path_file_s(1:end-5),'performed/',files(i,1).name(1:end-4),'.wav',];

           %% Align midi and beat track extracted from backing track audio file
           %fprintf(['Performing midi beat aligment based on beat extraction from audio backing track: \n',files(i,1).name,'...']);
           %nmat2=beatTrackMidiAlign(wavFile,nmat2,nstruct1.timeBeats);
           %fprintf('Done!\n');

           %% Align performance 2 score
           %Shift both sequences to same octave
           octaveOffset=round((mean(nmat2(:,4))-mean(nmat1(:,4)))/12)*12;%mean of notes of first sequence minus mean of notes of second sequence
           nmat1(:,4)=nmat1(:,4)+octaveOffset;%shift octave

           %% Create aligment matrix
           fprintf(['Performing aligment betwen performance and score...\n']); 
           
           %aligment using dinamic time wrapping, with distance function based on cost of onsets, pitch duration and legato
           [H2, p2s,fig1,pnroll] = dtwSig(nmat1,nmat2, 0.6   , 0.1   ,        1   ,           0.5   ,        0.6      , 'no'       ,0.3);
           %                                                  pitchW, durW, OnsetW, iniLegatoW,lastLegatoW, inverted, legato_threshold(gap betwen two notes in beats fraction) );
           %Aligment using anotated data
           
           %p2s=anotationsProcess2([path_file_s(1:end-5),'annotations/',files(i,1).name(1:end-4)]);%read all anotated data of one song
    
           
           fprintf(['Printing score vs perform aligment. Check for errors and press any key...\n']);
 %          pause();
           
           %note omisions... If a score note is omited in the performance
           %(or two notes of the score are related to one of the
           %performance, we ommit the second one... Becasuse we can...
           p2s=unique_sig(p2s);
           p2s=unique_sig(p2s); %tree performance notes repeated.... doesnt work...!! 13 may 2014
           
           %plot correspondence
            figure (2)
            plot(p2s(:,2),p2s(:,1),'*');
            set(gca,'YDir','reverse');
            xlabel('score notes');
            ylabel('performed notes (descending)');
            hndl=colorbar;
            ylabel(hndl,'Agreement');
            hold off
            
            octShift=1;
            pnrll=aligmentPlot(nmat1,nmat2,p2s,octShift);
           %% Create database of ornaments
           
           %emb = embellish(nmat1,nmat2,p2s); %returns a structure     
           %emb=addAttribute(emb, files(i,1).name, 'fileName');  %set constant descriptors (ej. tempo) to each not
           
           
            %% is the note embellished?
           
            %score_s=isEmbellished(score_s,emb);
           
           %% Concatenate with previous data of files already parsed SCORE

%         if flag1==0%if first loop
%              score_all=score_s;
%             flag1=1;
%         else
%             score_all=structCat(score_all,score_s);
%         end
%         fprintf('Done!\n');
            %% concatenate data.... PERFORMED
% 
%         if flag2==0%if first loop
%             emb_all=emb;
%             flag2=1;
%         else
%             emb_all=structCat(emb_all,emb);
%         end
%         fprintf('Done!\n');
%         
           %% Save Data
%            saveFile=[path_file_p(1:end-10),'Data/',files(i,1).name(1:end-4),'.mat'];
%             save(saveFile);
%              saveFigure=[path_file_s(1:end-12),'Figures/',files(i,1).name(1:end-4),'.m'];
%              saveas(fig1,saveFigure);
%              savePianoRoll=[path_file_s(1:end-12),'Figures/',files(i,1).name(1:end-4),'PianoRoll.m'];
%              saveas(pnroll,savePianoRoll);
%                      
%              clf(fig1);
%              clf(pnroll);
    end
  end
end
score_all = score_s;
%save data
%save([path_file_s(1:end-12),'dataOut/emb.mat'],'emb_all');
save([path_file_s(1:end-11),'/dataOut/score_descript.mat'],'score_all');

%%open pre calculated data
%     cd(pwd)
%     [filename,pathname]=uigetfile();
%     load([pathname,filename]);

%create arfs
fprintf('Creating arff files...\n');
%score_all_2=struct_cell_parse(score_all);%parse cell fields to cell char
atrib=attributes(score_all,score_all);%create atribute list
arff_write('Files/dataOut/arffs/score.arff',score_all,'train',atrib, 'marc');%write train data set for embellishment 

  
 fprintf('SUCCESS!!!')



