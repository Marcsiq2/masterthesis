function SIG_descriptorsExtractorXML(batch)
%This function parses an XLM music file and extracts note information and
%chord information in a ARFF file and MATLAB "mat" file. It is desingned to
%parse a monophonic melody along with it respective chords. XML files must
%i%This function parses an XLM music file and extracts note information and
%chord information in a ARFF file and MATLAB "mat" file. It is desingned to
%parse a monophonic melody along with it respective chords. XML files must
%include key, tempo, and time signature information. The ARFF file produced
%is compatible to be evaluated with the respective expressive model
%available at:
%
%https://github.com/chechojazz/machineLearningAndJazz/tree/master/models
%
%input arguments:
%batch: [1,0]. Set to 1 if you want to bacth process several files in a
%folder. Set to zero if you want to process only one file.
%
%This code make use of some functions of the MIDItoolbox library. Please
%download and install from:
%https://www.jyu.fi/hum/laitokset/musiikki/en/research/coe/materials/miditoolbox
%
%This code was created by Sergio Giraldo, MTG, Pompeu Fabra University, 2016
%(sergio.giraldo@upf.edu). If you make use of this code please refer to the
%following citattions:
%
%Giraldo, S., & Ramírez, R. (2016). A machine learning approach to
%ornamentation modeling and synthesis in jazz guitar. Journal of
%Mathematics and Music, 10(2), 107-126. doi: 10.1080/17459737.2016.1207814,
%URL: http://dx.doi.org/10.1080/17459737.2016.1207814
%
%Sergio Giraldo, 2016, MTG.nclude key, tempo, and time signature information. The ARFF file produced
%is compatible to be evaluated with the respective expressive model
%available at:
%
%https://github.com/chechojazz/machineLearningAndJazz/tree/master/models
%
%input arguments:
%batch: [1,0]. Set to 1 if you want to bacth process several files in a
%folder. Set to zero if you want to process only one file.
%
%This code make use of some functions of the MIDItoolbox library. Please
%download and install from:
%https://www.jyu.fi/hum/laitokset/musiikki/en/research/coe/materials/miditoolbox
%
%This code was created by Sergio Giraldo, MTG, Pompeu Fabra University, 2016
%(sergio.giraldo@upf.edu). If you make use of this code please refer to the
%following citattions:
%
%Giraldo, S., & Ramírez, R. (2016). A machine learning approach to
%ornamentation modeling and synthesis in jazz guitar. Journal of
%Mathematics and Music, 10(2), 107-126. doi: 10.1080/17459737.2016.1207814,
%URL: http://dx.doi.org/10.1080/17459737.2016.1207814
%
%Sergio Giraldo, 2016, MTG.



path_list_cell = path;

if isempty(strfind(path_list_cell, 'MIDItoolbox'))
    error('Please install and add the MIDItoolbox path before runing this code. MIDItoolbox can be dounloaded from https://www.jyu.fi/hum/laitokset/musiikki/en/research/coe/materials/miditoolbox. Use addpath command to add MIDItoolbox path to your matlab enviroment.');
else
    
    if batch==1
        path_file_s=uigetdir('Choose the folder in which XML scores are stored');%Get the directory path where the midi and xml files are stored
        %path_file_s = [pwd,'/dataIn/score/'];
        files=dir(path_file_s);%Get files names and attributes in a astructure array
        numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
        
    else
        [file,path_file_s]=uigetfile('*.xml','Choose a score file');%Get the directory path where the midi and xml files are stored
        files.name=file;
        numberOfFiles=1;
    end
    
    %promt user for which performance action to create a test set
    PA_idx= input('Choose the performance action for prediction:\n 1- Embellishment\n 2- Duration Ratio\n 3- Onset Deviation\n 4- Energy Ratio\n 5- All\n'); %5- Duration deviation (nominal)\n 6- Onset Deviation (nominal)\n 7-Energy Deviation (nominal)\n');
    
    %Do the same for nominal problem....
    
    PA_list = {'emb',...
        'duration_rat',...
        'onset_dev',...
        ...'pitchDev',...
        'energy_rat',...
        ...'duration_dev_nom',...
        ...'onsetDev_nom',...
        ...'energyDev_nom'...
        };
    %% For each file:
    if PA_idx < 5
        main_parse_files(path_file_s,files,numberOfFiles, PA_list{PA_idx});
    else
        for j=1:4
            main_parse_files(path_file_s,files,numberOfFiles, PA_list{j});
        end
    end
    
end
end

function main_parse_files(path_file_s,files,numberOfFiles, PA, PA_idx)
    
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
            save( [path_file_s, '/', files(i,1).name(1:end-4),'_',PA,'.mat'], 'nstruct1','nmat1','score_s');
            fprintf('Done!\n');
            
            %% Create ARFF file
            attribute_irrel = {'ch','vel','chord','measure','chord2key'};% chord to key should be included in the future!
            score_s=rmfield(score_s,attribute_irrel);%remove indexed attributes            
            attribute2remove = prepareData(PA);
            score_test=rmfield(score_s,attribute2remove);%remove indexed attributes
            score_test=addAttribute(score_test, '?', PA);
            
            attrib=attributes(score_test,score_test);
            fprintf('   Saving arff file...');% in folder ',pwd,'/dataOut/scoreNmat as ',files(i,1).name(1:end-3),'mat...']);
            arff_write([path_file_s,'/', files(i,1).name(1:end-4),'_',PA,'.arff'],score_test, 1, attrib, PA);
            fprintf('Done!\n');
        end
        
    end
end
fprintf('Success!\n');

end


function [nmat, nstruct, notes_idx]=xmlMusicParse(file)

%This function parses an XLM music file and extracts note information and
%chord information in a structure. It is desingned for music scores with
%only one monophonic melodic line with chords, in the way as standar jazz
%lead sheets are usually found.
%
%Input arguments
%file: A music xml file
%
%output arguments
%nstruct: A structure that contains note information and chord information
%
%Sergio Giraldo, 2013 MTG.

xDoc = xmlread(file);%read xml file into a DOM structure
allMeasures = xDoc.getElementsByTagName('measure');%Get all measures node elements
allNotes= xDoc.getElementsByTagName('note');%Get all note node elements

nstruct=struct;%Initialize structure (similar to nmat but as a structure)


i=1;%initialize note counter
l=1;%initialize chord counter

