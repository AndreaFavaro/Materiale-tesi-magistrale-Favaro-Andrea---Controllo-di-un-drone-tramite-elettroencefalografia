clear


net=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrepCorrWind_completa.mat');

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
labelsTest=training_labels(index_test);


training_labels1=categorical(labelsTest);

y= classify(net.examinedNet,test_dataset);
    
confChart=confusionchart(training_labels1',y);
confValues=confMatrixValues(training_labels1', y);




%--------------------------------------------------------------------------
%----------------------PER TESTARE SU NUOVI DATI---------------------------
%-----------------IN QUESTO CASO UN TRIAL ALLA VOLTA-----------------------
%--------------------------------------------------------------------------

% partial_data=[];
% partial_labels=[];
% tot_trials=[];
% load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\dati_miei_buoni\flashSequence06-May-2022-143750.mat');
% D=designfilt('bandpassiir', 'FilterOrder', 8, 'PassbandFrequency1', 1, 'PassbandFrequency2', 12, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);
% 
% 
% no=0;
% 
% resto=mod(length(flashSeq), 4);
% 
% flashSeqCorr=flashSeq(:, 1+no:length(flashSeq)-resto-4); 
%
% labels=zeros(1,length(flashSeqCorr));    
% labels(flashSeqCorr(2,:)==target)=1;
% 
% 
% 
% startingPoint=find(EEGsamples(9, :)==flashSeqCorr(1,1));
%    
% dataset=EEGsamples(:,startingPoint:end); %rimuovo la prima parte
% 
%    
% 
% dataset_filt= transpose(filtfilt(D, transpose(dataset(1:8, :))));   %filter data with filter D
% 
% dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);
%    
% 
% for i=1:8  %rescaling amplitude bewteen [-1, 1]
%      
%     dataset_resc(i,:) =  rescale(dataset_wins(i,:),-1,1);                 
% 
% end  
% 
% 
% 
% timestamps=dataset(9, 1:10:end);
% dataset_subs=dataset_resc(:, 1:10:end);
% 
% dataset_timed=cat(1, dataset_subs, timestamps);
% 
% 
% for j = 1:length(labels)
%     timeposition=flashSeqCorr(1, j);
%     dist=abs(dataset_timed(9,:)-timeposition);
%     minDist=min(dist);
%     timeIndex=find(dist==minDist);
%
%     window=dataset_subs(1:8, timeIndex(1):timeIndex(1)+24); %finestre da 25
% 
%     partial_data=cat(2, partial_data, window);
%
% end
% 
% partial_labels=[partial_labels, labels];
%     
%     
% 
% trials=zeros(length(labels), 8, 25);
% 
% for i=1:length(labels)
% 
%     trials(i,:,:)=partial_data(:, 1+25*(i-1):25*i);   
%     
%     tot_trials=cat(1, tot_trials, trials(i,:,:));
%
% end
% 
% 
% 
% M=zeros(4,25,3,length(partial_labels));
% 
% for z = 1:length(partial_labels)
%     M(2,:,1,z)=tot_trials(z, 1,:);
%     M(4,:,1,z)=tot_trials(z, 2,:);       
%     M(3,:,2,z)=tot_trials(z, 3,:);
%     M(4,:,2,z)=tot_trials(z, 4,:);
%     M(4,:,3,z)=tot_trials(z, 5,:);
%     M(2,:,3,z)=tot_trials(z, 6,:);
%     M(1,:,2,z)=tot_trials(z, 7,:);
%     M(2,:,2,z)=tot_trials(z, 8,:);
% end
% 
%     
% training_labels1=categorical(partial_labels);
% 
% y= classify(net.examinedNet,M);
%   
% confChart=confusionchart(training_labels1',y);
% confValues=confMatrixValues(training_labels1', y);
% 
