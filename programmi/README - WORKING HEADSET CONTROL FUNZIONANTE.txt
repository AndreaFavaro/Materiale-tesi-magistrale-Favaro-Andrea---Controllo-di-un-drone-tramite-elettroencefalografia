%%   ISTRUZIONI PER IL PROGRAMMA DI ACQUISIZIONE DATI E CONTROLLO DRONE
%%   
%%   Questo non è il programma, ma la descrizione dei vari componenti del programma e come essi interagiscono.
%%   Sono state omesse tutte le linee di codice di pura reinizializzazione dei parametri, poiché non necessitano di spiegazione.
%%   Elementi ripetuti nelle varie funzioni sono stati spiegati una volta sola.
%%   L'ordine delle funzioni e delle operazioni è stato mantenuto.
%%   
%%   Il programma crea la GUI e collega le varie funzioni ad un modello Simulink attraverso dei callback. 
%%   La funzione di decollo (Takeoff) inizializza i vari parametri necessari per le funzioni e invia il comando di decollo.
%%   La funzione di atterraggio (Land) invia il comando di atterraggio e salva tutti i dati necessari.
%%   I flash vengono governati dalla funzione flashImage.
%%   L'analisi tramite CNN e l'invio dei comandi vengono effettuati dalla funzione dataAnalysys.
%%   Simulink richiede che il caschetto sia collegato e attivo, in caso contrario cercare di far partire il programma causa errori.
%%   Se usato, il drone dev'essere collegato tramite WiFi prima di far partire il programma.
%%   Caricamento del modello Simulink e collegamento al drone possono richiedere alcuni secondi.



%-------------------------------------------------------------------------

function varargout =WORKING_HEADSET_CONTROL_FUNZIONANTE 
%è la funzione che si occupa di caricare tutto ciò che serve; è la main function.



modelName = 'readingP300_corr' 
%è il nome del modello Simulink. Attenzione che questo usa Matlab2021. 



setappdata 
%è necessario per poter passare i parametri tra le funzioni. In questo caso "0" indica la location di default. 



%Le immagini delle frecce devono essere nella stessa cartella del programma se si vuole utilizzare solo il nome del file.


%p=parrot();
%questo effettua il collegamento al drone. Se il collegamento non avviene è necessario disattivare i firewall. 
   
%setappdata(0, 'drone', p); 
%fprintf('collegamento parrot effettuato\n')
%SE IL PROGRAMMA DEVE ESSERE SOLO ACQUISIZIONE DATI BISOGNA COMMENTARE TUTTE LE ISTANZE DEI COMANDI DEL DRONE
%Se il collegamento non viene effettuato i comandi risulteranno in errori, dunque bisogna ricordarsi di commentarli nelle altre funzioni



ISI=0.8 
%è il periodo dei flash (ISI in questo caso è un termine improprio). In caso serva cambiare periodo basta farlo qua.



D=designfilt('bandpassiir', 'FilterOrder', 8, 'PassbandFrequency1', 1, 'PassbandFrequency2', 12, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);
setappdata(0, 'filter', D);
%Designfilt serve per costruire il filtro.
%Il filtro va costruito qui perché è un'operazione pesante dal punto di vista computazionale, dunque bisogna farla una volta sola



NN=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrepCorrWind_completa.mat');
%Questa è la rete neurale da usare.



bin=[0 0 0 0 ];
flashSequence=randperm(4);
%Bisogna inizializzare i bin e la prima sequenza di flash.



guiCheck = findall(0,'Tag',mfilename);
    if isempty(guiCheck)  %se findall non ha trovato nulla allora la GUI non esiste
        guiCheck = createGUI(modelName);  %quindi la crea
    else  %se invece la trova
        figure(guiCheck); %la mette in primo piano
    end
%La funzione createGui è definita successivamente. 


%-----------------------------------------------------------------------------------------

function figureGUI = createGUI(modelName)
%la funzione per creare la GUI. Non si occupa dell'update, ma solo della creazione.



figureGUI = figure('Tag', mfilename, 'Toolbar', 'none', 'MenuBar', 'none',...
        'IntegerHandle', 'off', 'Units', 'normalized', 'Resize', 'off',...
        'NumberTitle', 'off', 'HandleVisibility', 'callback',...
        'Name', sprintf('Controllo di %s.mdl',modelName),...
        'CloseRequestFcn', @safelyCloseGUI, 'Visible', 'off', 'Resize', 'on', 'Color', '#c0c0c0');
