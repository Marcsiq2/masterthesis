function [pred,CCI,CCI_precent,CM]=cross_val2(class_y_ds,class_n_ds,folds)
%This function performs the cross validation for a machine
%learning experiment. It uses as imput parameters a structure array, the
%number of folds, a seed indicator (true or false) to use the same seed
%each time the experiment is performed or a different one otherwise, and
%finally the classifier or algorithm to use for the experiment.
%Version 2 of the function receives 2 randomazed arrays of ach of two
%BALANCED clases and perfrorm the 10 cross fold test


%Create folds indexes (distributed in K folds)
d=floor(numel(class_y_ds.pitch)/folds);%divide the data set into the number of folds, rounding
r=rem(numel(class_y_ds.pitch),folds);%Get the reminder of the division
index=ones(folds,2);%create a ones matrix with the number of folds size x 2 
for i=1:folds %for each fold...
    if i==1 % if is the first fold
        in=1; % define in and out index from 1 to 1st fold sample size
        out=in+d;
    else if i<r+1;% While i is smaller than the remaining of the division the folds sizes are increased by one
        in=in+d+1;
        out=in+d;
        else
            if i==r+1
            in=in+d+1; % define in and out of the size of the division (sample size/folds)
            else
            in=in+d; % define in and out of the size of the division (sample size/folds)
            end    
        out=in+d-1;
        end
    end
    index(i,1)=in;%store each in out index on the index matrix
    index(i,2)=out;
end
%Run machine learning experiment
pred=[];
%atrib=attributes(score_ds,score_ds);
flag=0;
for i=1:folds
    %get test subset for y class
    if i==1
        test_y_ds=remove_instances(class_y_ds,index(i+1,1):index(end,2));
    else
        if i==folds
            test_y_ds=remove_instances(class_y_ds,index(1,1):index(i-1,2));
        else
            test_y_ds=remove_instances(class_y_ds,index(i+1,1):index(end,2));
            test_y_ds=remove_instances(test_y_ds,index(1,1):index(i-1,2));
        end
    end
    
   %get test subset for n class
     if i==1
        test_n_ds=remove_instances(class_n_ds,index(i+1,1):index(end,2));
    else
        if i==folds
            test_n_ds=remove_instances(class_n_ds,index(1,1):index(i-1,2));
        else
            test_n_ds=remove_instances(class_n_ds,index(i+1,1):index(end,2));
            test_n_ds=remove_instances(test_n_ds,index(1,1):index(i-1,2));
        end
        %concatenate test y,n
     end
    test_ds=structCat(test_y_ds,test_n_ds);
    
    %get training subset for y class
    train_y_ds=remove_instances(class_y_ds,index(i,1):index(i,2));

    
   %get training subset for n class
    train_n_ds=remove_instances(class_n_ds,index(i,1):index(i,2));

    %concatenate train y,n
    train_ds=structCat(train_y_ds,train_n_ds);
    
    pred=[pred ; weka_run(train_ds,test_ds)];
    fprintf('Runing train test experiment for fold %i\n',i);
    
    if flag==0
    score_ds=test_ds;
    flag=1;
    else
    score_ds=structCat(score_ds,test_ds);%create dataset concatanating test set for evaluation
    end
    
end

% %un randomimze
% [~, un_rand_idx]=sort(rand_idx);
% pred=pred(un_rand_idx);

%evaluation

%correctly classified instances
header=fieldnames(score_ds); %Get field names ina a cell array
j=0;%initialize conunter of correctly classified instances
for i=1:numel(pred)%for each data
    j=j+strcmp(pred(i),score_ds.(header{end})(i));% if prediction is correct increas counter by one
end

CCI=j;%assign value of counter to CCI
CCI_precent=j/numel(pred); %Calculate percentage of CCI

%confusion matrix
class=unique(score_ds.(header{end})); %look ofr unique clases in the last column of the structure data (y or n in this case)
if strcmp(class(1),'n')
   class=flipud(class);%flip to y-n order
end
CM=zeros(numel(class));%initialize matrix of size of length of the clases
for i=1:numel(class)
    for j=1:numel(class)% on each cell of the matrix...
        for k=1:numel(pred)% for each prediction ...
            % increas by one each time the current pair of classes were classified to be the same.
            CM(i,j)=CM(i,j)+(strcmp(score_ds.(header{end})(k),class(i))&& strcmp(pred(k), class(j)));
        end
    end
end
end
            



