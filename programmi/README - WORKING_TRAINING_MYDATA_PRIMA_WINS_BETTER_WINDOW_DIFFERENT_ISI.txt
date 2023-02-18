%%   ISTRUZIONI PER IL PROGRAMMA DI ADDESTRAMENTO DELLA RETE TRAMITE I DATI RACCOLTI
%%   
%%   Questo non è il programma, ma la descrizione dei vari componenti del programma e come essi interagiscono.
%%   Sono state omesse le linee di codice di pura reinizializzazione dei parametri, poiché non necessitano di spiegazione.
%%   Elementi ripetuti nelle varie funzioni sono stati spiegati una volta sola.
%%   L'ordine delle funzioni e delle operazioni è stato mantenuto.
%%   
%%   Il programma carica uno alla volta i trials.
%%   Su ciascuno viene svolto il preprocessing come presentato nella tesi:
%%   filtraggio, winsorizzazione, rescaling, trasformazione della matrice di dati, creazione delle finestre, associazione delle finestre con i labels (1 per la freccia corrispondente al target, 0 per le altre).
%%   Successivamente le finestre dei vari trials vengono raggruppate assieme e viene fatto oversampling: le finestre con label 0 sono tre volte quelle con label 1, dunque quelle con label 1 vengono copiate più volte per pareggiare le quantità. 
%%   Questo per evitare sbilanciamenti nell'addestramento, in cui la rete viene addestrata a riconoscere meglio un tipo di segnali e meno un altro.
%%   Le finestre vengono rimescolate in ordine casuale, poi vengono divise: 70% per gruppo di training, 30% per gruppo di test.
%%   La rete viene addestrata con 10-fold cross-validation, utilizzando 3 patience diverse per controllare se ci sono variazioni (il risultato è che non è necessario).
%%   Le varie reti vengono salvate in una cartella per poter poi essere testate con il rimanente 30% dei dati.
%%
%%   I nomi delle cartelle e delle reti coincidono tra i vari programmi, quindi bisogna ricordarsi di cambiare ovunque.
 


%-------------------------------------------------------------------------

clear

myFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\dati_miei_buoni';
%In questa cartella vanno inseriti i dati



filePattern = fullfile(myFolder, '*.mat'); 
filenames = dir(filePattern);
%La lista dei nomi dei file di dati




D=designfilt('bandpassiir', 'FilterOrder', 8, 'PassbandFrequency1', 1, 'PassbandFrequency2', 12, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);
%Il filtro per il preprocessing



no=0;
%In caso serva togliere una parte iniziale di campioni, questo è il numero di campioni che si vogliono rimuovere




for k = 1 : length(filenames)
%Il loop in cui viene effettuato il preprocessing di ciascun file di dati



    partial_data=[];
    dataset_resc=[];
    baseFileName = filenames(k).name;
    fullFileName = fullfile(filenames(k).folder, baseFileName);
    fprintf(1, 'Preprocessing %s\n', fullFileName);
    load(fullFileName)
    %Il file viene caricato



    resto=mod(length(flashSeq), 4);

    flashSeqCorr=flashSeq(:, 1+no:length(flashSeq)-resto-4); 
    %Con questo sistema la sequenza di flash ha sempre lunghezza multipla di 4. Questo perché non è detto che l'ultimo loop di un'acquisizione sia completo, quindi potrebbe non avere flash e dati sufficienti, dunque viene scartato.



    labels=-ones(1,length(flashSeqCorr));    
    labels(flashSeqCorr(2,:)==target)=1;
    %Definizione dei labels a partire dalle frecce target



    startingPoint=find(EEGsamples(9, :)==flashSeqCorr(1,1));  
    dataset=EEGsamples(:,startingPoint:end); 
    %I dati da utilizzare devono cominciare in corrispondenza del primo flash. Questo sistema confronta l'istante di tempo del primo flash con i tempi dei vari campioni, e rimuove la parte precedente.
    %Questa è una misura di sicurezza.



    dataset_filt= transpose(filtfilt(D, transpose(dataset(1:8, :))));   
    %filtraggio con D. Attenzione che la nona riga contiene tempi, su di essa non va fatto preprocessing



    dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);
    %winsorising. Fatto prima di rescaling per evitare che l'operazione di rescaling sia condizionata da eventuali outlier



    for i=1:8 
     
        dataset_resc(i,:) =  rescale(dataset_wins(i,:),-1,1);                 

    end  
    %rescaling dell'ampiezza nell'intervallo [-1, 1]




    timestamps=dataset(9, 1:10:end);
    dataset_subs=dataset_resc(:, 1:10:end);
    dataset_timed=cat(1, dataset_subs, timestamps);
    %subsampling a 25 campioni/sec, sia dei campioni sia dei tempi. Il risultato è di nuovo una matrice con 9 righe.



    for j = 1:length(labels)
        timeposition=flashSeqCorr(1, j);
        dist=abs(dataset_timed(9,:)-timeposition);
        minDist=min(dist);
        timeIndex=find(dist==minDist);

        window=dataset_subs(1:8, timeIndex(1):timeIndex(1)+24); 

        partial_data=cat(2, partial_data, window);
    end
    %creazione dell'array che in seguoti verrà tagliato in finestre. Alcuni dati e tempi si ripeteranno, in quanto le finestre devono essere sovrapposte di 200ms.



    partial_labels=[partial_labels, labels];
    %concatenazione dell'array di labels per queste finestre a quello complessivo
	



    clear EEGsamples flashSeq target valid;
    
 

    trials=zeros(length(labels), 8, 25);

    for i=1:length(labels)
        trials(i,:,:)=partial_data(:, 1+25*(i-1):25*i);   
        tot_trials=cat(1, tot_trials, trials(i,:,:));
    end
    %creazione dell'array contenente le singole finestre. Sono i finestre 8x25



