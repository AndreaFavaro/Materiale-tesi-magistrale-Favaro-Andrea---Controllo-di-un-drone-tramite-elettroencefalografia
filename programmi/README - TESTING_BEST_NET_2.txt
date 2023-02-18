%%   ISTRUZIONI PER IL PROGRAMMA DI VERIFICA DELLA RETE MIGLIORE
%%   
%%   Questo non è il programma, ma la descrizione dei vari componenti del programma e come essi interagiscono.
%%   Sono state omesse le linee di codice di pura reinizializzazione dei parametri, poiché non necessitano di spiegazione.
%%   Elementi ripetuti nelle varie funzioni sono stati spiegati una volta sola.
%%   L'ordine delle funzioni e delle operazioni è stato mantenuto.
%%   
%%   Il programma carica la rete migliore definita tramite il programma precedente.
%%   Usa i dati di test per calcolare la confusion matrix ed i parametri di accuracy, precision, recall, f-score



clear


% net=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetNewPrep.mat');
% net=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrep.mat');
% net=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrepCorrWind.mat');
% net=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrepCorrWind_buona.mat');
% net=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrepCorrWind_completa.mat');
% net=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrepCorrWind_rumore.mat');



% data=load('index.mat');
% data=load('indexMine.mat');
% data=load('indexMine_buoni.mat');
% data=load('indexMine_completi.mat');
% data=load('indexMine_rumore.mat');


index=data.data_index;

% training_data=load('DataForTrainingExpanded.mat', 'training_trials', 'training_labels');
% training_data=load('DataForTrainingExpandedMine.mat', 'training_trials', 'training_labels');
% training_data=load('DataForTrainingMine_buoni.mat', 'training_trials', 'training_labels');
% training_data=load('DataForTrainingMine_completi.mat', 'training_trials', 'training_labels');
% training_data=load('DataForTrainingMine_rumore.mat', 'training_trials', 'training_labels');


trials=training_data.training_trials;

labels=training_data.training_labels;
%--------------------------------------------------------------------------

a=find(labels== -1);
training_labels=labels;
training_labels(a)=0;


%-----------------------------------------------------------------------

separation_test=floor(length(index)*0.7);


index_test=index((separation_test+1):end);

test_dataset=trials(:,:,:,index_test);
labelsTest=training_labels(index_test);

training_labels1=categorical(labelsTest);
%Fin qui come nel programma precedente




y= classify(net.examinedNet,test_dataset);
    
confChart=confusionchart(training_labels1',y);
confValues=confMatrixValues(training_labels1', y);
%confusionchart è la funzione di Matlab per creare la confusion matrix
%confMatrixValues è una funzione scritta appositamente per calcolare accuracy, precision, recall, f-score



%--------------------------------------------------------------------------
%----------------------PER TESTARE SU NUOVI DATI---------------------------
%--------------------------------------------------------------------------
%In caso si voglia testare la rete ottenuta su nuovi dati, qui è replicato tutto il preprocessing già descritto negli altri programmi, basta solo selezionare i dataset corretti


