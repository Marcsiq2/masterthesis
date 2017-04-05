function emb = embellish(nmat1,nmat2,p2s)
%Given a midi score and a midi performance of that score, we use the
%midi2ds to calculate note descriptors for each file, and then characterize
%the embelishments (transformations done) to each note of the score.

emb=struct;%create embelishment estucture
emb.p2s=p2s;

%Embelishments: each note can be ornamented by a set of notes that are
%transformations with respect of the original note,  acording to the music
%context. For each note of the performed we know to which note corresponds,
%and the ornamentation is measured by beat offset (boff), interval offset (ioff), and
%duration in beats (already calculated as dur), with respect of the original note.
%We also calculated ornament duration difference (odd), and number of notes used to ornament.


%Interval offset with respect to original note: here we rest the pitch of
%the each performance note and the pitch of its corresponding note in the
%original score.
emb.ioff=nmat2(:,4) - nmat1(p2s(:,2),4);

%Beat onset with respect to original note: here we rest the beat onset of
%each performed note and its corresponding note in the score. This way we
%measure anticipations or ritardations.
emb.boff=nmat2(:,1) - nmat1(p2s(:,2),1);

%ratio (with respect to the onset of the note)
emb.boff_r=(nmat2(:,1) - nmat1(p2s(:,2),1))./nmat1(p2s(:,2),1);

%Duration difference with respect to the original note (odr)... relevant? The problem
%here are the ornament notes that are the same duration regardless the
%original duration. (difference or ratio?)
emb.odd=nmat2(:,2) - nmat1(p2s(:,2),2);

%ratio(with respect to the duration of the note)
emb.odd_r=nmat2(:,2) ./nmat1(p2s(:,2),2);

        