%costruisce la finestra in cui verranno aggiunti i vari elementi. 



%axes per il video
%axVid = axes('Parent', figureGUI, 'HandleVisibility','callback',...
%        'Unit', 'normalized', 'OuterPosition', [0.25 0.25 0.45 0.45],...
%        'Tag', 'videoAxes', 'Color', '#c0c0c0');
%se si volesse riprovare con la webcam, questa è l'area predisposta per lo streaming video



arrowUp=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...  
        'Unit', 'normalized', 'OuterPosition', [0.4 0.86 0.2 0.2],...           
        'cdata', getappdata(0, 'upBlack'), 'Tag', 'flashImgUp', 'BackgroundColor', '#a9a9a9');                
arrowDown=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [0.4 -0.07 0.2 0.2],...
        'cdata', getappdata(0, 'downBlack'), 'Tag', 'flashImgDown', 'BackgroundColor', '#a9a9a9');
arrowLeft=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [-0.08 0.45 0.2 0.2],...
        'cdata', getappdata(0, 'leftBlack'), 'Tag', 'flashImgLeft', 'BackgroundColor', '#a9a9a9');
arrowRight=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [0.88 0.45 0.2 0.2],...
        'cdata', getappdata(0, 'rightBlack'), 'Tag', 'flashImgRight', 'BackgroundColor', '#a9a9a9');
%questo è un sistema molto facile perché utilizzando dei bottoni è sufficiente cambiare i CData per cambiare l'immagine



takeoff=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [0.15 0.2 0.2 0.2],...
        'cdata', getappdata(0, 'takeoffBlack'), 'Tag', 'Takeoff',...
        'Enable', 'on', 'Callback', @takeoffButtonCallback);
land=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [0.65 0.2 0.2 0.2],...
        'cdata', getappdata(0, 'landBlack'), 'Tag', 'Land',...
        'Enable', 'off', 'Callback', @landButtonCallback);
%bottoni di Takeoff e Land



targetSelect = uicontrol('Parent',figureGUI,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0 0.8 0.2 0.2],...
        'String','',...
        'Backgroundcolor',[1 1 1],...
        'Enable','on',...
        'Callback',@chooseTarget,...
        'HandleVisibility','callback',...
        'Tag','choiceTarget', 'BackgroundColor', '#a9a9a9');
%la finestra in cui definire quale freccia si usa durante l'acquisizione dati per training



mp = loadSimulinkModel(modelName); 
%la funzione loadSimulinkModel è definita più avanti. Qui viene chiamata per caricare il modello Simulink



set_param(mp.modelName, 'StopTime', 'inf');
set_param(mp.modelName, 'SimulationMode', 'normal');
%bisogna settare i parametri della simulazione Simulink



set_param(mp.modelName, 'StartFcn', 'addListenersToEvents');
%imposta i listener necessari nella startFcn (definiti successivamente)
    


mp.flashHandlesUp=arrowUp;  
mp.flashHandlesDown=arrowDown;
mp.flashHandlesLeft=arrowLeft;
mp.flashHandlesRight=arrowRight;
mp.handlesTakeoff=takeoff;
mp.handlesLand=land;
%in "mp" vengono memorizzati vari handles per gestire l'interfaccia attraverso le varie funzioni.
%Questi sono quelli dei bottoni 



%     mp.videoHandles=axVid;
%     cameraObj = camera(getappdata(0, 'drone'),'FPV');
%     img=image(zeros(360, 640, 3), 'Parent', mp.videoHandles);
%     img=image(zeros(250, 500, 3), 'Parent', mp.videoHandles);
%     mp.cameraHandle=cameraObj;
%     preview(mp.cameraHandle, img);
%questo è l'handle per lo streaming video della webcam, qualora venisse usata. Preview attiva lo streaming.


    
mp.handles = guihandles(figureGUI);    
%i vari handle della GUI (tutti quelli della Figure)



guidata(figureGUI,mp);     
%memorizza tutti i dati della GUI 
    


movegui(figureGUI,'center')    
%mette la GUI al centro

    

