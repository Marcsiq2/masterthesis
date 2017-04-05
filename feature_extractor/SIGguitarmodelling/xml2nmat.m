function [nmat,nstruct]=xml2nmat(xmlFile)

[~, nstruct, ~] =xmlMusicParse(xmlFile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% onset    dur       chan       pitch      vol     onset      dur   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

onset_sec=0;
onsetBeat=0;%initialize onset beat
lineCount=1;%line of nmat couter
i=1; 

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
        end
    end
onsetBeat=onsetBeat+durationBeat;%advance onset to end of the current note
i=i+1;%move to next note
end