end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% QUESTA SECONDA PARTE è STATA AGGIUNTA PER SEPARARE I DATASET CONTENENTI DATI BUONI DA QUELLI CONTENENTI DATI PRESI CON IL RUMORE DEL DRONE IN VOLO (VEDI TESI).
%% SE NON CI SONO CONDIZIONI O TIPOLOGIE DIVERSE DI DATI, QUESTA PARTE PUò ESSERE OMESSA
%% QUESTA PARTE è IDENTICA ALLA PRECEDENTE

myFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\data_with_drone_noise'; % dati aggiuntivi

filePattern = fullfile(myFolder, '*.mat'); 
filenames = dir(filePattern);

for k = 1 : length(filenames)
    partial_data=[];
    dataset_resc=[];
    baseFileName = filenames(k).name;
    fullFileName = fullfile(filenames(k).folder, baseFileName);
    fprintf(1, 'Preprocessing %s\n', fullFileName);
    load(fullFileName)


    resto=mod(length(flashSeq), 4);

    flashSeqCorr=flashSeq(:, 1+no:length(flashSeq)-resto-4); 

    labels=-ones(1,length(flashSeqCorr));    
    labels(flashSeqCorr(2,:)==target)=1;

    startingPoint=find(EEGsamples(9, :)==flashSeqCorr(1,1));
   
    dataset=EEGsamples(:,startingPoint:end); %rimuovo la prima parte

    dataset_filt= transpose(filtfilt(D, transpose(dataset(1:8, :))));  
    dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);
   

    for i=1:8  
     
        dataset_resc(i,:) =  rescale(dataset_wins(i,:),-1,1);                 

    end  



    timestamps=dataset(9, 1:10:end);
    dataset_subs=dataset_resc(:, 1:10:end); %25 campioni/sec

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

    %Qui viene costruito l'array con tutte le finestre trasformate in matrici 4x25x3, che verranno date alla rete, e i corrispettivi labels



% save('TrialsMine.mat', 'training_trials');
% save('LabelsMine.mat', 'training_labels');
% save('TrialsMine_buoni.mat', 'training_trials');
% save('LabelsMine_buoni.mat', 'training_labels');
% save('TrialsMine_completi.mat', 'training_trials');
% save('LabelsMine_completi.mat', 'training_labels');
%save('TrialsMine_rumore.mat', 'training_trials');
%save('LabelsMine_rumore.mat', 'training_labels');
%Finestre e labels vengono salvati in due file. Questi sono i nomi usati durante i vari addestramenti.





%--------oversampling------------------------------------------------------
%In questa parte di programma viene effettuato l'oversampling. 

% ttt=load('TrialsMine.mat');
% ttl=load('LabelsMine.mat');
% ttt=load('TrialsMine_buoni.mat');
% ttl=load('LabelsMine_buoni.mat');
% ttt=load('TrialsMine_completi.mat');
% ttl=load('LabelsMine_completi.mat');
%ttt=load('TrialsMine_rumore.mat', 'training_trials');
%ttl=load('LabelsMine_rumore.mat', 'training_labels');

training_trials=ttt.training_trials;
training_labels=ttl.training_labels;
%I dati pronti vengono caricati. 
%In caso si vogliano usare dati diversi, o in caso il preprocessing sia già stato fatto una volta e si vogliano solo variare parametri dell'addestramento
%è sufficiente commentare tutta la parte precedente del programma e caricare i dati da qui.



index=[1:1:length(training_labels); training_labels];
%Indice per le posizioni delle finestre nell'array