%Go over each measure
for k = 0:allMeasures.getLength-1
    
    thisMeasure = allMeasures.item(k);%get each measure node
    
    %% Get score information (tempo, key, time signature placed at first measure)
    if k==0 %if we are at the first measure
        measureAttributes=thisMeasure.getElementsByTagName('attributes').item(0);%get measure attributes
        %key
        attributeKey=measureAttributes.getElementsByTagName('key').item(0);%get attribute node
        timeBeats=attributeKey.getElementsByTagName('fifths');%get fiths node (this is the key in the cycle of fifiths with rescpect to C
        nstruct.keyFifths=str2num(char(timeBeats.item(0).getFirstChild.getData));%get data from node
        keyMode=attributeKey.getElementsByTagName('mode');%get mode node (major or minor)
        nstruct.keyMode=char(keyMode.item(0).getFirstChild.getData);%get data from node
        %Time Signature
        attributeTime=measureAttributes.getElementsByTagName('time').item(0);%get attribute node
        timeBeats=attributeTime.getElementsByTagName('beats');%get time beat node (time signature numerator)
        nstruct.timeBeats=str2num(char(timeBeats.item(0).getFirstChild.getData));%get data from node
        timeBeat_type=attributeTime.getElementsByTagName('beat-type');%get time beat type node (time siignature denominator)
        nstruct.beat_type=str2num(char(timeBeat_type.item(0).getFirstChild.getData));%get data from node
        %Time divisions: xml divides each beat in a integer based on the
        %divisions of the score
        attributeDivisions=measureAttributes.getElementsByTagName('divisions').item(0);%get attribute node
        nstruct.divisions=str2num(char(attributeDivisions.getFirstChild.getData));%get data from node
    end
    
    %tempo (it could be at any measure if there are tempo changes)
    measureDirection=thisMeasure.getElementsByTagName('direction');%get measure attributes
    if measureDirection.getLength~=0
        %         directionTempo=measureDirection.item(0).getElementsByTagName('sound');
        for n=0:measureDirection.getLength-1%more than 1 direction node can appear
            directionTempo=measureDirection.item(n).getElementsByTagName('sound');
            if directionTempo.getLength~=0 %if direction node contains tempo information
                nstruct.tempo=str2num(char(directionTempo.item(0).getAttribute('tempo')));
                nstruct.tempoBar=k+1;
            end
        end
    end
    
    %% Parse notes in each measure
    
    measureNotes=thisMeasure.getElementsByTagName('note');%get all note nodes for current measure
    
    
    % if ~(strcmp(char(measureNotes.item(0)),'[note: null]')) %if first note points to null the mesasure is empty
    
    
    for j=0:measureNotes.getLength-1%for each note...
        
        nstruct.measure_n(i)=k+1;%write the current measure numer (indexed fom 1)
        
        thisNote=measureNotes.item(j);%get current note node
        
        %Get current note name
        notePitchStep=thisNote.getElementsByTagName('step');
        if notePitchStep.getLength==0
            noteRest=thisNote.getElementsByTagName('rest');
            if noteRest.getLength~=0
                noteRestDur=thisNote.getElementsByTagName('duration');
                nstruct.duration(i)=str2num(char(noteRestDur.item(0).getFirstChild.getData));
                nstruct.pitchStep(i)='r';
                nstruct.pitchAlter(i)=0;
                nstruct.pitchOctave(i)=0;
                
                noteRestType=thisNote.getElementsByTagName('type');
                if noteRestType.getLength~=0
                    nstruct.type{i}=char(noteRestType.item(0).getFirstChild.getData);
                else
                    nstruct.type{i}='barRest';
                end
                
                nstruct.dot(i)=0;
                nstruct.slurType{i,1}=[];
            end
            i=i+1;
            continue
        end
        nstruct.pitchStep(i)= char(notePitchStep.item(0).getFirstChild.getData);
        
        %Get current note alteration (1=sharp, -1=flat, 0=no alter.
        notePitchAlter=thisNote.getElementsByTagName('alter');
        if (~isempty(notePitchAlter.item(0)))
            nstruct.pitchAlter(i)=str2num(char(notePitchAlter.item(0).getFirstChild.getData));
        else
            nstruct.pitchAlter(i)=0;
        end
        
        
        %Get note octave (from 0 to 8)
        notePitchOctave=thisNote.getElementsByTagName('octave');
        nstruct.pitchOctave(i)=str2num(char(notePitchOctave.item(0).getFirstChild.getData));
        
        %Get note duration (based on beat division)
        noteDuration=thisNote.getElementsByTagName('duration');
        nstruct.duration(i)=str2num(char(noteDuration.item(0).getFirstChild.getData));
        
        %Get note type (whole, half, quarter, etc)
        noteType=thisNote.getElementsByTagName('type');
        nstruct.type{i}=char(noteType.item(0).getFirstChild.getData);
        
        %if note is dotted dot=1 else dot=0 (Relevant? we already have the duration of the note!!!)
        noteDot=thisNote.getElementsByTagName('dot');
        if(~isempty(noteDot.item(0)))
            nstruct.dot(i)=1;
        else
            nstruct.dot(i)=0;
        end
        
        %slurs...tie's
        noteSlur=thisNote.getElementsByTagName('slur');
        if(~isempty(noteSlur.item(0)))
            nstruct.slurType{i,1}=char(noteSlur.item(0).getAttribute('type'));
        else
            noteSlur=thisNote.getElementsByTagName('tie');
            if(~isempty(noteSlur.item(0)))
                for m=0:noteSlur.getLength-1
                    nstruct.slurType{i,m+1}=char(noteSlur.item(m).getAttribute('type'));
                end
            else
                nstruct.slurType{i,1}=[];
            end
        end
        
        i=i+1; %advance counter (for each note)
        
    end
    
    %% Parse chords in each measure
    
    measureChords = thisMeasure.getElementsByTagName('harmony');%Get all chord nodes of current measure
    
    for j=0:measureChords.getLength-1 %For each chord node
        
        nstruct.measure_c(l)=k+1;% Write the current measure
        
        thisChord=measureChords.item(j);%Get current chord node
        
        %Get the chord root note
        chordRoot = thisChord.getElementsByTagName('root-step');
        nstruct.root(l)=char(chordRoot.item(0).getFirstChild.getData);
        chordRootAlter=thisChord.getElementsByTagName('root-alter');
        if ~isempty(chordRootAlter.item(0))
            nstruct.rootAlter{l}=str2num(char(chordRootAlter.item(0).getFirstChild.getData));
        else
            nstruct.rootAlter{l}=0;
        end
        
        %Get the chord kind (maj7, min7, etc...)
        chordKind=thisChord.getElementsByTagName('kind');
        nstruct.kind{l}=char(chordKind.item(0).getFirstChild.getData);
        nstruct.kindAbreviate{l}=char(chordKind.item(0).getAttribute('text'));
        
        l=l+1;
    end
end
[nmat, notes_idx]=nstruct2nmat(nstruct);%parse nstruct data to obtain an nmat representation
end

function [nmat,notes_idx]=nstruct2nmat(nstruct)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% onset    dur       chan       pitch      vol     onset      dur   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

onset_sec=0;
onsetBeat=0;%initialize onset beat
lineCount=1;%line of nmat couter
i=1;
notes_idx=[];

while i<=length(nstruct.pitchStep)
    %% Get onset in beats
    nmatLine=[];%initialize new line
    durationBeat=nstruct.duration(i)/nstruct.divisions;%duration of note over division of beat as encoded in xml
    if ~strcmp(nstruct.pitchStep(i),'r')% if not a rest
        if isempty(nstruct.slurType{i,1}) %if no slurs and ties
            nmatLine= [nmatLine, onsetBeat, durationBeat];%Assing onset and duration to nmatLine
        else
            while 1 %We are on a slured note, so... repeat until...
                i=i+1;%Advance to next note
                durationBeat=durationBeat+nstruct.duration(i)/nstruct.divisions;%sume  durations of current and previous notes
                if size (nstruct.slurType,2)==1%if only simple slurs, slur size matrix is one colum, so we have to add an empty column (easiest way...may not the best one!)
                    nstruct.slurType=[nstruct.slurType,repmat({[]},length(nstruct.slurType),1)];
                end
                if strcmp(nstruct.slurType{i,1},'stop')&&isempty(nstruct.slurType{i,2})% if the note is the last of a group of slured notes...
                    break% break
                end
                %                 if i+1>length(nstruct.pitchStep) %if is the last note
                %                     break %get out the loop and continue (other wisewhile condition will drop an error)
                %                 end
            end
            nmatLine= [nmatLine, onsetBeat, durationBeat];%Assing onset and duration to nmatLine (After sumattion of slur, tied notes)
        end
        
        
        
        %% midi chanel (always 1 as it is monophonic)
        nmatLine=[nmatLine,1];
        
        %% Get midi pitch (midi note 12=C0)
        if ~strcmp(nstruct.pitchStep(i),'r')
            switch nstruct.pitchStep(i)
                case 'C'
                    midiNote=12;
                case 'D'
                    midiNote=14;
                case 'E'
                    midiNote=16;
                case 'F'
                    midiNote=17;
                case 'G'
                    midiNote=19;
                case 'A'
                    midiNote=21;
                case 'B'
                    midiNote=23;
            end
            %correct octave and alterations (plus alteration!)
            midiNote=midiNote+(12*nstruct.pitchOctave(i))+nstruct.pitchAlter(i);%Plus alteration (0, 1=#, -1=b)
            nmatLine=[nmatLine,midiNote];
            
            
            
            %% Velocity (Always 80. We assume no volume indications on the score!)
            nmatLine=[nmatLine,80];
            
            %% Calculate in seconds Onset sec, Duration sec.
            
            onsetSec=onsetBeat*60/nstruct.tempo;
            durationSec=durationBeat*60/nstruct.tempo;
            
            nmatLine=[nmatLine,onsetSec,durationSec];%Add to nmat Line
            
            %% Add nmat lines
            if lineCount==1
                nmat=nmatLine;
                lineCount=2;
            else
                nmat=[nmat;nmatLine];
            end
            notes_idx=[notes_idx,i];
        end
    end
    onsetBeat=onsetBeat+durationBeat;%advance onset to end of the current note
    i=i+1;%move to next note
end
end

function score_s = extractScoreDescriptors(nmat,nstruct, notes_idx)

%score_q is a nmat converted midi file

%% Create a score structure
score_s= struct;

%% Create labels to structure according to midi data
score_s.onset_b = roundn(nmat(:,1),-6);%roundn is used to force six decimals accuracy this was inducing an error in beat chord note indexing as bar 12 was equal to 13.9999999999 so floor function droped a wrong value. 12dic2014
score_s.duration_b = roundn(nmat(:,2),-6);
score_s.ch = nmat(:,3);
score_s.pitch = nmat(:,4);
score_s.vel = nmat(:,5);
score_s.onset_s= nmat(:,6);
score_s.dur_s = nmat(:,7);

%% Measure at which bar the note occurs
score_s.measure=floor((nmat(:,1)./4))+1;

%% Create "previous duration" column
score_s.pre_dur_b = circshift(score_s.duration_b,1);
score_s.pre_dur_b(1) = 0; %initial value is zero as it is the first note
score_s.pre_dur_s=score_s.pre_dur_b*60/nstruct.tempo;

%% Create "Next duration" column
score_s.nxt_dur_b = circshift(score_s.duration_b,-1);
score_s.nxt_dur_b(length (score_s.nxt_dur_b)) = 0;%last value is zero as it is the last note
score_s.nxt_dur_s=score_s.nxt_dur_b*60/nstruct.tempo;


%% Onset beat mod (beat onset at current measure)
score_s.onset_b_mod=rem((score_s.onset_b),4);%check out if summing 1 or not

%% We decided not to sume zero to the beat, so defeinition remains:
% beat 1=0
% beat 2=1
% beat 3=2
% beat 4=3

%% Note pitch mod
score_s.pitch_mod=rem(score_s.pitch,12);
%C=0
%C#=1...etc
%B=11

%% Previous and next interval
score_s.prev_int = -(score_s.pitch - circshift(score_s.pitch,1));
score_s.next_int = -(score_s.pitch - circshift(score_s.pitch,-1));

%% Find key (numeric representation) using info from bb file
%      if (strcmp(info{1,2}{4}(2),'b'))%If the root is flattern
%          key=strfind(notes,info{1,2}{4}(1))-1;%search for the key note in notes vector minus 1 semitone
%      else if (strcmp(info{1,2}{4}(2),'#'));%if the root is sharp
%          key=strfind(notes,info{1,2}{4}(1))+1; %search for the key note in notes vector plus one semitone
%      else
%          key=strfind(notes,info{1,2}{4}(1));%search for the key in vector
%          end
%      end
%      key=key-1;%to set note C as zero index

%Key is indexed by cicle of fifts from xml format so we have to get it indexed in
%linear representation (ej. CDEFG... etc)
%create notes vector

score_s=addAttribute(score_s, nstruct.keyFifths, 'keyFifhts');%Set key in the cycle of fifths
score_s=addAttribute(score_s, nstruct.keyMode, 'keyMode');%set mode major or minor

%% Melodic analysis respect to key

%notes='CsDsEFsGsAsB';%%'s' character is used to handle enarmonics
fifthsCircle=[12 7 2 9 4 11 6 1 8 3 10 5 12 7 2]; %indexes to vetor notes
key=fifthsCircle(nstruct.keyFifths + 8) - 1;%key indexed in vector notes minos one so C is zero index
% the following line is incorrect, bug fixed Jan 31 2016
% score_s.note2key = abs(score_s.pitch_mod - key);%key context
score_s.note2key = mod(score_s.pitch_mod - key, 12);% (note_chroma - key_linear)%12

%% Read chords from band in a box file (function)
%ene/2014. This part will be read from the xml file. We need a function to
%read chords and return a matrix of bar x number of beats in a bar. We are
%assuming maximum one chord per beat.

chords=chordBeatMat(nstruct);% debbuged chord id not detecting #'s and b's and not in zero indexing dic9 2014

%order chords in a column by beat
chord_beat_col=chords.mat';
chord_beat_col=chord_beat_col(1:end)';

%same for chords indexes: no chord indexes needed!!!
chord_id_beat_col=chords.id';
chord_id_beat_col=chord_id_beat_col(1:end)';

%index the note chord by note beat...
score_s.chord=chord_beat_col(floor(score_s.onset_b)+1);%chord to each note(plus one as beats are zero indexed)
%score_s.chord=[score_s.chord{:}]';
score_s.chord_id=chord_id_beat_col(floor(score_s.onset_b)+1)+1;%chord idx to each note
%chord_id is choor root chroma in numerical representaton

% 1 r 2 r 3 4 r 5 r 6 r  7
% 0 1 2 3 4 5 6 7 8 9 10 11
score_s.chord2key = mod(score_s.chord_id - key, 12); %chord root interval to key (chord analysis)


%% create chord type descriptor (this means chord root!)
score_s.chord_type=cell(size(nmat,1),1);
for i=1:size(nmat,1)
    currentChord=char(score_s.chord{i});
    switch length(currentChord)
        case 0
            score_s.chord_type{i}='nc';%no chord
        case 1 %case of natural major chords only
            score_s.chord_type{i}='major';%mayor
        otherwise
            if strcmp(currentChord(2),'#')||strcmp(currentChord(2),'b')%if cord is flat or sharp
                if length(currentChord)==2
                    score_s.chord_type{i}='major';%mayor
                else
                    score_s.chord_type{i}=currentChord(3:end);%read type from the third index
                end
            else
                score_s.chord_type{i}=currentChord(2:end);%read type from the second index
            end
    end
end

%% Melodic analisys respect to chord:
%this is the interval from each note to its corresponding chord root.
%formula fixed Jan 2016: use mod base 12 instead of abs.
score_s.note2chord = mod(score_s.pitch_mod - score_s.chord_id, 12);

%% Is a chord note?
%A chord type database was buildt with intervals describing note coposition.

%Function to get chord extensions description
%CHECK OUT MAYOR CHORDS AS THEY HAVE NO TEXT TO REFER TO THE TYPE!!!
[ext_id, ext_c]=chordExtensions('/Users/chechojazz/Dropbox/PHD/Libraries/SIGGuitarModelling/data_sets/chords_extensions.txt');

%classify "Is a chord note y/n" by looking if the note2chord is in the chord description
score_s.isChordN=cell(size(nmat,1),1);%initialize cell array
for i=1:size(nmat,1),
    if strcmp(score_s.chord_type{i},'aug')
        score_s.chord_type{i}='+';
    end
    if  strcmp(score_s.chord_type{i},'7+')%enramonic chord notation of + and 7#5
        score_s.chord_type{i}='7#5';
    end
    %     if strcmp(score_s.chord_type{i},'dim')%enramonic chord notation of + and 7#5
    %         score_s.chord_type{i}='dim7';
    %     end
    %
    chtid=find(strcmp(ext_id{1},score_s.chord_type{i}));%get the chord type index of the current note
    if numel(chtid)==0
        score_s.isChordN{i}='n';%if there is no chord note is labeled as not belonging to chord note... (think)
    else if ~isempty(find(cell2mat(ext_c{chtid}(2:end))==score_s.note2chord(i), 1))%if the note2chord is in the chord type description
            score_s.isChordN{i}='y';
        else
            score_s.isChordN{i}='n';
        end
    end
end

%mtr: this is the strength of the note in terms of the place in the bar:
% 1st beat: Very strong (ss)
% 2nd beat: Weak (w)
% 3rd beat: Strong (s)
% 4th beat: Weak (w)
%
% Up beats are calculated as beat fractions and their strength is set to very weak (ww) as follows:
%
% 16th notes up beats:
% 1_1/2, 2_1/2, 3_1/2 and 4_1/2 beats: Very weak (ww)
%
% 8th note triplets up beats:
% 1_1/3, 1_2/3,2_1/3,2_2/3,3_1/3,3_2/3,4_1/3,4_2/3 beats: Very weak (ww)

score_s.mtr=cell(size(nmat,1),1);%initialize cell array

for i=1:size(nmat,1)
    switch score_s.onset_b_mod(i)
        case 0 %note at first beat
            score_s.mtr{i}='ss';%very strong
        case 1 %note at second beat
            score_s.mtr{i}='w';%weak
        case 2 %note at third beat
            score_s.mtr{i}='s';%strong
        case 3 %note at fourth beat
            score_s.mtr{i}='w';%weak
        otherwise %intermediate values: half notes, triplets, etc
            score_s.mtr{i}='ww';%very weak
    end
end
%% melodic expectation descriptors

%Narmour (MIDI toolbox)
score_s.nar_rd=narmour(nmat,'rd');%registral direction (revised, Schellenberg 1997)
score_s.nar_rr=narmour(nmat,'rd');%registral return (revised, Schellenberg 1997)
score_s.nar_id=narmour(nmat,'id');%intervallic difference
score_s.nar_cl=narmour(nmat,'cl');%closure
score_s.nar_pr=narmour(nmat,'pr');%proximity (revised, Schellenberg 1997)
score_s.nar_co=narmour(nmat,'cl');%consonance (Krumhansl, 1995)

%tonal estability (Krumhansl and Kessler 1982)
nmat_in_c = shift (nmat, 'pitch', -key);
score_s.ton_stab = tonality(nmat_in_c);

%melodic Attraction (Lerdahl 1996)
score_s.mel_atract = melattraction (nmat_in_c);

%tessitura and Mobility (Hippel 2000)

score_s.tessitura = tessitura (nmat);
score_s.mobility = mobility (nmat);


% narmour (mine)
score_s.nar=narmour_sig(nmat);

%% melodic complexity

%tone transitions probabilities (Simonton 1984)
score_s.complex_trans = ones(length(nmat),1)*compltrans(nmat);

%expentancy based model (Ereola 2001)
score_s.complex_expect = ones(length(nmat),1)*complebm(nmat,'o');

%% Get tempo
score_s=addAttribute(score_s, nstruct.tempo, 'tempo');

%% Phrase descriptor:
%Is a descriptor based on the phrasse position. First we segement the
%melody using campolopous algorithm. Notes are then labeled as follows.
%i=beguining of phrase
%m=note in the middle of a phrase
%f=end of a phrase
%our theory is that a note is more probable to be embellished if is at the
%beguining or at the end of a phrase.

phrase=[];%initialize phrase
b=boundary(nmat);%find phrases boundarys
for i=1:length(b)-1%for each note (excep the last one which will be always end of phrase)
    if (b(i)>mean(b)*2)
        phrase{i}=['i'];%lable notes that are beguining of a phrase
    else if (b(i+1)>mean(b)*2)%if the next note is the beguining of a phrase, label prevous note as phrase end
            phrase{i}=['f'];%lable notes that are beguining of a phrase
        else
            phrase{i}=['m'];%lable notes as "in the middle of a phrase"
        end
    end
end

phrase{length(b)}=['f'];%lable last note as end of  phrase"
score_s.phrase=phrase';%assign resulting vector to score structure

score_s = createNominalDescritp(score_s,nmat,nstruct, notes_idx);

end

function [chords,info]=chordBeatMat(nstruct)

j=1; %chord root index

%create notes vector
notes='CsDsEFsGsAsB';%%'s' character is used to handle enarmonics

chords=struct;
chordName={};
%% Build chords
for i=1:length(nstruct.rootAlter)
    switch nstruct.rootAlter{i}
        case 0
            chordName{i}= [char(nstruct.root(i)),char(nstruct.kindAbreviate(i))];
        case 1
            chordName{i}= [char(nstruct.root(i)),'#',char(nstruct.kindAbreviate(i))];
        case -1
            chordName{i}= [char(nstruct.root(i)),'b',char(nstruct.kindAbreviate(i))];
    end
end

%% Create matrix of chords (bar x beats).

for i=1:max(nstruct.measure_n)%for 1 to number of bars
    %    blank_id=find(isspace(chords.names{1,1}{i}));
    chordsXbar=length(find(nstruct.measure_c==i));%Calculate how many chords are at current bar
    
    if chordsXbar==0 && i~=1,
        for k=1:nstruct.timeBeats
            chords.mat{i,k}=chordName{j-1};
        end
    else if chordsXbar==0,
            continue
        else if chordsXbar==1,%if only one chord
                for k=1:nstruct.timeBeats
                    chords.mat{i,k}=chordName{j};
                end
                j=j+1;
            else if chordsXbar==2,%if 2 chords at bar
                    for k=1:nstruct.timeBeats
                        if k==3,j=j+1;end
                        chords.mat{i,k}=chordName{j};
                    end
                    j=j+1;
                else if chordsXbar==3,%if three chords (only 3/4 time signature case)
                        if nstruct.timeBeats==4
                            chords.mat{i,1}=chordName{j};
                            chords.mat{i,2}=chordName{j};
                            chords.mat{i,3}=chordName{j+1};
                            chords.mat{i,4}=chordName{j+2};
                        end
                        if nstruct.timeBeats==3
                            chords.mat{i,1}=chordName{j};
                            chords.mat{i,2}=chordName{j+1};
                            chords.mat{i,3}=chordName{j+2};
                        end
                        j=j+3;
                    else if chordsXbar==4,%if four chords
                            chords.mat{i,1}=chordName{j};
                            chords.mat{i,2}=chordName{j+1};
                            chords.mat{i,3}=chordName{j+2};
                            chords.mat{i,4}=chordName{j+3};
                            j=j+4;
                        else %if more chords
                            fprintf('%s\n','Error: max 1 chords per beat is allowed!');
                            break;
                        end
                    end
                end
            end
        end
    end
end
%eliminate inversions!!! (chech if how xml format handles inversions)
%      for i=1: size(chords.mat,1),
%         for j=1: size(chords.mat,2),
%             if strfind(chords.mat{i,j},'/')>0
%                 id=strfind(chords.mat{i,j},'/');%index where the "/" appears
%                 chords.mat{i,j}=chords.mat{i,j}(1:id-1);%assign base chord info only (symbol before the "/" idx)
%             end
%         end
%      end
%%get the chord root index
%chords.id=zeros(size(chords.mat,1),size(chords.mat,2))
for i=1: size(chords.mat,1),
    for j=1: size(chords.mat,2),
        currentChord=char(chords.mat{i,j});
        if isempty(chords.mat{i,j})
            chords.id(i,j)=NaN;
            chords.mat{i,j}='nc';
        else if numel(currentChord)==1%if chord is only one letter (major chord such as C)
                chords.id(i,j)=strfind(notes,currentChord(1))-1;%search for the root in vector (minuns 1 for zero indexing)
            else if (strcmp(currentChord(2),'b'))%If the root is flattern
                    chords.id(i,j)=strfind(notes,currentChord(1))-2;%search for the root in vector minus 1 semitone
                else if (strcmp(currentChord(2),'#'));%if the root is sharp
                        chords.id(i,j)=strfind(notes,currentChord(1)); %search for the root in vector plus one semitone
                    else
                        chords.id(i,j)=strfind(notes,currentChord(1))-1;%search for the root in vector (minuns 1 for zero indexing)
                    end
                end
            end
        end
    end
end
chords.id=chords.id-1;%substract 1 to get zero indexing
end

function [ext_id, ext_c]=chordExtensions(chord_ext_file)
%This function reads a chord type database was buildt with intervals describing note coposition.

%get chord extensions description

fid2 = fopen(chord_ext_file);
%fid2 = fopen('data_sets/chords_extensions.txt');

ext=struct;
ext.a1 = textscan(fid2,'%s %f %f %f',1);%major
ext.b1 = textscan(fid2,'%s %f %f %f',1);%minor
ext.b2 = textscan(fid2,'%s %f %f %f',1);%2
ext.b3 = textscan(fid2,'%s %f %f %f',1);%sus
ext.b4 = textscan(fid2,'%s %f %f %f',1);%dim
ext.b5 = textscan(fid2,'%s %f %f %f',1);%aug (+)
ext.c1 = textscan(fid2,'%s %f %f %f %f',1);%Maj7
ext.c2 = textscan(fid2,'%s %f %f %f %f',1);%6
ext.c3 = textscan(fid2,'%s %f %f %f %f',1);%m7
ext.c4 = textscan(fid2,'%s %f %f %f %f',1);%m6
ext.c5 = textscan(fid2,'%s %f %f %f %f',1);%mMaj7
ext.c6 = textscan(fid2,'%s %f %f %f %f',1);%m7b5
ext.c7 = textscan(fid2,'%s %f %f %f %f',1);%dim7
ext.c8 = textscan(fid2,'%s %f %f %f %f',1);%7
ext.c9 = textscan(fid2,'%s %f %f %f %f',1);%7#5 (+7?)
ext.c10 = textscan(fid2,'%s %f %f %f %f',1);%7b5
ext.c11 = textscan(fid2,'%s %f %f %f %f',1);%7sus
ext.d1 = textscan(fid2,'%s %f %f %f %f %f',1);%Maj9
ext.d2 = textscan(fid2,'%s %f %f %f %f %f',1);%69
ext.d3 = textscan(fid2,'%s %f %f %f %f %f',1);%m9
ext.d4 = textscan(fid2,'%s %f %f %f %f %f',1);%9
ext.d5 = textscan(fid2,'%s %f %f %f %f %f',1);%7b9
ext.d6 = textscan(fid2,'%s %f %f %f %f %f',1);%7#9
ext.d7 = textscan(fid2,'%s %f %f %f %f %f',1);%7#11 0 4 6 7 10
ext.e1 = textscan(fid2,'%s %f %f %f %f %f %f',1);%13
ext.e2 = textscan(fid2,'%s %f %f %f %f %f %f',1);%7b9b13
ext.e3 = textscan(fid2,'%s %f %f %f %f %f %f',1);%7alt
frewind(fid2);%restart the file scaning from the beguining
ext_id = textscan(fid2,'%s %*[^\n]');%get chord types in a separate variable
fclose(fid2);
ext_c= struct2cell(ext);%convert everything in to a cell
end

function score_s_nom = createNominalDescritp(score_s,nmat,nstruct,note_idx)

score_s_nom = score_s;
score_s_nom.durType = nstruct.type(note_idx)';

for i=1:length(score_s.pitch)
    if score_s.dur_s(i) > 1.6
        score_s_nom.durNom{i} = 'veryLarge';
    else if score_s.dur_s(i) > 1
            score_s_nom.durNom{i} = 'lage';
        else if score_s.dur_s(i) > 0.25
                score_s_nom.durNom{i} = 'average';
            else if score_s.dur_s(i) > 0.125
                    score_s_nom.durNom{i} = 'short';
                else
                    score_s_nom.durNom{i} = 'veryShort';
                end
            end
        end
    end
    %dur Dot
    if nstruct.dot(note_idx(i))==1
        score_s_nom.durDot{i} = 'y';
    else
        score_s_nom.durDot{i} = 'n';
    end
    %pitch
    score_s_nom.pitchStep{i} = nstruct.pitchStep(i);
    switch score_s.pitch_mod(i)
        case 0
            score_s_nom.pitchChroma{i} = 'C';
        case 1
            score_s_nom.pitchChroma{i} = 'C#orDb';
        case 2
            score_s_nom.pitchChroma{i}= 'D';
        case 3
            score_s_nom.pitchChroma{i}= 'D#orEb';
        case 4
            score_s_nom.pitchChroma{i}= 'E';
        case 5
            score_s_nom.pitchChroma{i}= 'F';
        case 6
            score_s_nom.pitchChroma{i}= 'F#orGb';
        case 7
            score_s_nom.pitchChroma{i}= 'G';
        case 8
            score_s_nom.pitchChroma{i}= 'G#orAb';
        case 9
            score_s_nom.pitchChroma{i}= 'A';
        case 10
            score_s_nom.pitchChroma{i}= 'A#orBb';
        case 11
            score_s_nom.pitchChroma{i}= 'B';
    end
    
    %melodic analisys....??? como lo justifico? esto no se si existe o me
    %lo invente.... auqnue en realidad tampoco añade. A lo mejor se prodría
    %implementar algun tipo de analisis melodico mas formal: mirar berkely
    switch score_s.note2key(i)
        case 1 || 7 || 5 || 4 || 3 || 9 ||  8
            score_s_nom.note2keyIntQual{i} = 'consonant';
        otherwise
            score_s_nom.note2keyIntQual{i} = 'disonant';
    end
    
    %prev and next int Falta case none para initial and final note!
    if score_s.prev_int(i) > 0
        score_s_nom.prevIntDir{i}= 'ascending';
    else if score_s.prev_int(i) < 0
            score_s_nom.prevIntDir{i} = 'descencing';
        else
            score_s_nom.prevIntDir{i} = 'unison';
        end
    end
    
    if score_s.prev_int(i) > 0
        score_s_nom.nextIntDir{i}= 'ascending';
    else if score_s.prev_int(i) < 0
            score_s_nom.nextIntDir{i} = 'descencing';
        else
            score_s_nom.nextIntDir{i} = 'unison';
        end
    end
    
    
    if score_s.prev_int(i) > 6
        score_s_nom.prevIntSize{i}= 'large';
    else
        score_s_nom.prevIntSize{i} = 'small';
    end
    
    if score_s.prev_int(i) > 6
        score_s_nom.nextIntSize{i}= 'large';
    else
        score_s_nom.nextIntSize{i} = 'small';
    end
    
    %tempo Prefered tempos by Collier Lincoln (1993)
    %           92 , 117      , 160    , 220
    %Ranges     slow, moderate, medium , Up
    %boundaries <104, 105-138 , 139-180,>180
    
    if score_s.tempo(i) > 180
        score_s_nom.tempoNom{i}= 'UpTempo';
    else if score_s.tempo(i) > 139
            score_s_nom.tempoNom{i}= 'Medium';
        else if score_s.tempo(i) > 105
                score_s_nom.tempoNom{i}= 'Moderate';
            else
                score_s_nom.tempoNom{i}= 'Slow';
            end
        end
    end
    
    %chords functional harmnony
    % 1 r 2 r 3 4 r 5 r 6 r  7
    % 0 1 2 3 4 5 6 7 8 9 10 11
    %    if score_s.keymode == 'major'
    
    if score_s.chord2key(i) == 0 && (strcmp(score_s.chord_type{i}, 'major') || strcmp(score_s.chord_type{i}, 'Maj7'))%or 6 or 6/9 or maj9
        score_s_nom.chordFunc{i} = 'tonic';
    else if score_s.chord2key(i) == 9 && (strcmp(score_s.chord_type{i}, 'm') || strcmp(score_s.chord_type{i}, 'm7'))
            score_s_nom.chordFunc{i} = 'tonic';
        else if strcmp(score_s.chord_type{i}(1), '7') || strcmp(score_s.chord_type{i}, 'dim')
                score_s_nom.chordFunc{i} = 'dominant';
            else
                score_s_nom.chordFunc{i} = 'subdominant';
            end
        end
    end
    
    % 1 r 2 r 3 4 r 5 r 6 r  7
    % 0 1 2 3 4 5 6 7 8 9 10 11
    
    %note2chord interval
    %C G D A E B F# Db Ab Eb Bb F
    %1 5 9 6 3 7 #4 b2 b6 b3 b7 4
    %1 5 4 3 b3 6 b6 -->consontant 2 b2 7 b7--->disonant
    %1 7 5 4 3  9 8  -->           2 1  11 10-->
    
    switch score_s.note2chord(i)
        case 1 || 7 || 5 || 4 || 3 || 9 ||  8
            score_s_nom.note2chordIntQual{i} = 'consonant';
        otherwise
            score_s_nom.note2chordIntQual{i} = 'disonant';
    end
    
    %Key
    switch score_s.keyFifhts(i)
        case 0
            score_s_nom.keyNom{i} = 'C';
        case 1
            score_s_nom.keyNom{i} = 'G';
        case 2
            score_s_nom.keyNom{i} = 'D';
        case 3
            score_s_nom.keyNom{i} = 'A';
        case 4
            score_s_nom.keyNom{i} = 'E';
        case 5
            score_s_nom.keyNom{i} = 'B';
        case 6
            score_s_nom.keyNom{i} = 'F#';
        case -1
            score_s_nom.keyNom{i} = 'F';
        case -2
            score_s_nom.keyNom{i} = 'Bb';
        case -3
            score_s_nom.keyNom{i} = 'Eb';
        case -4
            score_s_nom.keyNom{i} = 'Ab';
        case -5
            score_s_nom.keyNom{i} = 'Db';
        case -6
            score_s_nom.keyNom{i} = 'F#';
    end
end

score_s_nom.durNom = score_s_nom.durNom';
score_s_nom.prevDur = circshift(score_s_nom.durNom,1);
score_s_nom.prevDur{1} = 'none';
score_s_nom.nextDur = circshift(score_s_nom.durNom,-1);
score_s_nom.nextDur{length (score_s_nom.nextDur)} = 'none';%last value is zero as it is the last note
score_s_nom.durDot = score_s_nom.durDot';

score_s_nom.pitchStep = score_s_nom.pitchStep';
score_s_nom.pitchAlter = nstruct.pitchAlter(note_idx)';
score_s_nom.pitchOctave = nstruct.pitchOctave(note_idx)';
score_s_nom.pitchChroma = score_s_nom.pitchChroma';

score_s_nom.prevIntDir = score_s_nom.prevIntDir';
score_s_nom.prevIntDir{1} = 'none';
score_s_nom.nextIntDir = score_s_nom.nextIntDir';
score_s_nom.nextIntDir{length (score_s_nom.nextIntDir)} = 'none';
score_s_nom.prevIntSize = score_s_nom.prevIntSize';
score_s_nom.prevIntSize{1} = 'none';
score_s_nom.nextIntSize = score_s_nom.nextIntSize';
score_s_nom.nextIntSize{length(score_s_nom.nextIntSize)} = 'none';

score_s_nom.tempoNom = score_s_nom.tempoNom';

score_s_nom.chordFunc = score_s_nom.chordFunc';
score_s_nom.note2chordIntQual = score_s_nom.note2chordIntQual';
score_s_nom.note2keyIntQual = score_s_nom.note2keyIntQual';

score_s_nom.keyNom = score_s_nom.keyNom';

end


function atrib=attributes(s,t)
%This function uses the field names of a structure and convert them in to a
%cell array with the attribute list following the arff format. Input
%paramenters are structures (s and t). The code merges attributes form the
%two structures.

%if isfield(s,'tempo')
%    s=rmfield(s,'tempo');
%end
%if isfield(t,'tempo')
%    t=rmfield(t,'tempo');
%end

header=fieldnames(s);
if isfield(s,'nar')%this is to add 3 narmour class descriptors to the header
    id=find(strcmp('nar',header));%find nar position on header vector
    headend=['nar1' 'nar2' 'nar3' header(id+1:end)']';
    header=[header(1:id-1);headend];
end

%atributes
atrib=cell(numel(header),1);

for i=1:numel(header)
    switch header{i}%if narmour filed exists
        case 'nar1'
            tp='P R D ID IP VP IR VR SA SB NA';
            atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp,'}']);%write atributes for nar1
        case 'nar2'
            atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp,'}']);%write atributes for nar2
        case 'nar3'
            atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp,'}']);%write atributes for nar3
        case 'chord_type'
            tp='+ 6 7 7#11 7#5 7#9 7b5 7b9 Maj7 c dim dim7 m m6 m7 m7b5 major';
            atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp,'}']);%write atributes for chord            
        case 'keyMode'
            tp='major minor';
            atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp,'}']);%write atributes for chord            
        case 'isChordN'
            tp='n y';
            atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp,'}']);%write atributes for chord            
        case 'mtr'
            tp='s ss w ww';
            atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp,'}']);%write atributes for chord            
        case 'phrase'
            tp='f i m';
            atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp,'}']);%write atributes for chord            
        case 'emb'
            tp='n y';
            atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp,'}']);%write atributes for chord            
        otherwise
