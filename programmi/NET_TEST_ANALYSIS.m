
data=load('indexMine_completi.mat');

index=data.data_index;

training_data=load('DataForTrainingMine_completi.mat', 'training_trials', 'training_labels');

trials=training_data.training_trials;
labels=training_data.training_labels;



a=find(labels== -1);
training_labels=labels;
training_labels(a)=0;


separation_test=floor(length(index)*0.7);


index_test=index((separation_test+1):end);

test_dataset=trials(:,:,:,index_test);

labelsTest=labels(index_test);


minMse=100000000;


netFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\netsMineCompl'; % Folder for nets to test


filePattern = fullfile(netFolder, '*.mat'); % List of all data files 
filenames = dir(filePattern);

truelabel=labelsTest;

MSEarray=zeros(1, length(filenames));



for k = 1 : length(filenames)

    k
    baseFileName = filenames(k).name;
    fullFileName = fullfile(filenames(k).folder, baseFileName);
    Network=load(fullFileName);

    examinedNet=Network.net;
    
    y= classify(examinedNet, test_dataset);


    
    for i=1:length(y)
        
        if y(i)==categorical(1)
            classifiedLabels(i)=1;
        else
            classifiedLabels(i)=0;
        end
        
    end


    
    perf = immse(truelabel,classifiedLabels);
    MSEarray(k)=perf;


    
    if perf<minMse

        minMse=perf;
        bestNet=fullFileName;
        minMse

        save('bestNetMineNewPrepCorrWind_completa.mat', 'examinedNet');

    end
        
   

end


bestNet
