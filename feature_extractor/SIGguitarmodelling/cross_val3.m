function [pred,CCI,CCI_precent,CM]=cross_val3(class_y_ds,class_n_ds)
%This function performs the cross validation for a machine
%learning experiment using weka (blinded)

%Run machine learning experiment
pred=[];

test_y_ds=class_y_ds;
test_n_ds=class_n_ds;
test_ds=structCat(test_y_ds,test_n_ds);

train_y_ds=class_y_ds;
train_n_ds=class_n_ds;
train_ds=structCat(train_y_ds,train_n_ds);


fprintf('Runing train test experiment with 1o cross fold validation\n');
pred=[pred ; weka_run_cv(train_ds,test_ds)];
fprintf('Done...................................................................................\n');


score_ds=test_ds;%create dataset concatanating test set for evaluation

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
            