set(figureGUI,'Visible','on'); 
%la GUI diventa visibile una volta impostata
    
 
%--------------------------------------------------------------------------  

function mp = loadSimulinkModel(modelName)
%Impostare e salvare parametri iniziali del modello e altre impostazioni
%per i listeners e callbacks (mp sta per model parameters)



if ~modelIsLoaded(modelName)
    load_system(modelName);
end
%il modello va caricato una volta sola


    
mp.modelName = modelName;
mp.originalStopTime = get_param(mp.modelName, 'Stoptime');
mp.originalStartFcn = get_param(mp.modelName, 'StartFcn');
%parametri da salvare per poterli ripristinare una volta chiuso il programma


   
mp.listenerSettings = struct('blockName', '', 'blockHandle', [],...
    'blockEvent', '', 'blockFcn', []);
%struttura da definire per la costruzione dei listener


    
mp.listenerSettings(1).blockName = sprintf('%s/Digital Clock', mp.modelName);
mp.listenerSettings(2).blockName = sprintf('%s/RAW_EEG1', mp.modelName);
mp.listenerSettings(3).blockName = sprintf('%s/Digital Clock', mp.modelName);
%Nomi 

mp.listenerSettings(1).blockHandle = get_param(mp.listenerSettings(1).blockName, 'Handle');
mp.listenerSettings(2).blockHandle = get_param(mp.listenerSettings(2).blockName, 'Handle');
mp.listenerSettings(3).blockHandle = get_param(mp.listenerSettings(3).blockName, 'Handle');
%Handles

mp.listenerSettings(1).blockEvent = 'PostOutputs';
mp.listenerSettings(2).blockEvent = 'PostOutputs';   
mp.listenerSettings(3).blockEvent = 'PostOutputs';
%Che tipo di eventi triggerano i listener. PostOutputs vuol dire dopo aver aggiornato il blocco con i nuovi valori.
%Lo Scope ha un output grafico, quindi è possibile usare comunque PostOutputs



mp.listenerSettings(1).blockFcn = @flashImage;
mp.listenerSettings(2).blockFcn = @plotEEG;
mp.listenerSettings(3).blockFcn = @dataAnalysys;
%I callback alle funzioni opportune (definite in seguito)


%--------------------------------------------------------------------------

function addListenersToEvents
$aggiunge i listener opportuni in base a cosa è stato definito nella funzione loadSimulinkModel


mp = guidata(gcbo); 
$carica tutto ciò che è stato definito in precedenza in mp



if ~isempty(mp.originalStartFcn)
    evalin('Base',mp.originalStartFcn);
end
%esegue la startFcn originale di Simulink per avviare il modello

   
mp.eventHandle = cell(1,length(mp.listenerSettings));
for idx = 1:length(mp.listenerSettings)
    mp.eventHandle{idx} = add_exec_event_listener(mp.listenerSettings(idx).blockName,...
        mp.listenerSettings(idx).blockEvent, mp.listenerSettings(idx).blockFcn);
end
 %aggiunge i listener sui blocchi



guidata(gcbo,mp);
%memorizza le modifiche fatte


%--------------------------------------------------------------------------

%per controllare che il modello sia caricato

function modelLoaded = modelIsLoaded(modelName)

    try
        modelLoaded = ~isempty(find_system('Type', 'block_diagram', 'Name', modelName));
    catch ME %non so se necessario
        modelLoaded = false;
    end
    
%--------------------------------------------------------------------------


function takeoffButtonCallback(hObject,~) 
%Callback function del bottone Takeoff
%Questa funzione avvia la raccolta dati, le sequenze di flash, e fa decollare il drone
%Nota che Takeoff è un bottone, ma nel caso in cui venisse inserito un bottone Start per avviare semplicemente il programma il decollo potrebbe essere inserito come ulteriore comando dello speller. 
%Stessa considerazione vale per il bottone Land.
%In questo caso è stato scelto di fare così per evitare problemi di perdita di sincronia, poiché separare l'avvio della simulazione dall'inizio dei flash dava problemi per i primi secondi del decollo.



if ~modelIsLoaded(mp.modelName) 
    load_system(mp.modelName);
end
%ridondante, ma per sicurezza



set_param(mp.modelName, 'SimulationCommand', 'start');
%avvia la simulazione


