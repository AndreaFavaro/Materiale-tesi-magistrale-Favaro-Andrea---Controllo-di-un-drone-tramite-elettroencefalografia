%%   ISTRUZIONI PER IL PROGRAMMA DI TEST DELLE RETI OTTENUTE
%%   
%%   Questo non è il programma, ma la descrizione dei vari componenti del programma e come essi interagiscono.
%%   Sono state omesse le linee di codice di pura reinizializzazione dei parametri, poiché non necessitano di spiegazione.
%%   Elementi ripetuti nelle varie funzioni sono stati spiegati una volta sola.
%%   L'ordine delle funzioni e delle operazioni è stato mantenuto.
%%   
%%   Questo programma viene utilizzato per valutare la qualità dello speller.
%%   Carica uno alla volta tutti i trials che vengono forniti nella cartella di riferimento (devono essere dati diversi da quelli di training e test).
%%   Viene fatto preprocessing e i dati vengono passati alla rete in cicli da 4 flash e classificati.
%%   I risultati vengono accumulati in 4 bin, come nello speller vero.
%%   A questo punto ci sono due modalità:
%%   -nella prima la richiesta è di continuare ad accumulare nei bin fino a quando la risposta corretta non diventa quella corrispondente a target del trial.7
%%    Ciò permette di calcolare quanti cicli servono per ottenere la risposta corretta.
%%   -nella seconda invece si specifica un numero minimo di cicli, ed il sistema fornisce la risposta in base a quale bin ha valore massimo dopo almeno quel numero di cicli (o maggiore in caso di parità).
%%    Ciò permette di verificare le risposte dello speller, calcolando l'accuracy come numero di risposte corrette su numero di risposte totali (vedi accuracy.xlsx allegato). 




clear

% myFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\dati_conteggio_buoni'; 
%Cartella con i dati



filePattern = fullfile(myFolder, '*.mat'); 
filenames = dir(filePattern);



D=designfilt('bandpassiir', 'FilterOrder', 8, 'PassbandFrequency1', 1, 'PassbandFrequency2', 12, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);



net=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrepCorrWind_completa.mat');
NN=net.examinedNet;
%Rete da utilizzare



for k = 1 : length(filenames)
%I dati da analizzare vengono presi un trial alla volta
 
    baseFileName = filenames(k).name;
    fullFileName = fullfile(filenames(k).folder, baseFileName);
    fprintf(1, '%s\n', fullFileName);
    dataset=load(fullFileName);

    partials=dataset.partials; 
    eeg=dataset.EEGsamplesCut;

    labels=dataset.flashSeq;

    target=dataset.target;
    flashAnalisi=dataset.flashAnalisi;

    takeoff=dataset.takeoff;
    binbin=dataset.binbin;

   

    cicli=0;
    %Il conteggio di quanti cicli sono necessari
    bin=[0 0 0 0];
    binbinbin=[];



    for min=4:11
%     min=8;
    %In questo caso si vogliono provare più valori per il numero minimo di cicli per avere una risposta, qualunque essa sia. 
    %Se invece si vuole verificare quanti cicli servono per avere la risposta corretta, min non viene utilizzato, quindi il for può essere commentato (sarebbero for loop identici).
    %Per praticità si può anche commentare il for e imporre un min manualmente (in questo caso 8), in maniera da fare i calcoli solo per il caso richiesto.


        cicli=0;
        bin=[0 0 0 0];

        quantity=0;
        errori=0;
        delay=0;



        for num=1:length(binbin)
	%binbin contiene già i bin in righe da 4 elementi l'una, dunque la lunghezza di binbin è pari al numero totale di cicli effettuati nel trial

%          for num=1:50 %per flashSequence15-Sep-2022-170308 (può succedere che alcuni trial non siano completi (l'ultimo ciclo non contiene 850 campioni per canale), nel qual caso arrivare fino in fondo darebbe errore. In questi casi va specificato a mano il range) 

            trials=zeros(4, 8, 25);

            flashes=flashAnalisi(2, 1+4*(num-1): 4+4*(num-1));

            dataset_filt= transpose(filtfilt(D, transpose(partials(1+9*(num-1):8+9*(num-1), :))));   
	    %I flash vanno presi a blocchi di 4 finestre con i corrispettivi labels, per avere un ciclo.




            dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);

	    dataset_resc(1,:) =  rescale(dataset_wins(1,:),-1,1); 
	    dataset_resc(2,:) =  rescale(dataset_wins(2,:),-1,1); 
	    dataset_resc(3,:) =  rescale(dataset_wins(3,:),-1,1); 
	    dataset_resc(4,:) =  rescale(dataset_wins(4,:),-1,1); 
	    dataset_resc(5,:) =  rescale(dataset_wins(5,:),-1,1); 
	    dataset_resc(6,:) =  rescale(dataset_wins(6,:),-1,1); 
	    dataset_resc(7,:) =  rescale(dataset_wins(7,:),-1,1); 
	    dataset_resc(8,:) =  rescale(dataset_wins(8,:),-1,1); 

            dataset_subs=dataset_resc(:, 1:10:end); 

	    trials(1,:,:)=dataset_subs(:, 1:25);
	    trials(2,:,:)=dataset_subs(:, 21:45);
	    trials(3,:,:)=dataset_subs(:, 41:65);
	    trials(4,:,:)=dataset_subs(:, 61:85);

            M=zeros(4,25,3,4);

            for z = 1:4
                M(2,:,1,z)=trials(z, 1,:);
                M(4,:,1,z)=trials(z, 2,:);       
                M(3,:,2,z)=trials(z, 3,:);
                M(4,:,2,z)=trials(z, 4,:);
                M(4,:,3,z)=trials(z, 5,:);
                M(2,:,3,z)=trials(z, 6,:);
                M(1,:,2,z)=trials(z, 7,:);
                M(2,:,2,z)=trials(z, 8,:);
            end
	    %Preprocessing fatto come nel programma dello speller



            p= classify(NN,M);

            y=str2double(cellstr(p));
            t=y==1;

            s=flashes(t);
            bin(s)=bin(s)+1;
            binbinbin=[binbinbin;bin];
            cicli=cicli+1;
            %Come nello speller, i bin vengono accumulati e i cicli contati.
        

%             if  (length(find(bin==max(bin)))==1) && (find(bin==max(bin))==target)
            if  (length(find(bin==max(bin)))==1) && (cicli>=min)
            %Qui bisogna scegliere quale if usare: il primo per contare il numero di cicli per avere la risposta corretta, il secondo se si ha imposto un numero minimo di cicli (per il calcolo dell'accuracy, vedi introduzione)


           
                fprintf('%d con %d; ',find(bin==max(bin)), cicli);
		%La risposta dello speller e quanti cicli sono stati necessari

                quantity=quantity+1;

                if find(bin==max(bin))~= target

                    errori=errori+1;

                end

                if cicli > min

                    delay=delay+1;

                end

                cicli=0;
                bin=[0 0 0 0];
            
            end



        end

        fprintf('\n');


        fprintf('quantità= %d, errori= %d, delay=%d',quantity, errori, delay);
	%quantity è il numero di risposte date in un singolo trial, dunque il numero di comandi che lo speller darebbe al drone. Dipende dal numero di cicli per risposta.
	%errori conta il numero di risposte errate (il bin di valore massimo non coincide col target). In caso si esiga la risposta corretta, questo valore è chiaramente nullo.
	%delay indica quante volte il numero di cicli per dare una risposta ha superato il numero minimo di cicli richiesto. In caso si esiga la risposta corretta, questo valore non ha significato.
        fprintf('\n');

    end

    fprintf('\n');  

end