rng(0)
[G,classes] = findgroups(training_labels);
numObservations = splitapply(@numel,training_labels,G);
desiredNumObservationsPerClass = max(numObservations);
new_index = splitapply(@(x){randReplicateFiles(x,desiredNumObservationsPerClass)},index(1,:),G);
new_index = new_index(randperm(length(new_index)));
%Questo fornisce un nuovo array di posizioni, contenente repliche degli indici precedenti



newtrials=cat(4, training_trials(:,:,:,new_index{1,1}), training_trials(:,:,:,new_index{1,2}));
clear training_trials;
training_trials=newtrials;
%Il nuovo array di finestre

newlabels=cat(2, training_labels(new_index{1,1}), training_labels(new_index{1,2}));
clear training_labels;
training_labels=newlabels;
%Il nuovo array di labels



reord=[1:1:length(training_labels)];

reord = reord(randperm(length(reord)));

training_trials=training_trials(:,:,:,reord);
training_labels=training_labels(reord);
%Entrambi gli array vengono riordinati in maniera random 




% save('DataForTrainingExpandedMine.mat', 'training_trials', 'training_labels');
% save('DataForTrainingMine_buoni.mat', 'training_trials', 'training_labels');
% save('DataForTrainingMine_completi.mat', 'training_trials', 'training_labels');
%save('DataForTrainingMine_rumore.mat', 'training_trials', 'training_labels');

%----------------------------------------------------------------------------

a=find(training_labels== -1);
training_labels1=training_labels;
training_labels1(a)=0;
training_labels1=categorical(training_labels1);
%Labels per l'addestramento. Devono essere categorical per poter essere utilizzate nell'addestramento, poiché verranno confrontate con gli output della rete che sono appunto categorical.


rng(42);
%Questo serve come seed per la suddivisione dei dati. Se viene ripetuto sia preprocessing che oversampling, può essere omesso.

data_index=randperm(length(training_trials));

% save('indexMine.mat', 'data_index');
% save('indexMine_buoni.mat', 'data_index');
% save('indexMine_completi.mat', 'data_index');
%save('indexMine_rumore.mat', 'data_index');
%Questo sarà l'indice con cui in seguito i dati verranno suddivisi in training e test. 
%Bisogna salvarlo per poterlo fornire anche ai programmi successivi.
%Altrimenti non c'è modo di recuperare la suddivisione corretta. 




%------------------------------------------

separation_test=floor(length(data_index)*0.7);

index_training=data_index(1:separation_test);
index_test=data_index((separation_test+1):end);
training_dataset=training_trials(:,:,:,index_training);
labelsTraining=training_labels1(index_training);
test_dataset=training_trials(:,:,:,index_test);
labelsTest=training_labels1(index_test);
%Questa è la suddivisione dei dati in training (70%) e test (30%). 




for sep=1:10
    
    knife=floor(length(training_dataset)*0.1);
    sliceOfCake(sep,:,:,:,:)=training_dataset(:,:,:,(1+(sep-1)*knife):(sep*knife));
    cakeLabels(sep,:)=labelsTraining((1+(sep-1)*knife):(sep*knife));
    
end
%Questa è la suddivisione in 10 parti per poter effettuare 10-fold cross-validation


%--------------------------------------------------------------------
%Questa è la sezione di addestramento. Il loop viene fatto sulle varie patience e sulle varie suddivisioni di k-fold. 
%Otteniamo in totale 30 reti.


for patience=10:10:30

    for ii=1:10 %10-fold

%%%
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
%%%
%La rete viene ricostruita ad ogni loop per avere sempre pesi reinizializzati 

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
        %Creazione dei set di training e validation, utilizzando di volta in volta 9 dei blocchi in cui i dati sono stati suddivisi, per training, e il rimanente per validation.

        
        patience_step=0;
        minLoss=10000000000;
        
        options = trainingOptions('adam', 'shuffle','every-epoch', 'ValidationData',{validationSet, validationLabels'}, 'plots', 'training-progress', 'OutputNetwork','best-validation-loss', 'ValidationPatience', patience, 'initialLearnRate', 0.001, 'learnRateSchedule', 'none');
	%Opzioni dell'addestramento



        [net, info] = trainNetwork(trainSet,trainLabels',layers_training,options);
	%Funzione di training della rete


      
        delete(findall(0));


        
%         savDir='D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\netsMine';
%         savDir='D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\netsMineCompl';
%         savDir='D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\netsMineRumore';

         
        netName=['net-', num2str(patience), '-', num2str(ii), '.mat']; 
	%creazione del nome della rete
        save(fullfile(savDir,netName),'net');          
        
        clear layers_training;
               
    end
        
end



