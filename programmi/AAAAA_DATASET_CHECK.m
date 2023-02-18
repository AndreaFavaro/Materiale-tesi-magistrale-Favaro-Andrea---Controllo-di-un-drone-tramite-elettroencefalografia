

clear 

dataset=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\flashSequence23-Sep-2022-154315.mat');


eeg=dataset.EEGsamplesCut;
labels=dataset.flashSeq;
target=dataset.target;


ISI=0.8;
no=0;
D=designfilt('bandpassiir', 'FilterOrder', 8, 'PassbandFrequency1', 1, 'PassbandFrequency2', 12, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);



resto=mod(length(labels), 4);

labelsCorr=labels(:, 1+no:length(labels)-resto-4); 

labelsGood=-ones(1,length(labelsCorr));    


startingPoint=find(eeg(9, :)==labelsCorr(1,1));
   
dataset=eeg(:,startingPoint:end); 

x=1:1:250;



%-----------WINSORIZATION -> RESCALE-----------     

binGood=zeros(8, 250);
binBad=zeros(8, 250);
bgcount=0;
bbcount=0;


dataset_filt= transpose(filtfilt(D, transpose(dataset(1:8, :))));   %filter data with filter D





dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);

for i=1:8  
     
    dataset_resc(i,:) =  rescale(dataset_wins(i,:),-1,1);                 

end  

for i=1:length(labelsGood)

    time=labelsCorr(1, i);
    pos=find(dataset(9, :)==time);
    trials=dataset_resc(:, pos:250+pos-1); 

    if labelsCorr(2,i)==target
        binGood=binGood+trials;
        bgcount=bgcount+1;
    else
        binBad=binBad+trials;
        bbcount=bbcount+1;
    end
end

binGood=binGood/bgcount;
binBad=binBad/bbcount;


figure(5)
    plot(x, binGood(1:8, :))
figure(6)
    plot(x, binBad(1:8, :))






