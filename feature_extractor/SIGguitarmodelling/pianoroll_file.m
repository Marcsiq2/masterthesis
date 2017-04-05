function pianoroll_file(h)

[file,path_file_s]=uigetfile('*.mat','Choose a nmat score file');%Get the directory path where the midi and xml files are stored

load([path_file_s,file],'nmat*');

figure(h)

if exist('nmat1')
    pianoroll(nmat1);
else
    pianoroll(nmat2);
end
end
