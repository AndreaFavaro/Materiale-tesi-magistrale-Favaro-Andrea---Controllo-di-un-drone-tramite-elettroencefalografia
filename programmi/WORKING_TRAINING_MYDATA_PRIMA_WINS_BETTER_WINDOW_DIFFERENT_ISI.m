

clear

myFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\dati_miei_buoni'; 

filePattern = fullfile(myFolder, '*.mat'); % List of all data files 
filenames = dir(filePattern);

training_trials=[];
training_labels=[];
partial_data=[];
partial_labels=[];


D=designfilt('bandpassiir', 'FilterOrder', 8, 'PassbandFrequency1', 1, 'PassbandFrequency2', 12, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);



no=0;

tot_trials=[];


for k = 1 : length(filenames)

    partial_data=[];
    dataset_resc=[];
    baseFileName = filenames(k).name;
    fullFileName = fullfile(filenames(k).folder, baseFileName);
    fprintf(1, 'Preprocessing %s\n', fullFileName);
    load(fullFileName)


    resto=mod(length(flashSeq), 4);

    flashSeqCorr=flashSeq(:, 1+no:length(flashSeq)-resto-4); %così è divisibile per 4 e salto l'ultima fetta che potrebbe dare problemi se non è completa

    labels=-ones(1,length(flashSeqCorr));    
    labels(flashSeqCorr(2,:)==target)=1;

    startingPoint=find(EEGsamples(9, :)==flashSeqCorr(1,1));
   
    dataset=EEGsamples(:,startingPoint:end); 


    %-----preprocessing---------------------------

    dataset_filt= transpose(filtfilt(D, transpose(dataset(1:8, :))));   

    dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);
   
    for i=1:8  
     
        dataset_resc(i,:) =  rescale(dataset_wins(i,:),-1,1);                 

    end  

    timestamps=dataset(9, 1:10:end);

    dataset_subs=dataset_resc(:, 1:10:end); %25 campioni/sec

    %--------------------------------------------


    dataset_timed=cat(1, dataset_subs, timestamps);


    for j = 1:length(labels)
        timeposition=flashSeqCorr(1, j);
        dist=abs(dataset_timed(9,:)-timeposition);
        minDist=min(dist);
        timeIndex=find(dist==minDist);

        window=dataset_subs(1:8, timeIndex(1):timeIndex(1)+24); %finestre da 25

        partial_data=cat(2, partial_data, window);

    end

    partial_labels=[partial_labels, labels];

    clear EEGsamples flashSeq target valid;
    

    trials=zeros(length(labels), 8, 25);

    for i=1:length(labels)

        trials(i,:,:)=partial_data(:, 1+25*(i-1):25*i);   
    
        tot_trials=cat(1, tot_trials, trials(i,:,:));
    end

end


%#############################PARTE NON NECESSARIA, VEDI README#########################################
%#######################################################################################################
%
%
% myFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\data_with_drone_noise'; 
% 
% filePattern = fullfile(myFolder, '*.mat'); % List of all data files 
% filenames = dir(filePattern);
% 
% for k = 1 : length(filenames)

%     partial_data=[];
%     dataset_resc=[];

%     baseFileName = filenames(k).name;
%     fullFileName = fullfile(filenames(k).folder, baseFileName);
%     fprintf(1, 'Preprocessing %s\n', fullFileName);
%     load(fullFileName)
% 
% 
%     resto=mod(length(flashSeq), 4);
% 
%     flashSeqCorr=flashSeq(:, 1+no:length(flashSeq)-resto-4); %così è divisibile per 4 e salto l'ultima fetta che potrebbe dare problemi se non è completa
% 
%     labels=-ones(1,length(flashSeqCorr));    
%     labels(flashSeqCorr(2,:)==target)=1;
% 
% 
%     startingPoint=find(EEGsamples(9, :)==flashSeqCorr(1,1));
%    
%     dataset=EEGsamples(:,startingPoint:end);
%
%
% 
%     dataset_filt= transpose(filtfilt(D, transpose(dataset(1:8, :)))); 
% 
%     dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);
%    
%     for i=1:8  
%      
%         dataset_resc(i,:) =  rescale(dataset_wins(i,:),-1,1);                 
% 
%     end  
% 
%     timestamps=dataset(9, 1:10:end);
%
%     dataset_timed=cat(1, dataset_subs, timestamps);
% 
% 
%     for j = 1:length(labels)
%
%         timeposition=flashSeqCorr(1, j);
%         dist=abs(dataset_timed(9,:)-timeposition);
%         minDist=min(dist);
%         timeIndex=find(dist==minDist);
%
%         window=dataset_subs(1:8, timeIndex(1):timeIndex(1)+24); %finestre da 25
% 
%         partial_data=cat(2, partial_data, window);
%
%     end
% 
%     partial_labels=[partial_labels, labels];
%
%     clear EEGsamples flashSeq target valid;
%     
%  
%
%     trials=zeros(length(labels), 8, 25);
% 
%     for i=1:length(labels)
%  
%         trials(i,:,:)=partial_data(:, 1+25*(i-1):25*i);   
%     
%         tot_trials=cat(1, tot_trials, trials(i,:,:)); 
%
%     end
%
% end

%#######################################################################################################
%#######################################################################################################