%numerosi parametri usati nelle funzioni vengono inizializzati al loro valore di partenza tramite i setappdata
%perché in caso di atterraggi e decolli multipli è necessario avere tutto reinizializzato
 


flashSequence=randperm(4);    
%anche la sequenza
    


set(mp.handles.Takeoff,'Enable','off');
set(mp.handles.Land,'Enable','on');
%disabilita il pulsante Takeoff e abilita il pulsante Land



setappdata(0, 'flight', 1);     
%questa flag segnala che il drone è in volo, per abilitare i flash. 
%I flash vanno disabilitati con il drone a terra per evitare di mandare comandi inutili



handleName=sprintf('%s/Digital Clock', mp.modelName); 
runTimeTime = get_param(handleName,'RunTimeObject'); 
timeData=get(runTimeTime.OutputPort(1));
time=timeData.Data;
setappdata(0, 'timeTakeoff', time);  
%questo permette di prendere il tempo a cui viene fatto decollare il drone, per fare l'analisi dati corretta. 
%In questa maniera anche se ci sono leggere discrepanze tra decollo e acquisizione dati, sappiamo da dove partire per avere i dati corretti



%takeoff(getappdata(0, 'drone'));
%IN CASO DI SOLA ACQUISIZIONE DATI PER TRAINING IL COMANDO DI DECOLLO DEVE ESSERE DISABILITATO


%--------------------------------------------------------------------------




function landButtonCallback(hObject,~) 
%Callback function del bottone Land




%land(getappdata(0, 'drone'));
%IN CASO DI SOLA ACQUISIZIONE DATI PER TRAINING IL COMANDO DI ATTERRAGGIO DEVE ESSERE DISABILITATO
%Far atterrare il drone è la prima operazione da fare, per evitare di attendere il salvataggio dei dati



setappdata(0, 'flight', 0);    
%la flag segnala che il drone è atterrato, per disabilitare i flash



set_param(mp.modelName,'SimulationCommand','stop');        
set_param(mp.modelName,'Stoptime',mp.originalStopTime);
%ferma la simulazione e ripristina il tempo iniziale salvato in precedenza


binbin=getappdata(0, 'binbin');
   
save('binCheck',  'binbin');
setappdata(0, 'flight', 0);
flashSeq=getappdata(0, 'flashDaPrendere');
EEGsamples=getappdata(0, 'EEG');
beginIndex=find(EEGsamples(9,:)==getappdata(0, 'beginTime'));
EEGsamplesCut=EEGsamples(:, beginIndex:end);
takeoff=getappdata(0, 'timeTakeoff');
target=getappdata(0, 'target');
ISI=getappdata(0, 'ISI');
flashAnalisi=getappdata(0, 'flashAnalisi');
tempi_analisi=getappdata(0, 'tempiAnalisi');
partials=getappdata(0, 'partial4Windows');
netOutput=getappdata(0, 'classif');
conteggioCicli=getappdata(0, 'conteggioCicli');

fileName=['flashSequence',datestr(now, 'dd-mmm-yyyy'), '-', datestr(now, 'HH') ,datestr(now, 'MM'),datestr(now, 'SS'), '.mat'];
save(fileName, 'EEGsamples', 'EEGsamplesCut', 'flashSeq', 'takeoff', 'target', 'ISI', 'tempi_analisi', 'binbin', 'flashAnalisi', 'partials', 'netOutput', 'conteggioCicli');
%nel file con nome definito da fileName vengono salvati:
%-EEGsamples: i campioni prelevati dal caschetto
%-EEGsamplesCut: i campioni prelevati, a partire dal tempo di decollo. Normalmente coincidono con EEGsamples, ma in caso di modifiche alla sequenza di avvio potrebbero differire, dunque questi sono i dati da usare
%-flashSeq: la sequenza dei flash nell'ordine con cui avvengono
%-takeoff: il tempo a cui avviene il decollo
%-target: se è stata specificata la freccia su cui concentrarsi, questa viene indicata qui (avanti=1; indietro=2; sinistra=3; destra=4), altrimenti sarà vuoto
%-ISI: con nome improprio, il periodo con cui avvengono i flash. 
%-tempi_analisi= gli istanti di tempo corrispondenti all'inizio delle finestre fornite alla rete. Utile per controllare la sincronia. In caso alcuni flash non si verifichino l'intero ciclo viene scartato: di conseguenza è necessario sapere in quali intervalli di tempo ritagliare i segnali in EEG
%-binbin: la sequenza con cui si riempiono i bin, per poter verificare il comportamento della rete
%-flashAnalisi: la sequenza dei flash in ordine di avvenimento, ma solo in corrispondenza di tempi_analisi. Necessario per confrontare i risultati ottenuti con quelli attesi in fase di analisi e training
%-partials: i blocchi di dati di EEG passati alla rete: corrispondono a blocchi di 850 campioni, con 8 canali e l'istante di tempo di acquisizione. La dimensione è Nx850, dove N è multiplo di 9 (8 canali + tempo)
%-netOutput: è la sequenza degli output della rete. Sono Categorical. Serve solo per eventuali verifiche offline dei dati.
%-conteggioCicli: un check per controllare se i cicli avvengono o meno



