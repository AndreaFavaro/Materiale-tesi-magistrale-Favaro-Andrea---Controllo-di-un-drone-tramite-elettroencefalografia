L'ordine dei programmi è il seguente:

WORKING HEADSET CONTROL FUNZIONANTE
è il programma sia di acquisizione dati che di controllo del drone. Può essere usato solo per la raccolta o anche per il pilotaggio.
Contiene la GUI, il collegamento al programma Simulink, il classificatore e i comandi da inviare al drone.
I dati prelevati vengono sempre salvati. Per raccogliere dati per l'addestramento basta disabilitare il drone.

AAAAA_DATASET_CHECK
è il programma che permette di valutare la bontà dei dati prelevati, per decisere se includerli o meno nell'addestramento.

WORKING_TRAINING_MYDATA_PRIMA_WINS_BETTER_WINDOW_DIFFERENT_ISI
è il programma di training della rete.
I dati raccolti dal primo programma in modalità di semplice acquisizione vengono utilizzati per addestrare la CNN da usare come classificatore.
Addestramento con 10-fold cross validation.

NET_TEST_ANALYSIS
è il programma che determina quale delle reti addestrate dal programma precedente è la migliore.

TESTING_BEST_NET_2
è il programma per calcolare le prestazioni della rete (accuracy, precision, recall, f-score) e la confusion matrix.

conteggio_cicli_automatico
è il programma per misurare per quanti cicli lo speller deve operare per poter dare una risposta corretta su un determinato trial.
Accumulando queste risposte è possibile calcolare l'accuracy dello speller (vedi accuracy.xlsx)

bestNetMineNewPrepCorrWind_completa
è la rete già addestrata.

readingP300_corr.slx
è il programma Simulink per la raccolta dati.