M=zeros(4,25,3,length(partial_labels));

for z = 1:length(partial_labels)

    M(2,:,1,z)=tot_trials(z, 1,:);
    M(4,:,1,z)=tot_trials(z, 2,:);       
    M(3,:,2,z)=tot_trials(z, 3,:);
    M(4,:,2,z)=tot_trials(z, 4,:);
    M(4,:,3,z)=tot_trials(z, 5,:);
    M(2,:,3,z)=tot_trials(z, 6,:);
    M(1,:,2,z)=tot_trials(z, 7,:);
    M(2,:,2,z)=tot_trials(z, 8,:);

end
 
    
training_trials=M;

training_labels = partial_labels;  



save('TrialsMine_completi.mat', 'training_trials');
save('LabelsMine_completi.mat', 'training_labels');





%--------oversampling------------------------------------------------------


%%---se serve solo questa parte---
% training_trials=load('TrialsMine.mat').training_trials;
% training_labels=load('LabelsMine.mat').training_labels;
%%--------------------------------


ttt=load('TrialsMine_completi.mat');
ttl=load('LabelsMine_completi.mat');


training_trials=ttt.training_trials;
training_labels=ttl.training_labels;

index=[1:1:length(training_labels); training_labels];



rng(0)

[G,classes] = findgroups(training_labels);

numObservations = splitapply(@numel,training_labels,G);

desiredNumObservationsPerClass = max(numObservations);

new_index = splitapply(@(x){randReplicateFiles(x,desiredNumObservationsPerClass)},index(1,:),G);

new_index = new_index(randperm(length(new_index)));

newtrials=cat(4, training_trials(:,:,:,new_index{1,1}), training_trials(:,:,:,new_index{1,2}));

clear training_trials;

training_trials=newtrials;

newlabels=cat(2, training_labels(new_index{1,1}), training_labels(new_index{1,2}));

clear training_labels;

training_labels=newlabels;

reord=[1:1:length(training_labels)];

reord = reord(randperm(length(reord)));

training_trials=training_trials(:,:,:,reord);
training_labels=training_labels(reord);

save('DataForTrainingMine_completi.mat', 'training_trials', 'training_labels');


%--------------------------------------------------------------------------


a=find(training_labels== -1);
training_labels1=training_labels;
training_labels1(a)=0;

training_labels1=categorical(training_labels1);

rng(42); %serve per la replicabilità di data_index in caso di debug

data_index=randperm(length(training_trials));

save('indexMine_completi.mat', 'data_index');


%-----------------------------------------------------------------------



separation_test=floor(length(data_index)*0.7);

index_training=data_index(1:separation_test);
index_test=data_index((separation_test+1):end);

training_dataset=training_trials(:,:,:,index_training);
labelsTraining=training_labels1(index_training);
test_dataset=training_trials(:,:,:,index_test);
labelsTest=training_labels1(index_test);

for sep=1:10
    
    knife=floor(length(training_dataset)*0.1);
    sliceOfCake(sep,:,:,:,:)=training_dataset(:,:,:,(1+(sep-1)*knife):(sep*knife));
    cakeLabels(sep,:)=labelsTraining((1+(sep-1)*knife):(sep*knife));
    
end



for patience=10:10:30

    for ii=1:10

        %----RETE----

        layers_training = [

            imageInputLayer([4 25 3], 'Normalization', 'none')
    
            convolution2dLayer(3,8,'padding',1) %i canali li determina in automatico
            reluLayer
            batchNormalizationLayer
            dropoutLayer(0.2)
    

            convolution2dLayer(3 ,8,'padding',0)  
            reluLayer
            batchNormalizationLayer
            dropoutLayer(0.2)
    

            fullyConnectedLayer(368)  %flatten
            fullyConnectedLayer(30)


            fullyConnectedLayer(2)

            softmaxLayer

            classificationLayer('Classes',[categorical(0) categorical(1)])
        ];

        %----FINE RETE----



        trainSet=[];
        trainLabels=[];
        
        whichSlices=[1:1:10];
        whichSlices(ii)=[];
        
        for k=whichSlices
            piece=[];
            piece(:,:,:,:)=sliceOfCake(k,:,:,:,:);
            trainSet=cat(4, trainSet, piece(:,:,:,:));
            strip=[];
            strip=cakeLabels(k,:);
            trainLabels=[trainLabels strip];
        
        end
        
        validationSet(:,:,:,:)=sliceOfCake(ii,:,:,:,:);
        validationLabels=cakeLabels(ii,:);
        
        patience_step=0;
        minLoss=10000000000;
        
        options = trainingOptions('adam', 'shuffle','every-epoch', 'ValidationData',{validationSet, validationLabels'}, 'plots', 'training-progress', 'OutputNetwork','best-validation-loss', 'ValidationPatience', patience, 'initialLearnRate', 0.001, 'learnRateSchedule', 'none');

        [net, info] = trainNetwork(trainSet,trainLabels',layers_training,options);
      
        delete(findall(0));
        
        savDir='D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\netsMineCompl';

        netName=['net-', num2str(patience), '-', num2str(ii), '.mat']; 

        save(fullfile(savDir,netName),'net');          
        
        clear layers_training;

               
    end
        
     
end
