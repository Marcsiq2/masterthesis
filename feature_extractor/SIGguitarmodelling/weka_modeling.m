function weka_modeling

PA = {...'embellishment',...
      'durRat',...
      'onsetDev',...
      ...'pitchDev',...
      'energyRat'};
for i=1:4
    weka_modelingPA(PA{i});
end
end
function weka_modelingPA(PA)

%TO DO:create a for loop to iterate with different algorithms

if strcmp(PA,'embellishment')
    classifier = {'weka.classifiers.trees.J48 -C 0.25',...
                  'weka.classifiers.functions.MultilayerPerceptron -L 0.3 -M 0.2 -N 500 -V 0 -S 0 -E 20 -H a',...
                  'weka.classifiers.functions.SMO -C 1.0 -L 0.001 -P 1.0E-12 -N 0 -V -1 -W 1 -K "weka.classifiers.functions.supportVector.PolyKernel -C 250007 -E 1.0"',...
                  'weka.classifiers.lazy.IBk -K 1 -W 0 -A "weka.core.neighboursearch.LinearNNSearch -A \"weka.core.EuclideanDistance -R first-last\""'...
                  };
    
else
    classifier = {'weka.classifiers.trees.M5P -M 4.0'...
                  'weka.classifiers.functions.MultilayerPerceptron -L 0.3 -M 0.2 -N 500 -V 0 -S 0 -E 20 -H a',...
                  'weka.classifiers.functions.SMOreg -C 1.0 -N 0 -I "weka.classifiers.functions.supportVector.RegSMOImproved -L 0.001 -W 1 -P 1.0E-12 -T 0.001 -V" -K "weka.classifiers.functions.supportVector.PolyKernel -C 250007 -E 1.0"',...
                  'weka.classifiers.lazy.IBk -K 1 -W 0 -A "weka.core.neighboursearch.LinearNNSearch -A \"weka.core.EuclideanDistance -R first-last\""'...
                  };
    
end
for i=1:4
    in= input('chose the classiffier you want to use:\n1-Trees\n2-ANN\n3-SVM\n4-KNN\n:');
    weka_mod_pa_classifier(PA, classifier{in},in);
end

end
function weka_mod_pa_classifier(PA, classifier,classif_idx)

    path_file_s = [pwd,'\Files\scores\xml\'];
    files=dir(path_file_s);%Get files names and attributes in a astructure array
    numberOfFiles=length(files);%How many files (-2 cause . and .. are counted as files
    


%% For each file:

for i=1:numberOfFiles, %for each file (do not count . and ..
    if ~(strcmp(files(i,1).name,'.'))&& ~(strcmp(files(i,1).name,'..'))&& ~(strcmp(files(i,1).name,'.DS_Store'))  %if to by pass . and .. DOS comands listed by dir as files
        
        if strcmp(files(i,1).name(end-2:end),'xml') %filter xml files only
            
%remove any old train_test, and outputs text files
            system(['del ',pwd,'/dataOut/weka_tmp_files/output.txt']);

            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% run weka experiment train test %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            classif_name = {'Trees','ANN','SVM','KNN'};
            fprintf('   running weka train-test %s experiment, with %s classifier for %s...',PA, classif_name{classif_idx}, files(i,1).name(1:end-4));
            train_file = [pwd,'/Files/dataOut/arff/',files(i,1).name(1:end-4),'_pas_20b.arff'];
            test_file = [pwd,'/Files/dataOut/arff/',files(i,1).name(1:end-4),'_pas_8b.arff'];

            system(['java -cp "C:\Program Files\weka-3-8-1\weka.jar" -Xmx1024m ',classifier,' -p 0 -t ',train_file,' -T ',test_file,' >> ',pwd,'/Files/dataOut/weka_tmp_files/output.txt']);

            %% clean ouput file
            
            %read output file into a cell array
            fid=fopen([pwd,'/Files/dataOut/weka_tmp_files/output.txt']); 
            textscan(fid,'*%s',1, 'headerlines' , 5);        
            if strcmp(PA,'embellishment')
                 format = '%f %*f:%s %*f:%s %*[^\n]'; 
            else
                format = '%f %f %f %f';
            end
            pred = textscan(fid, format);
            fclose(fid);
            %create clean output file and write prediction column only
            fid=fopen([pwd,'/dataOut/arffs/leaveOneOut/',PA,'/predictions/',files(i,1).name(1:end-4),'_',classif_name{classif_idx},'.txt'],'w'); 
            if strcmp(PA,'embellishment')
                fprintf(fid,'%s\n',pred{1,3}{:});
            else
                fprintf(fid,'%f\n',pred{1,3});
            end
            fclose(fid);
            
            %% Optional: Save instance number, actual value and predicted value cell array in a .mat format
            %save ([pwd,'/dataOut/arffs/leaveOneOut/',PA,'/predictions/',files(i,1).name(1:end-4),'.mat'], 'pred');
          

        end
        fprintf('Done!\n');
    end
end
fprintf('Done!\n');
end