removeListenersFromStartFcn;  
%chiama la funzione per rimuovere i listener dalla startFcn
   


set(mp.handles.Takeoff,'Enable','on');
set(mp.handles.Land,'Enable','off');
%toggle dei pulsanti
    



 fprintf('stop\n')    



%------------------------------------------------- 

function chooseTarget(hObject, ~)
%funzione per memorizzare la freccia target

str = get(hObject,'String');
newValue = str2double(str);
setappdata(0, 'target', newValue);


%--------------------------------------------------------------------------



function removeListenersFromStartFcn
%Funzione per rimuovere i listener dalla startFcn



set_param(mp.modelName,'StartFcn',mp.originalStartFcn);
%ripristina la startFcn alla condizione originale



for idx = 1:length(mp.eventHandle)
    if ishandle(mp.eventHandle{idx})
        delete(mp.eventHandle{idx});
    end
end
%cancella i listener impostati precedentemente


 
mp = rmfield(mp,'eventHandle');
%rimuove eventHandle
    


%--------------------------------------------------------------------------

function plotEEG(block, ~) 
%questa funzione (collegata allo scope in Simulink tramite callback) raccoglie e salva in un array i dati del caschetto. 


  
EEGdata(1)=block.InputPort(1).Data; 
EEGdata(2)=block.InputPort(2).Data;
EEGdata(3)=block.InputPort(3).Data;
EEGdata(4)=block.InputPort(4).Data;
EEGdata(5)=block.InputPort(5).Data;
EEGdata(6)=block.InputPort(6).Data;
EEGdata(7)=block.InputPort(7).Data;
EEGdata(8)=block.InputPort(8).Data;
EEGdata(9)=get_param(mp.modelName,'SimulationTime');  
%il for loop dà problemi di prestazioni. Questo è poco elegante ma più veloce.
 
   

