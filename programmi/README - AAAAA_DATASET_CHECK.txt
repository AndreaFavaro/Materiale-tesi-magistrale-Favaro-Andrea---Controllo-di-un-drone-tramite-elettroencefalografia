%%   ISTRUZIONI PER IL PROGRAMMA DI VISUALIZZAZIONE DEL P300 ALL'INTERNO DEI DATI
%%   
%%   Questo non è il programma, ma la descrizione dei vari componenti del programma e come essi interagiscono.
%%   Sono state omesse le linee di codice di pura reinizializzazione dei parametri, poiché non necessitano di spiegazione.
%%   Elementi ripetuti nelle varie funzioni sono stati spiegati una volta sola.
%%   L'ordine delle funzioni e delle operazioni è stato mantenuto.
%%   
%%   Questo programma carica i dati di un trial ed effettua il preprocessing, eccezion fatta per il sottocampionamento.
%%   Vengono effettuate la media delle finestre in cui ha lampeggiato la freccia target (in cui dovrebbe essere presente il P300)
%%   e la media delle altre finestre (in cui non dovrebbe essere presente).
%%   In questo modo è possibile visualizzare la forma del P300 e valutare la bontà del trial, per valutare se includerlo nell'addestramento o meno.
%%   Un trial è stato considerato buono se:
%%   -la forma del P300 è ben distinguibile nella media delle finestre target (il picco dev'essere di minimo 0.4, meglio 0.6)
%%   -la media delle finestre non-target è molto più bassa del picco del P300, e se si nota una forma simile dev'essere molto più bassa (massimo 0.2). 




clear 



dataset=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\flashSequence23-Sep-2022-154315.mat');
%un dataset


eeg=dataset.EEGsamplesCut;
labels=dataset.flashSeq;
target=dataset.target;


ISI=0.8;

no=0;
%in caso serva tagliare una parte iniziale di campioni




D=designfilt('bandpassiir', 'FilterOrder', 8, 'PassbandFrequency1', 1, 'PassbandFrequency2', 12, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);
%il filtro




resto=mod(length(labels), 4);
labelsCorr=labels(:, 1+no:length(labels)-resto-4); 
%così è divisibile per 4 e salto l'ultima fetta che potrebbe dare problemi se non è completa




startingPoint=find(eeg(9, :)==labelsCorr(1,1));
dataset=eeg(:,startingPoint:end); 
%viene definito il punto di partenza nel trial


 
x=1:1:250;



binGood=zeros(8, 250);
binBad=zeros(8, 250);
bgcount=0;
bbcount=0;




dataset_filt= transpose(filtfilt(D, transpose(dataset(1:8, :))));   

dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);

for i=1:8  
     
    dataset_resc(i,:) =  rescale(dataset_wins(i,:),-1,1);                 

end  
%preprocessing



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
%suddivisione delle finestre. Le target vengono accumulate in binGood, le non-target in binBad.

binGood=binGood/bgcount;
binBad=binBad/bbcount;
%le medie delle finestre. 




figure(5)
plot(x, binGood(1:8, :))
figure(6)
plot(x, binBad(1:8, :))
%le medie vengono plottate





