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
        %NOT WORKING
        %nstruct.keyMode=char(keyMode.item(0).getFirstChild.getData);%get data from node
        %MARC FIX
        nstruct.keyMode=char(keyMode.item(0));

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