setappdata(0, 'EEG', [getappdata(0, 'EEG') EEGdata']);
%in questo array vengono accumulati i dati. Questo array verrà ripreso nella funzione Land per salvare i dati del trial



 %--------------------------------------------------------------------------


function flashImage(block, ~)  
%Questa funzione (collegata al digital clock in Simulink) si occupa della gestione dei flash.



ISI=getappdata(0, 'ISI');



timeTakeoff=getappdata(0, 'timeTakeoff');
time=block.OutputPort(1).Data-timeTakeoff;
%I flash si attivano dal momento in cui il drone decolla. Di conseguenza il tempo viene calcolato come la differenza tra il tempo di simulazione ed il tempo di decollo.

    
  
if (mod(time+round(ISI/2, 1), 4*ISI)==0) % && (getappdata(0, 'flight')==1)                   
        setappdata(0, 'sequenceBin2', getappdata(0, 'sequenceBin1'));
        setappdata(0, 'sequenceBin1', []);
        setappdata(0, 'i', 0);
        flashSequence=randperm(4);
        setappdata(0, 'sequence', flashSequence);
end
%La nuova sequenza viene generata a metà ISI prima dell'inizio del ciclo successivo. Il primo è stato inizializzato all'avvio.
%Durante l'esecuzione i flash vengono accumulati in sequenceBin1. 
%Prima dell'inzio del ciclo successivo questi vengono salvati in sequenceBin2 (perché serviranno successivamente per l'analisi dati, che viene effettuata dopo un ciclo completo, dunque bisogna evitare di sovrascriverli)
%SequenceBin1 viene svuotato in maniera da contenere sempre gruppi di 4.
% i è il contatore dei flash avvenuti, servirà per prendere l'elemento successivo in flashSequence.

    


if (mod(time, ISI)==0) % && (getappdata(0, 'flight')==1) 
%ogni ISI flasho un'immagine
       

   step=getappdata(0, 'i')+1;
   setappdata(0, 'i', step);
%i viene aggiornato

        
   randSeq=getappdata(0, 'sequence');
   tttt(1)=get_param(mp.modelName,'SimulationTime'); % occhio che questo è simulation time, quindi non parte da zero - ma mi serve saperlo perché devo poter sincronizzare dati e flash
   tttt(2)=randSeq(step);
   setappdata(0, 'sequenceBin1', [getappdata(0, 'sequenceBin1'), tttt']);
%sequenceBin1 viene aggiornato

        if (getappdata(0, 'timeFlag')==0) && (getappdata(0, 'flight')==1)     
            setappdata(0, 'beginTime', get_param(mp.modelName,'SimulationTime'));
            setappdata(0, 'timeFlag', 1);
        end
%salva in beginTime l'istante in cui iniziano i flash. TimeFlag=1 è una flag che avvisa che il sistema è partito.

        
        switch randSeq(step)
            
            case 1
               
                set(mp.flashHandlesUp, 'CData', getappdata(0, 'upWhite'));
                drawnow;
                
            case 2
                
                set(mp.flashHandlesDown, 'CData', getappdata(0, 'downWhite'));
                drawnow;
                
            case 3
                
                set(mp.flashHandlesLeft, 'CData', getappdata(0, 'leftWhite'));
                drawnow;
                
            case 4
                
                set(mp.flashHandlesRight, 'CData', getappdata(0, 'rightWhite'));
                drawnow;
     
        end
%Lo switch cambia l'immagine della freccia indicata da randSeq(step) per simulare il flash. 
%Drawnow effettua un refresh della GUI
%il refresh della GUI normalmente avviene ogni ~ 1/8s. Per evitare che il flash venga perso durante un refresh vengono usati i drawnow per forzare l'update 
        
end



if (mod(time-0.1, ISI)==0)
        
    set(mp.flashHandlesUp, 'CData', getappdata(0, 'upBlack'));
    set(mp.flashHandlesDown, 'CData', getappdata(0, 'downBlack'));
    set(mp.flashHandlesLeft, 'CData', getappdata(0, 'leftBlack'));
    set(mp.flashHandlesRight, 'CData', getappdata(0, 'rightBlack'));
    drawnow; 
 
end
%Il flash dura 0.1s, poi l'immagine viene ripristinata. Lo stesso vale per le frecce rosse.
%Siccome i cambi di frecce possono avvenire in più occasioni, è più facile riaggiornarle ogni 0.1s.




%--------------------------------------------------------------------------

function dataAnalysys(block, ~)  
%Questa è la funzione che effettua l'analisi dei dati ed invia i comandi di conseguenza


    mp = guidata(findall(0,'tag',mfilename));

    ISI=getappdata(0, 'ISI');

    timeTakeoff=getappdata(0, 'timeTakeoff');
    time=block.OutputPort(1).Data-timeTakeoff;

    flashAnalysis=getappdata(0, 'sequenceBin2');



     tempiConfronto=getappdata(0, 'tempiFlashPerConfronto');
     %tempiFlashPerConfronto è stato inizializzato a -1 in takeoffButtonCallback




    if (mod((time-round(3/2*ISI, 1)), 4*ISI)==0) && (time >1) && length(flashAnalysis(2,:))==4  && tempiConfronto~=flashAnalysis(1, 1)
    %questo permette di avere abbastanza tempo per prendere i dati e avere un intervallo di tempo sufficiente per fare l'analisi
    %L'analisi deve attendere di avere abbastanza dati, dunque viene effettuata successivamente al ciclo completo
    %length(flashAnalysis(2,:))==4 è necessario per controllare che il ciclo completo sia stato effettuato, altrimenti i dati da inviare alla rete neurale non avrebbero senso
    %tempiConfronto~=flashAnalysis(1, 1) serve per essere sicuri che il sistema attenda il ciclo successivo per fare l'analisi del ciclo precedente. 

       


        if getappdata(0, 'timeFlag')==1
            setappdata(0, 'tempiAnalisi', [getappdata(0, 'tempiAnalisi'), get_param(mp.modelName,'SimulationTime')]);
            setappdata(0, 'flashAnalisi', [getappdata(0, 'flashAnalisi'), flashAnalysis]);
        end
        %qui vengono accumulate le sequenze di flash, a gruppi di 4, e l'istante di tempo in cui viene effettuata l'analisi (come misura di controllo)

	

        setappdata(0, 'tempiFlashPerConfronto', flashAnalysis(1, 1));
        %'tempiFlashPerConfronto' viene aggiornato con l'inizio del nuovo loop


        bin=getappdata(0, 'bin');  
      
        datiUtili=getappdata(0, 'EEG');
        timeIndex = find(datiUtili(9,:)==getappdata(0, 'beginTime'));
        setappdata(0, 'timeSlice', timeIndex);
	%Questo è l'inizio dei dati. 
        
        
       
        timeIndexPartial = find(datiUtili(9,:)==flashAnalysis(1,1));
        toProcess=datiUtili(:, timeIndexPartial:timeIndexPartial+(3*ISI+1)*250-1);
	%questi sono gli 850 campioni associati al ciclo di 4 flash effettuati

   

        setappdata(0, 'partial4Windows', [getappdata(0, 'partial4Windows');toProcess]);
        %I dati vengono salvati a blocchi di 4 flash, da salvare in landButtonCallback.



        M=provaPrepr3(toProcess, getappdata(0, 'filter'));
	%provaPrepr3 effettua il preprocessing dei dati (vedi più avanti). 
	%In input vengono passati gli 850 campioni ed il filtro caricato all'avvio. 



        p= classify(getappdata(0, 'net'),M);
	%La funzione classify è una funzione di Matlab che si occupa di usare la rete come classificatore. 
	%I dati vengono passati come 4 finestre, e la funzione effettua la classificazione su ciascuna.
	%L'output è un vettore di 4 classi.



        setappdata(0, 'classif', [getappdata(0, 'classif'); p]);
	%La sequenza di output della rete viene salvata



        y=str2double(cellstr(p));
        t=y==1;
	%t contiene gli indici del vettore di output le cui classi sono 1 (ovvero dove il P300 è stato individuato)



        setappdata(0, 'flagD', (getappdata(0, 'flagD')+1));
%%%%DA TOGLIERE


        
        s=flashAnalysis(2, t);
        bin(s)=bin(s)+1;
	%I bin corrispondenti alle frecce dove è stato individuato il P300 vengono incrementati di 1.



        setappdata(0, 'cicli', (getappdata(0, 'cicli')+1));
	%Questo contatore tiene traccia di quante volte l'operazione di classificazione è stata effettuata. 
	%Questo perché servono almeno 8 cicli prima di poter dare un comando.



        setappdata(0, 'conteggioCicli', [getappdata(0, 'conteggioCicli'), getappdata(0, 'cicli')]);
	%Qui viene menorizzato lo storico dei cicli per poter controllare quanti ne sono serviti di volta in volta



        setappdata(0, 'bin', bin);
	%Viene memorizzato lo stato attuale dei bin



        setappdata(0, 'binbin', [getappdata(0, 'binbin'); bin]);
	%Viene salvato lo storico degli update dei bin, in maniera tale da poter controllare come si sono riempiti



        if (time ~=0) && (length(find(bin==max(bin)))==1) && (getappdata(0, 'cicli'))>=8 
	%Il comando va mandato dopo almeno 8 cicli e solo se un unico bin domina su tutti gli altri.
	%Altrimenti verrebbero dati due comandi in contemporanea      
            


            switch find(bin==max(bin))
	    %La freccia corrispondente al comando inviato viene colorata di rosso per evidenziare a schermo quale è il comando selezionato
	    %SE IL PROGRAMMA VIENE USATO SOLO PER L'ACQUISIZIONE DATI I COMANDI VANNO TENUTI COMMENTATI
	    %SE IL PROGRAMMA VIENE USATO PER IL CONTROLLO BISOGNA TOGLIERE IL COMMENTO
	    %moveforward e moveback richiedono di specificare la durata del movimento
	    %turn richiede di specificare la rotazione in radianti
		
            
                case 1
                set(mp.flashHandlesUp, 'CData', getappdata(0, 'upRed'));
%                 if (getappdata(0, 'flight')==1) 
%                     moveforward(getappdata(0, 'drone'), 0.8); 
%                 end
                
                drawnow;
  
                case 2

                set(mp.flashHandlesDown, 'CData', getappdata(0, 'downRed'));    
%                 if (getappdata(0, 'flight')==1) 
%                     moveback(getappdata(0, 'drone'), 0.8); 
%                 end                  
                
                drawnow;
   
                case 3
                set(mp.flashHandlesLeft, 'CData', getappdata(0, 'leftRed'));
%                 if (getappdata(0, 'flight')==1) 
%                     turn(getappdata(0, 'drone'),deg2rad(-90)); 
%                 end                                                
                
                drawnow;
                          
                case 4
                set(mp.flashHandlesRight, 'CData', getappdata(0, 'rightRed'));
%                 if (getappdata(0, 'flight')==1) 
%                     turn(getappdata(0, 'drone'),deg2rad(90)); 
%                 end                             
                
                drawnow;

            end

            setappdata(0, 'bin', [0 0 0 0]);
            setappdata(0, 'cicli', 0);
   	    %se il comando è stato dato con successo, i bin e il conteggio dei cicli vengono inizializzati a 0
       
        end


    end




%--------------------------------------------------------------------------
  

function safelyCloseGUI(hObject,~)
%funzione per cancellare in sicurezza la GUI


    mp = guidata(hObject);


    if modelIsLoaded(mp.modelName)
        switch get_param(mp.modelName,'SimulationStatus')
            case 'stopped'
                removeListenersFromStartFcn;   %bisogna rimuovere i listener dalla startFcn
                close_system(mp.modelName,0);
                setappdata(0, 'drone', []); %chiude la connessione al drone
                delete(gcbo); %chiude la Figure
  
            otherwise
                errordlg('Stop the model first', 'UI Close error','modal');
        end
    else
        setappdata(0, 'drone', []);
        delete(gcbo);
    end
    %Per chiudere la GUI bisogna prima che il modello Simulink sia fermo.
    %Il sistema controlla se il modello Simulink è caricato.
    %Se è caricato ed il modello è fermo, allora la GUI viene chiusa
    %altrimenti un avviso ricorda di fermare il sistema.
    %Se il modello non è caricato, la GUI viene chiusa.




%--------------------------------------------------------------------------


function M= provaPrepr3(toProcess, D) 
%funzione di preprocessing dei dati



    dataset_filt= transpose(filtfilt(D, transpose(toProcess(1:8, :))));   
    %I dati vengono filtrati con il filtro realizzato all'avvio

    

    dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);
    %Winsorization



    dataset_resc(1,:) =  rescale(dataset_wins(1,:),-1,1); 
    dataset_resc(2,:) =  rescale(dataset_wins(2,:),-1,1); 
    dataset_resc(3,:) =  rescale(dataset_wins(3,:),-1,1); 
    dataset_resc(4,:) =  rescale(dataset_wins(4,:),-1,1); 
    dataset_resc(5,:) =  rescale(dataset_wins(5,:),-1,1); 
    dataset_resc(6,:) =  rescale(dataset_wins(6,:),-1,1); 
    dataset_resc(7,:) =  rescale(dataset_wins(7,:),-1,1); 
    dataset_resc(8,:) =  rescale(dataset_wins(8,:),-1,1); 
    %Rescaling dei singoli canali.
    %Non viene usato un for loop per ridurre il carico computazionale

    

    dataset_subs=dataset_resc(:, 1:10:end); 
    %Subsampling a 25 campioni/sec

    

    trials=zeros(4, 8, 25);

    trials(1,:,:)=dataset_subs(:, 1:25);
    trials(2,:,:)=dataset_subs(:, 21:45);
    trials(3,:,:)=dataset_subs(:, 41:65);
    trials(4,:,:)=dataset_subs(:, 61:85);
    %Le quattro finestre corrispondenti ai flash.



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
    %Le finestre vengono trasformate in matrici 4x25x3. 
    %La quarta dimensione è l'indice di ciascuna finestra. 
    %classify riceve in input questo array 4D e si occupa di suddividerlo in 4 array 3D 4x25x3.