%            array_class=class(s.(header{i}));
%            switch array_class
%                case 'double'
                    tp='numeric';
                    atrib(i)=space_cat(['@ATTRIBUTE',header(i),tp]);
%                case 'cell'
%                    [tp,~,~]=unique([s.(header{i})(:);t.(header{i})(:)]);
%                    atrib(i)=space_cat(['@ATTRIBUTE',header(i),'{',tp','}']);
%                case 'char'
%                    [tp,~,~]=unique([s.(header{i})(:);t.(header{i})(:)]);
%                    
%            end
    end
end
atrib=cellstr(atrib);
end

function B=space_cat(A)
B=[];
for i=1:numel(A)
    if i<numel(A)%if not the last
        B=strcat(B, A{i}, {' '});%concatenate with a space
    else
        B=strcat(B, A{i});%concatenate last element
    end
end
end

function arff_write(filename,s,trainOrTest,atrib, relationName)
%This function writes a arff file form a structure array and a cell array of
%attributes. The trainOrtest indicator defines if the last colum should be
%filled with actual values or by interrogation marks "?".
%filename
%structure
%[train, test]
%atrib (vector)
%relationName

%if isfield(s,'tempo')
%    s=rmfield(s,'tempo');
%end

cell_class=struct_class(s);%clasify class double=0 cell=1

header=fieldnames(s);

if isfield(s,'nar')%this is to add 3 narmour class descriptors to the header
    id=find(strcmp('nar',header));%find nar position on header vector
    cell_class=[cell_class(1:id);1;1;cell_class(id+1:end)];
    headend=['nar1' 'nar2' 'nar3' header(id+1:end)']';
    header=[header(1:id-1);headend];
end


c=s2c(s);

%Set up text and numbers format
format2=[];%initialize instances format

for i=1:(length(header))%we will concatenate strings to the size of headers
    if i~=(length(header))%if is not the last
        if cell_class(i)==0
            format2=[format2,'%f,'];%if not cell class use float format
        else
            format2=[format2,'%s,'];%else use string format
        end
    else
        
        if cell_class(i)==0
            format2=[format2,'%f\r\n,'];%if not cell class use float format
        else
            format2=[format2,'%s\r\n,'];%else use string format
        end
        
        % %        if isfield(s,'emb')&&strcmp(trainOrTest,'test')
        %             format2=[format2,'%s\r\n'];
        %  %       else
        %   %          format2=[format2,'%f\n'];
        %    %     end
    end
end
%c=c';

%c2(:,18)=c{:,18};

%include headers format for arff check them out!!! and then a printf for
%each....
%slash_idx = strfind(filename,'/');
%undscore_idx = strfind(filename,'_');
%if isempty(undscore_idx)
title=['@relation ',relationName];
%else

%    title=['@relation ',filename(slash_idx(end):undscore_idx(end)-1)];

%end

%written to
%Write text file
fid=fopen(filename,'w');
fprintf(fid,'%s\n','% This data was collected by Sergio Giraldo, MTG, Pompeu Fabra University, 2016 (sergio.giraldo@upf.edu). If you make use of this data please refer to the following citattions:');
fprintf(fid,'%s\n%s\n\n','% Giraldo, S., & Ramírez, R. (2016). A machine learning approach to ornamentation modeling and synthesis in jazz guitar. Journal of Mathematics and Music, 10(2), 107-126. doi: 10.1080/17459737.2016.1207814, URL: http://dx.doi.org/10.1080/17459737.2016.1207814');
fprintf(fid,'%s\n\n',title);
fprintf(fid,'%s\n',atrib{:});
fprintf(fid,'%s\n','');
fprintf(fid,'%s\n','@data');
for i=1:size(c,1)
    fprintf(fid,format2,c{i,:});
end
fclose(fid);
end

function cell_class=struct_class(s)
%This function retrieves a vector of the same length of the number of
%fields of a structure, containing and indicator of the class of the cells
%of a particular field, being 1 for cell class, and zero other wise.
header=fieldnames(s);
cell_class=zeros(length(header),1);
for i=1:length(header)
    switch class(s.(header{i}))
        case 'cell'
            cell_class(i)=1;
        otherwise
            cell_class(i)=0;
    end
end
end

function c=s2c(s)
sc=struct2cell(s);
N=length(fieldnames(s));
M=length(sc{1});
if isfield(s,'nar')
    c=cell(M,N+2);
    narId=find(strcmp('nar',fieldnames(s)));
    for i=1:M
        k=1;
        for j=1:N
            if j==narId
                for k=1:3
                    c{i,j+k-1}=sc{j,1}{i,k};
                end
            else
                %                 i
                %                 j
                %                 if (i==1378 && j==33)
                %                     lkjlk=0;
                %                 end
                if (i==744 && j==43)
                    sdfsd=1;
                end
                if isa(sc{j,1}(i),'cell')
                    c{i,j+k-1}=sc{j,1}{i};
                else
                    
                    if isinf(sc{j,1}(i))
                        c{i,j+k-1} = NaN;
                    else
                        c{i,j+k-1}=sc{j,1}(i);
                    end
                    %c{i,j+k-1}=sc{j,1}(i);
                end
            end
        end
        
        
        
    end
else
    c=cell(M,N);
    for i=1:N
        for j=1:M
            if iscell(sc{i,1}(j))
                c{j,i}=sc{i,1}{j};
            else
                if isinf(sc{i,1}(j))
                    c{j,i} = NaN;
                else
                    c{j,i}=sc{i,1}(j);
                end
            end
        end
    end
end
end

function score_s=addAttribute(score_s , attribute, attributeName)

fieldNames=fieldnames(score_s);
firstField=char(fieldNames(2));
for i=1:length(score_s.(firstField))
    switch class(attribute);
        case 'char'
            score_s.(attributeName){i}=attribute;
        case 'double'
            score_s.(attributeName)(i)=attribute;
    end
    score_s.(attributeName)=score_s.(attributeName)';
end
end

function nar=narmour_sig(nmat)
%This function calculates the Narmour strucutres on a midi file in nmat
%format. It parses the nmat matrix and for each note it classify the
%corresponding narmour structure for each of the three posible positions. 
%The classification is based on the work by Ramirez et al. 2006 and we have
%add two more classifiers: two long intervals in the same direction, and, a
%short interval followed by a long interval in the opposite direction.
%Long and short interval limit was set to 6 semitones. 

pc=pitch(nmat);% get pitch information in a vector.
nar=cell(length(pc),3);%Initialize an empty matrix of three columns for Narmour class for each note.
for i=1:length(pc)-2, %for each note
    notewin=pc(i:i+2); %create a note window of 3 notes
    dif1=diff(notewin); %diferentiate pitch to get intervals
    %tis=intsize2(notewin);
    if strcmp(intsize2(notewin),'ss')&&samedir(notewin) %get interval size and check direction.
        nar{i,1}='P';
    else
    if strcmp(intsize2(notewin),'ls')&&~samedir(notewin)
        nar{i,1}='R';
    else
    if dif1(1)==0&&dif1(2)==0
        nar{i,1}='D';
    else
    if dif1(1)==dif1(2) && dif1(1)<6
        nar{i,1}='ID';
    else
    if strcmp(intsize2(notewin),'ss')&&~samedir(notewin)
        nar{i,1}='IP';
    else
    if strcmp(intsize2(notewin),'sl')&&samedir(notewin)
        nar{i,1}='VP';
    else
    if strcmp(intsize2(notewin),'ls')&&samedir(notewin)
        nar{i,1}='IR';
    else
    if strcmp(intsize2(notewin),'ll')&&~samedir(notewin)
        nar{i,1}='VR';
    else
    if strcmp(intsize2(notewin),'ll')&&samedir(notewin)
        nar{i,1}='SA';
    else
    if strcmp(intsize2(notewin),'sl')&&~samedir(notewin)
        nar{i,1}='SB';
    else
        nar{i,1}='NA';
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
end
nar(1:end-1,2)=nar(2:end,1);
nar(1:end-2,3)=nar(3:end,1);
%fill out last columns
%1 col
nar{end-1,1}='NA';
nar{end,1}='NA';
%2 col
nar{end-2,2}='NA';
nar{end-1,2}='NA';
nar{end,2}='NA';
%3 col
nar{end-3,3}='NA';
nar{end-2,3}='NA';
nar{end-1,3}='NA';
nar{end,3}='NA';
end

function tis=intsize2(notewin)

%Given three notes' pitch, this function classify each of the two intervals
%betuen the notes as large or small, defining the limit in 6 semitones. 

dif1=diff(notewin);
if abs(dif1(1))<6&&abs(dif1(2))<6
    tis='ss';
else if abs(dif1(1))<6&&abs(dif1(2))>=6
    tis='sl';
else if abs(dif1(1))>=6&&abs(dif1(2))<6
    tis='ls';
    else
        tis='ll';
    end
    end
end
end
function sd=samedir(notewin)
%Given a set of three notes' pitch, this function returns 1 if the
%intervals betwen the two notes go in the same direction and zero
%otherwise. 

dif1=diff(notewin);
if dif1(1)*dif1(2)>0
    sd=1;
else
    sd=0;
end
end
        
function attribute2remove =prepareData(PA)

nominalFeat = {...
            ...'pitchOctave',... 
            'pitchAlter',...
            ...'pitchChroma',...
            ...'nextDur',... 
            ...'prevDur',... 
            ...'note2chordIntQual',...
            ...'note2keyIntQual',...
            ...'keyNom',...
            ...'chordFunc',... 
            ...'tempoNom',... 
            ...'nextIntSize',... 
            ...'prevIntSize',... 
            ...'nextIntDir',... 
            ...'prevIntDir',... 
            'pitchStep',... 
            ...'durNom',... 
            ...'durDot',... 
            ...'durType',... 
            ...'phrase',... 
            'tempo',... 
            'complex_expect',... 
            'complex_trans',... 
            ...'nar1',... 
            ...'nar2',... 
            ...'nar3',... 
            'mobility',... 
            'tessitura',... 
            'mel_atract',... 
            'ton_stab',... 
            'nar_co',... 
            'nar_pr',... 
            'nar_cl',... 
            'nar_id',... 
            'nar_rr',... 
            'nar_rd',... 
            ...'mtr',... 
            ...'isChordN',... 
            'note2chord',... 
            ...'chord_type',... 
            'chord2key',... 
            'chord_id',... 
            'note2key',... 
            ...'keyMode',... 
            'keyFifhts',... 
            'next_int',... 
            'prev_int',... 
            'pitch_mod',... 
            'onset_b_mod',... 
            'nxt_dur_s',... 
            'nxt_dur_b',... 
            'pre_dur_s',... 
            'pre_dur_b',... 
            'dur_s',... 
            'onset_s',... 
            'pitch',... 
            'duration_b',... 
            'onset_b'...  
            };
    

switch PA
    case 'emb'
        
        attribute2remove = {...
            ...
            'pitchOctave',... 
            'pitchAlter',...
            'pitchChroma',...
            'nextDur',... 
            'prevDur',... 
            'note2chordIntQual',...
            'note2keyIntQual',...
            'keyNom',...
            'chordFunc',... 
            'tempoNom',... 
            'nextIntSize',... 
            'prevIntSize',... 
            'nextIntDir',... 
            'prevIntDir',... 
            'pitchStep',... 
            'durNom',... 
            'durDot',... 
            'durType',... 
            ...'duration_dev'...
            ...'phrase',... 
            ...'tempo',... 
            ...'complex_expect',... 
            ...'complex_trans',... 
            ...'nar1',... 
            ...'nar2',... 
            ...'nar3',... 
            ...'mobility',... 
            ...'tessitura',... 
            ...'mel_atract',... 
            ...'ton_stab',... 
            ...'nar_co',... 
            ...'nar_pr',... 
            ...'nar_cl',... 
            ...'nar_id',... 
            ...'nar_rr',... 
            ...'nar_rd',... 
            ...'mtr',... 
            ...'isChordN',... 
            ...'note2chord',... 
            ...'chord_type',... 
            ...'chord2key',... 
            ...'chord_id',... 
            ...'note2key',... 
            ...'keyMode',... 
            ...'keyFifhts',... 
            ...'next_int',... 
            ...'prev_int',... 
            ...'pitch_mod',... 
            ...'onset_b_mod',... 
            ...'nxt_dur_s',... 
            ...'nxt_dur_b',... 
            ...'pre_dur_s',... 
            ...'pre_dur_b',... 
            ...'dur_s',... 
            ...'onset_s',... 
            ...'pitch',... 
            ...'duration_b',... 
            ...'onset_b',...
            };%Index of attributes to be reomoved
    case 'duration_rat'
        attribute2remove = {...

            ...
            'pitchOctave',... 
            'pitchAlter',...
            'pitchChroma',...
            'nextDur',... 
            'prevDur',... 
            'note2chordIntQual',...
            'note2keyIntQual',...
            'keyNom',...
            'chordFunc',... 
            'tempoNom',... 
            'nextIntSize',... 
            'prevIntSize',... 
            'nextIntDir',... 
            'prevIntDir',... 
            'pitchStep',... 
            'durNom',... 
            'durDot',... 
            'durType',... 
            ...'duration_dev'...
            ...'phrase',... 
            ...'tempo',... 
            ...'complex_expect',... 
            ...'complex_trans',... 
            ...'nar1',... 
            ...'nar2',... 
            ...'nar3',... 
            ...'mobility',... 
            ...'tessitura',... 
            ...'mel_atract',... 
            ...'ton_stab',... 
            ...'nar_co',... 
            ...'nar_pr',... 
            ...'nar_cl',... 
            ...'nar_id',... 
            ...'nar_rr',... 
            ...'nar_rd',... 
            ...'mtr',... 
            ...'isChordN',... 
            ...'note2chord',... 
            ...'chord_type',... 
            ...'chord2key',... 
            ...'chord_id',... 
            ...'note2key',... 
            ...'keyMode',... 
            ...'keyFifhts',... 
            ...'next_int',... 
            ...'prev_int',... 
            ...'pitch_mod',... 
            ...'onset_b_mod',... 
            ...'nxt_dur_s',... 
            ...'nxt_dur_b',... 
            ...'pre_dur_s',... 
            ...'pre_dur_b',... 
            ...'dur_s',... 
            ...'onset_s',... 
            ...'pitch',... 
            ...'duration_b',... 
            ...'onset_b',...
        };%Index of attributes to be reomoved
    
    case 'onset_dev'
        attribute2remove = {...
            
            ...
            'pitchOctave',... 
            'pitchAlter',...
            'pitchChroma',...
            'nextDur',... 
            'prevDur',... 
            'note2chordIntQual',...
            'note2keyIntQual',...
            'keyNom',...
            'chordFunc',... 
            'tempoNom',... 
            'nextIntSize',... 
            'prevIntSize',... 
            'nextIntDir',... 
            'prevIntDir',... 
            'pitchStep',... 
            'durNom',... 
            'durDot',... 
            'durType',... 
            ...'duration_dev'...
            ...'phrase',... 
            ...'tempo',... 
            ...'complex_expect',... 
            ...'complex_trans',... 
            ...'nar1',... 
            ...'nar2',... 
            ...'nar3',... 
            ...'mobility',... 
            ...'tessitura',... 
            ...'mel_atract',... 
            ...'ton_stab',... 
            ...'nar_co',... 
            ...'nar_pr',... 
            ...'nar_cl',... 
            ...'nar_id',... 
            ...'nar_rr',... 
            ...'nar_rd',... 
            ...'mtr',... 
            ...'isChordN',... 
            ...'note2chord',... 
            ...'chord_type',... 
            ...'chord2key',... 
            ...'chord_id',... 
            ...'note2key',... 
            ...'keyMode',... 
            ...'keyFifhts',... 
            ...'next_int',... 
            ...'prev_int',... 
            ...'pitch_mod',... 
            ...'onset_b_mod',... 
            ...'nxt_dur_s',... 
            ...'nxt_dur_b',... 
            ...'pre_dur_s',... 
            ...'pre_dur_b',... 
            ...'dur_s',... 
            ...'onset_s',... 
            ...'pitch',... 
            ...'duration_b',... 
            ...'onset_b',...
        };%Index of attributes to be reomoved
    
    
    case 'pitchDev'
        attribute2remove = {...

            ...
            'pitchOctave',... 
            'pitchAlter',...
            'pitchChroma',...
            'nextDur',... 
            'prevDur',... 
            'note2chordIntQual',...
            'note2keyIntQual',...
            'keyNom',...
            'chordFunc',... 
            'tempoNom',... 
            'nextIntSize',... 
            'prevIntSize',... 
            'nextIntDir',... 
            'prevIntDir',... 
            'pitchStep',... 
            'durNom',... 
            'durDot',... 
            'durType',... 
            ...'duration_dev'...
            ...'phrase',... 
            ...'tempo',... 
            ...'complex_expect',... 
            ...'complex_trans',... 
            ...'nar1',... 
            ...'nar2',... 
            ...'nar3',... 
            ...'mobility',... 
            ...'tessitura',... 
            ...'mel_atract',... 
            ...'ton_stab',... 
            ...'nar_co',... 
            ...'nar_pr',... 
            ...'nar_cl',... 
            ...'nar_id',... 
            ...'nar_rr',... 
            ...'nar_rd',... 
            ...'mtr',... 
            ...'isChordN',... 
            ...'note2chord',... 
            ...'chord_type',... 
            ...'chord2key',... 
            ...'chord_id',... 
            ...'note2key',... 
            ...'keyMode',... 
            ...'keyFifhts',... 
            ...'next_int',... 
            ...'prev_int',... 
            ...'pitch_mod',... 
            ...'onset_b_mod',... 
            ...'nxt_dur_s',... 
            ...'nxt_dur_b',... 
            ...'pre_dur_s',... 
            ...'pre_dur_b',... 
            ...'dur_s',... 
            ...'onset_s',... 
            ...'pitch',... 
            ...'duration_b',... 
            ...'onset_b',...
            };%Index of attributes to be reomoved
        
    case 'energy_rat'
        attribute2remove = {...

            ...
            'pitchOctave',... 
            'pitchAlter',...
            'pitchChroma',...
            'nextDur',... 
            'prevDur',... 
            'note2chordIntQual',...
            'note2keyIntQual',...
            'keyNom',...
            'chordFunc',... 
            'tempoNom',... 
            'nextIntSize',... 
            'prevIntSize',... 
            'nextIntDir',... 
            'prevIntDir',... 
            'pitchStep',... 
            'durNom',... 
            'durDot',... 
            'durType',... 
            ...'duration_dev'...
            ...'phrase',... 
            ...'tempo',... 
            ...'complex_expect',... 
            ...'complex_trans',... 
            ...'nar1',... 
            ...'nar2',... 
            ...'nar3',... 
            ...'mobility',... 
            ...'tessitura',... 
            ...'mel_atract',... 
            ...'ton_stab',... 
            ...'nar_co',... 
            ...'nar_pr',... 
            ...'nar_cl',... 
            ...'nar_id',... 
            ...'nar_rr',... 
            ...'nar_rd',... 
            ...'mtr',... 
            ...'isChordN',... 
            ...'note2chord',... 
            ...'chord_type',... 
            ...'chord2key',... 
            ...'chord_id',... 
            ...'note2key',... 
            ...'keyMode',... 
            ...'keyFifhts',... 
            ...'next_int',... 
            ...'prev_int',... 
            ...'pitch_mod',... 
            ...'onset_b_mod',... 
            ...'nxt_dur_s',... 
            ...'nxt_dur_b',... 
            ...'pre_dur_s',... 
            ...'pre_dur_b',... 
            ...'dur_s',... 
            ...'onset_s',... 
            ...'pitch',... 
            ...'duration_b',... 
            ...'onset_b',...
        };
        
    case 'embellish_nom'
        attribute2remove = [...
            'duration_dev'...
            nominalFeat{:}...
            ];%Index of attributes to be reomoved
        
    case 'duration_dev_nom'
        attribute2remove = [...
            ...'duration_dev'...
            nominalFeat{:}...
            ];%Index of attributes to be reomoved
        
    case 'onset_dev_nom'
        attribute2remove = [...
            ...'duration_dev'...
            nominalFeat{:}...
            ];%Index of attributes to be reomoved
     case 'energy_dev_nom'
        attribute2remove = [...
            ...'duration_dev'...
            nominalFeat{:}...
            ];%Index of attributes to be reomoved
        
        
end

end


