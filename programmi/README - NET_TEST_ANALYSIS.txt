%%   ISTRUZIONI PER IL PROGRAMMA DI TEST DELLE RETI OTTENUTE
%%   
%%   Questo non è il programma, ma la descrizione dei vari componenti del programma e come essi interagiscono.
%%   Sono state omesse le linee di codice di pura reinizializzazione dei parametri, poiché non necessitano di spiegazione.
%%   Elementi ripetuti nelle varie funzioni sono stati spiegati una volta sola.
%%   L'ordine delle funzioni e delle operazioni è stato mantenuto.
%%   
%%   Il programma carica i dati precedentemente salvati e ricava il 30% rimanente come dati di test
%%   Ciascuna rete viene utilizzata per classificare i dati di test. 
%%   Per ciascuna viene calcolato MSE.
%%   La rete con MSE minore viene selezionata come la migliore e salvata.







% data=load('index.mat');
% data=load('indexMine.mat');
% data=load('indexMine_buoni.mat');
% data=load('indexMine_completi.mat');
% data=load('indexMine_rumore.mat');
index=data.data_index;
%Questo è l'indice già usato per suddividere i dati per l'addestramento



% training_data=load('DataForTrainingExpanded.mat', 'training_trials', 'training_labels');
% training_data=load('DataForTrainingExpandedMine.mat', 'training_trials', 'training_labels');
% training_data=load('DataForTrainingMine_buoni.mat', 'training_trials', 'training_labels');
% training_data=load('DataForTrainingMine_completi.mat', 'training_trials', 'training_labels');
% training_data=load('DataForTrainingMine_rumore.mat', 'training_trials', 'training_labels');
trials=training_data.training_trials;
labels=training_data.training_labels;
%Questi sono i dati usati


%--------------------------------------------------------------------------

a=find(labels== -1);
training_labels=labels;
training_labels(a)=0;
%Ridefinizione delle labels. In realtà si poteva già fare nel programma precedente.

%-----------------------------------------------------------------------



separation_test=floor(length(index)*0.7);


index_test=index((separation_test+1):end);

test_dataset=trials(:,:,:,index_test);
labelsTest=labels(index_test);
%Definizione dei dati di test




minMse=100000000;




%  netFolder = 'D:\Users\206180-favaro\Documents\MATLAB\Unicorn\goodNetsThem'; % Folder for nets to test
%  netFolder = 'D:\Users\206180-favaro\Documents\MATLAB\Unicorn\goodNetsMine'; % Folder for nets to test
%  netFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\netsMine'; % Folder for nets to test
%  netFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\netsMineCompl'; % Folder for nets to test
%  netFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\netsMineRumore'; % Folder for nets to test
%Queste sono cartelle dove sono state salvate le reti ottenute tramite il programma precedente.



filePattern = fullfile(netFolder, '*.mat'); 
filenames = dir(filePattern);
%Elenco delle reti nella cartella


truelabel=labelsTest;




MSEarray=zeros(1, length(filenames));




for k = 1 : length(filenames)
%Il loop viene fatto su ciascuna rete

    baseFileName = filenames(k).name;
    fullFileName = fullfile(filenames(k).folder, baseFileName);
    Network=load(fullFileName);
   

   
    examinedNet=Network.net;
    
    y= classify(examinedNet, test_dataset);
    %La rete viene usata per classificare i dati di test


    
    for i=1:length(y)
        
        if y(i)==categorical(1)
            classifiedLabels(i)=1;
        else
            classifiedLabels(i)=0;
        end
        
    end
    %Le classi ottenute vengono trasformate in numeri interi. 
    %Questo perché per calcolare MSE non si possono usare categorical.


    
    perf = immse(truelabel,classifiedLabels);
    MSEarray(k)=perf;
    %MSE calcolato tramite la funzione immse
    
    if perf<minMse
        minMse=perf;
        bestNet=fullFileName;
        minMse

%  save('bestNetMine.mat', 'examinedNet');
%  save('bestNetMineNewPrepCorrWind.mat', 'examinedNet');
%  save('bestNetMineNewPrepCorrWind_buona.mat', 'examinedNet');
%  save('bestNetMineNewPrepCorrWind_completa.mat', 'examinedNet');
% save('bestNetMineNewPrepCorrWind_rumore.mat', 'examinedNet');
%La rete con MSE migliore viene salvata
    end
        
  
end

bestNet
%Semplicemente scrive a schermo qual è la ret scelta
