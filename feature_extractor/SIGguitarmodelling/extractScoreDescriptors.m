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
        phrase{i}=['initial'];%lable notes that are beguining of a phrase
    else if (b(i+1)>mean(b)*2)%if the next note is the beguining of a phrase, label prevous note as phrase end
            phrase{i}=['final'];%lable notes that are beguining of a phrase
        else
            phrase{i}=['middle'];%lable notes as "in the middle of a phrase"
        end
    end
end

phrase{length(b)}=['final'];%lable last note as end of  phrase"
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