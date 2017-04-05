function pred=weka_run(train_ds,test_ds)
%run weka

%change OS directory to matlab WD)
current_folder=pwd;
cd(current_folder);

%remove any old train_test, and outputs text files
system(['rm ',current_folder,'/weka_files/output.txt']);
system(['rm ',current_folder,'/weka_files/output_clean.txt']);

%delete previous versions of train test arfs
system(['rm ',current_folder,'/weka_files/train.arff']);
system(['rm ',current_folder,'/weka_files/test.arff']);

%set path for tran and test files
train_file='weka_files/train.arff';
test_file='weka_files/test.arff';

%create arfs
atrib=attributes(train_ds,test_ds);
arff_write(train_file,train_ds,'train',atrib);
arff_write(test_file,test_ds,'test',atrib);

%run weka train test experiment
%create comand to run weka from batck procesing file
system(['java -cp /Applications/weka-3-6-9.app/Contents/Resources/Java/weka.jar -Xmx1024m weka.classifiers.trees.J48 -C 0.25 -p 0 -t ',train_file,' -T ',test_file,' >> weka_files/output.txt']);


%if read_data==1
%% clean ouput file using python scrypt by Sankalp Gulati (MTG Group)
    system(['python ',current_folder,'/Clean_PredictionFile.py ',current_folder,'/weka_files/output.txt ',current_folder,'/weka_files/output_clean.txt']);
    pred=textread('weka_files/output_clean.txt','%s');
% else
%     fid = fopen('weka_files/output.txt');
%     C1 = textscan(fid, '%s',6);
%     C2 = textscan(fid, '%s',4);
%     C3 = textscan(fid, '%f %s %f %s');
% 
%     fclose(fid);
%     pred=C3{1,3};
% end
end



%%%%Fix the arf write in order to get always the same atributes for cells,
%%%%do a general list of atributes for chord, chortype, mtr, nar. Also
%%%%binary values (y n) should be defined by default, not checking the list.