

function varargout =WORKING_HEADSET_CONTROL_FUNZIONANTE  

    
    modelName = 'readingP300_corr'; 
    
    setappdata(0, 'upWhite', imread('up_white.jpg'));   %le immagini per i flash
    setappdata(0, 'upBlack', imread('up_black.jpg'));
    setappdata(0, 'upRed', imread('up_red.jpg'));
    setappdata(0, 'downWhite', imread('down_white.jpg'));  
    setappdata(0, 'downBlack', imread('down_black.jpg'));
    setappdata(0, 'downRed', imread('down_red.jpg'));
    setappdata(0, 'leftWhite', imread('left_white.jpg'));  
    setappdata(0, 'leftBlack', imread('left_black.jpg'));
    setappdata(0, 'leftRed', imread('left_red.jpg'));
    setappdata(0, 'rightWhite', imread('right_white.jpg'));  
    setappdata(0, 'rightBlack', imread('right_black.jpg'));
    setappdata(0, 'rightRed', imread('right_red.jpg'));
    setappdata(0, 'takeoffWhite', imread('takeoff_white.jpg'));  
    setappdata(0, 'takeoffBlack', imread('takeoff_black.jpg'));
    setappdata(0, 'landWhite', imread('land_white.jpg'));  
    setappdata(0, 'landBlack', imread('land_black.jpg'));
    
    fprintf('immagini caricate\n')


    
%     p=parrot();     %il drone    
%     setappdata(0, 'drone', p); 
%     fprintf('collegamento parrot effettuato\n')


     
    ISI=0.8;

    setappdata(0, 'ISI', ISI);

     

    D=designfilt('bandpassiir', 'FilterOrder', 8, 'PassbandFrequency1', 1, 'PassbandFrequency2', 12, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);
    setappdata(0, 'filter', D);

    NN=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrepCorrWind_completa.mat');

    setappdata(0, 'flashDaPrendere', []);
    setappdata(0, 'EEG', []);  
    setappdata(0, 'net', NN.examinedNet);

    setappdata(0, 'flagD', 0); 
    setappdata(0, 'cicli', 0); 
    setappdata(0, 'flight', 0);
    setappdata(0, 'binbin', []);
    setappdata(0, 'CHECK',[]);

   
    bin=[0 0 0 0 ];
    setappdata(0, 'bin', bin);

    
    flashSequence=randperm(4);
    setappdata(0, 'sequence', flashSequence);

    
    setappdata(0, 'beginTime', 0);
    setappdata(0, 'timeFlag', 0);
    setappdata(0, 'timeTakeoff', 0);


    guiCheck = findall(0,'Tag',mfilename);


    if isempty(guiCheck)  %se findall non ha trovato nulla allora la GUI non esiste
        guiCheck = createGUI(modelName);  %quindi la crea
    else  %se invece la trova
        figure(guiCheck); %la mette in primo piano
    end

    if nargout > 0  
        varargout{1} = guiCheck;
    end

%--------------------------------------------------------------------------

%Creazione dell'interfaccia grafica

function figureGUI = createGUI(modelName)

    
    % creare la Figure in cui va inserito il tutto
    figureGUI = figure('Tag', mfilename, 'Toolbar', 'none', 'MenuBar', 'none',...
        'IntegerHandle', 'off', 'Units', 'normalized', 'Resize', 'off',...
        'NumberTitle', 'off', 'HandleVisibility', 'callback',...
        'Name', sprintf('Controllo di %s.mdl',modelName),...
        'CloseRequestFcn', @safelyCloseGUI, 'Visible', 'off', 'Resize', 'on', 'Color', '#c0c0c0');

    
    %axes per il video (non usato)
%     axVid = axes('Parent', figureGUI, 'HandleVisibility','callback',...
%         'Unit', 'normalized', 'OuterPosition', [0.25 0.25 0.45 0.45],...
%         'Tag', 'videoAxes', 'Color', '#c0c0c0');



    %immagini da flashare - in questo caso frecce - vengono
    %innanzitutto impostate come grigie su sfondo nero
    arrowUp=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...   %nota: soluzione pigra, sono bottoni. Bisognerebbe mettere axes, 
        'Unit', 'normalized', 'OuterPosition', [0.4 0.86 0.2 0.2],...            %caricare le immagini in quegli axes all'inizializzazione, 
        'cdata', getappdata(0, 'upBlack'), 'Tag', 'flashImgUp', 'BackgroundColor', '#a9a9a9');                %e a quel punto cambiare i CData di quelle immagini
    arrowDown=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [0.4 -0.07 0.2 0.2],...
        'cdata', getappdata(0, 'downBlack'), 'Tag', 'flashImgDown', 'BackgroundColor', '#a9a9a9');
    arrowLeft=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [-0.08 0.45 0.2 0.2],...
        'cdata', getappdata(0, 'leftBlack'), 'Tag', 'flashImgLeft', 'BackgroundColor', '#a9a9a9');
    arrowRight=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [0.88 0.45 0.2 0.2],...
        'cdata', getappdata(0, 'rightBlack'), 'Tag', 'flashImgRight', 'BackgroundColor', '#a9a9a9');


      
    %bottoni di takeoff & land
    takeoff=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [0.15 0.2 0.2 0.2],...
        'cdata', getappdata(0, 'takeoffBlack'), 'Tag', 'Takeoff',...
        'Enable', 'on', 'Callback', @takeoffButtonCallback);
    
    land=uicontrol('Parent', figureGUI, 'HandleVisibility', 'callback',...
        'Unit', 'normalized', 'OuterPosition', [0.65 0.2 0.2 0.2],...
        'cdata', getappdata(0, 'landBlack'), 'Tag', 'Land',...
        'Enable', 'off', 'Callback', @landButtonCallback);


    %dove scrivere quale freccia sarà il target (se necessario)
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


    mp = loadSimulinkModel(modelName); %loadSimulinkModel è definita più avanti

    set_param(mp.modelName, 'StopTime', 'inf');
    set_param(mp.modelName, 'SimulationMode', 'normal');
    set_param(mp.modelName, 'StartFcn', 'addListenersToEvents');   %imposta i listener necessari nella startFcn
    
    fprintf('model loaded\n')

    mp.flashHandlesUp=arrowUp;  %memorizziamo in "mp" gli handle delle immagini di cui fare i flash
    mp.flashHandlesDown=arrowDown;
    mp.flashHandlesLeft=arrowLeft;
    mp.flashHandlesRight=arrowRight;
    mp.handlesTakeoff=takeoff;
    mp.handlesLand=land;


  
     %creazione dello streaming video (non usato)
%     mp.videoHandles=axVid;
%     cameraObj = camera(getappdata(0, 'drone'),'FPV');
%     img=image(zeros(360, 640, 3), 'Parent', mp.videoHandles);
%     mp.cameraHandle=cameraObj;
%     preview(mp.cameraHandle, img);


    mp.handles = guihandles(figureGUI); 
  
    guidata(figureGUI,mp);     %memorizza tutti i dati della GUI 
    
    movegui(figureGUI,'center')    %voglio la GUI al centro
    
    set(figureGUI,'Visible','on'); %voglio che diventi visibile una volta impostata
    
    fprintf('creazione GUI\n')


%--------------------------------------------------------------------------  



function mp = loadSimulinkModel(modelName)

    if ~modelIsLoaded(modelName)
        load_system(modelName);
    end
    
    mp.modelName = modelName;
    mp.originalStopTime = get_param(mp.modelName, 'Stoptime');
    mp.originalStartFcn = get_param(mp.modelName, 'StartFcn');

    %Parametri da impostare per assegnare i listener opportuni ai blocchi
    mp.listenerSettings = struct('blockName', '', 'blockHandle', [],...
        'blockEvent', '', 'blockFcn', []);
    
    %Nomi 
    mp.listenerSettings(1).blockName = sprintf('%s/Digital Clock', mp.modelName);
    mp.listenerSettings(2).blockName = sprintf('%s/RAW_EEG1', mp.modelName);
    mp.listenerSettings(3).blockName = sprintf('%s/Digital Clock', mp.modelName);
    
    %Handles opportuni
    mp.listenerSettings(1).blockHandle = get_param(mp.listenerSettings(1).blockName, 'Handle');
    mp.listenerSettings(2).blockHandle = get_param(mp.listenerSettings(2).blockName, 'Handle');
    mp.listenerSettings(3).blockHandle = get_param(mp.listenerSettings(3).blockName, 'Handle');

    %Su che eventi impostare i listener.
    mp.listenerSettings(1).blockEvent = 'PostOutputs';
    mp.listenerSettings(2).blockEvent = 'PostOutputs';   %Nota che lo Scope ha un output grafico, quindi è possibile usare comunque PostOutputs
    mp.listenerSettings(3).blockEvent = 'PostOutputs';
    
    %I callback opportuni
    mp.listenerSettings(1).blockFcn = @flashImage;
    mp.listenerSettings(2).blockFcn = @plotEEG;
    mp.listenerSettings(3).blockFcn = @dataAnalysys;


    

%--------------------------------------------------------------------------
        


function modelLoaded = modelIsLoaded(modelName)

    try
        modelLoaded = ~isempty(find_system('Type', 'block_diagram', 'Name', modelName));
    catch ME %non so se necessario
        modelLoaded = false;
    end
    
%--------------------------------------------------------------------------


function addListenersToEvents

    mp = guidata(gcbo);

    %esegue la startFcn originale
    if ~isempty(mp.originalStartFcn)
        evalin('Base',mp.originalStartFcn);
    end

    %aggiungere i listener
    mp.eventHandle = cell(1,length(mp.listenerSettings));
    for idx = 1:length(mp.listenerSettings)
        mp.eventHandle{idx} = add_exec_event_listener(mp.listenerSettings(idx).blockName,...
            mp.listenerSettings(idx).blockEvent, mp.listenerSettings(idx).blockFcn);
    end

    %memorizza
    guidata(gcbo,mp);
    
%--------------------------------------------------------------------------


function takeoffButtonCallback(hObject,~) 

    mp = guidata(hObject);
    
    if ~modelIsLoaded(mp.modelName) %il modello Simulink dev essere caricato per poter funzionare (funzione definita più sotto)
        load_system(mp.modelName);
    end

    %start Simulink
    set_param(mp.modelName, 'SimulationCommand', 'start');
    
    %parametri vari da mantenere tra un callback e l'altro. Le cose che vanno resettate vanno messe qui
    setappdata(0, 'i', 0);  
    setappdata(0, 'flagD', 0);
    setappdata(0, 'cicli', 0); 

    bin=[0 0 0 0];
    setappdata(0, 'bin', bin); 
 
    setappdata(0, 'binbin', []);
    setappdata(0, 'classif', []);
    setappdata(0, 'flashDaPrendere', []);
    setappdata(0, 'EEG', []);   %la sequenza dei campioni da salvare
    setappdata(0, 'beginTime', 0);
    setappdata(0, 'timeFlag', 0);
    setappdata(0, 'iniziadati', 1);

    flashSequence=randperm(4);    
    setappdata(0, 'sequence', flashSequence);

    setappdata(0, 'pastSequence', []);
    setappdata(0, 'tempiAnalisi', []);
    setappdata(0, 'flashAnalisi', []);
    setappdata(0, 'sequenceBin1', []);
    setappdata(0, 'sequenceBin2', []);
    setappdata(0, 'partial4Windows', []);
    setappdata(0, 'noInterruzioni', 0);
    setappdata(0, 'conteggioCicli', []);

    setappdata(0, 'tempiFlashPerConfronto', -1);

   

    % toggle
    set(mp.handles.Takeoff,'Enable','off');
    set(mp.handles.Land,'Enable','on');

    
    setappdata(0, 'flight', 1);     %segnala che il drone è in volo per abilitare i flash


    handleName=sprintf('%s/Digital Clock', mp.modelName);   
    runTimeTime = get_param(handleName,'RunTimeObject'); 
    timeData=get(runTimeTime.OutputPort(1));
    time=timeData.Data;
    setappdata(0, 'timeTakeoff', time);


%     takeoff(getappdata(0, 'drone'));

    


%--------------------------------------------------------------------------

%Callback function del bottone Land

function landButtonCallback(hObject,~) 

    mp = guidata(hObject);

%     land(getappdata(0, 'drone'));

    setappdata(0, 'flight', 0);    %segnala che il drone è atterrato per disabilitare i flash

    %stop Simulink
    set_param(mp.modelName,'SimulationCommand','stop');        
    set_param(mp.modelName,'Stoptime',mp.originalStopTime);

    binbin=getappdata(0, 'binbin');
   

    save('binCheck',  'binbin');


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


    removeListenersFromStartFcn;   %bisogna rimuovere i listener dalla startFcn

    % toggle
    set(mp.handles.Takeoff,'Enable','on');
    set(mp.handles.Land,'Enable','off');
  
     
    setappdata(0, 'iniziadati', 0); 


    fprintf('stop\n')    
    


%------------------------------------------------- 

%callback per selezionare il target

function chooseTarget(hObject, ~)

    str = get(hObject,'String');
    newValue = str2double(str);
    setappdata(0, 'target', newValue);


%--------------------------------------------------------------------------

%Funzione per rimuovere i listener dalla startFcn

function removeListenersFromStartFcn

    mp = guidata(gcbo);

    %ripristina la startFcn alla condizione originale
    set_param(mp.modelName,'StartFcn',mp.originalStartFcn);

    %cancella i listener impostati precedentemente
    for idx = 1:length(mp.eventHandle)
        if ishandle(mp.eventHandle{idx})
            delete(mp.eventHandle{idx});
        end
    end
   
    mp = rmfield(mp,'eventHandle'); %rimuove eventHandle
    
    guidata(gcbo,mp);

%--------------------------------------------------------------------------

%Callback function per l'EEG

function plotEEG(block, ~) 

    mp = guidata(findall(0,'tag',mfilename));

  
    EEGdata(1)=block.InputPort(1).Data; 
    EEGdata(2)=block.InputPort(2).Data;
    EEGdata(3)=block.InputPort(3).Data;
    EEGdata(4)=block.InputPort(4).Data;
    EEGdata(5)=block.InputPort(5).Data;
    EEGdata(6)=block.InputPort(6).Data;
    EEGdata(7)=block.InputPort(7).Data;
    EEGdata(8)=block.InputPort(8).Data;
    EEGdata(9)=get_param(mp.modelName,'SimulationTime');   
   
    setappdata(0, 'EEG', [getappdata(0, 'EEG') EEGdata']);

% --------------------------------------------------------------------------


%Callback function per flashare l'immagine

function flashImage(block, ~)   

    ISI=getappdata(0, 'ISI');

    mp = guidata(findall(0,'tag',mfilename));

    timeTakeoff=getappdata(0, 'timeTakeoff');
    time=block.OutputPort(1).Data-timeTakeoff;


    if (mod(time+round(ISI/2, 1), 4*ISI)==0) % && (getappdata(0, 'flight')==1) 
                           
        setappdata(0, 'sequenceBin2', getappdata(0, 'sequenceBin1'));
        setappdata(0, 'sequenceBin1', []);
        setappdata(0, 'i', 0);
        flashSequence=randperm(4);
        setappdata(0, 'sequence', flashSequence);

    end
    


    if (mod(time, ISI)==0) % && (getappdata(0, 'flight')==1) % && (getappdata(0, 'noInterruzioni')==0) %ogni ISI flasho un'immagine
       
        step=getappdata(0, 'i')+1;
        setappdata(0, 'i', step);
        
        randSeq=getappdata(0, 'sequence');

        tttt(1)=get_param(mp.modelName,'SimulationTime'); % occhio che questo è simulation time, quindi non parte da zero - ma mi serve saperlo perché devo poter sincronizzare dati e flash
        tttt(2)=randSeq(step);

        setappdata(0, 'flashDaPrendere', [getappdata(0, 'flashDaPrendere'), tttt']);
        setappdata(0, 'sequenceBin1', [getappdata(0, 'sequenceBin1'), tttt']);



        if (getappdata(0, 'timeFlag')==0) && (getappdata(0, 'flight')==1)     %serve per prendere l'istante in cui inizio a fare i flash

            setappdata(0, 'beginTime', get_param(mp.modelName,'SimulationTime'));
            setappdata(0, 'timeFlag', 1);

        end
        
        
        
        switch randSeq(step)
            
            case 1
               
                set(mp.flashHandlesUp, 'CData', getappdata(0, 'upWhite'));
                drawnow; %il refresh della GUI avviene ~ 1/8s. Per evitare che il flash venga perso durante un refresh vengono usati i drawnow per forzare l'update 
                
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
    
    end



    if (mod(time-0.1, ISI)==0) % && (getappdata(0, 'flight')==1) % && (getappdata(0, 'noInterruzioni')==0) %il flash dura 0.1s, dunque dopo 25 campioni l'immagine viene ripristinata.

        set(mp.flashHandlesUp, 'CData', getappdata(0, 'upBlack'));
        set(mp.flashHandlesDown, 'CData', getappdata(0, 'downBlack'));
        set(mp.flashHandlesLeft, 'CData', getappdata(0, 'leftBlack'));
        set(mp.flashHandlesRight, 'CData', getappdata(0, 'rightBlack'));

        drawnow;  

    end

%--------------------------------------------------------------------------

% callback per fare l'analisi dei dati

function dataAnalysys(block, ~)  

    mp = guidata(findall(0,'tag',mfilename));

    ISI=getappdata(0, 'ISI');

    timeTakeoff=getappdata(0, 'timeTakeoff');
    time=block.OutputPort(1).Data-timeTakeoff;

    flashAnalysis=getappdata(0, 'sequenceBin2');

    tempiConfronto=getappdata(0, 'tempiFlashPerConfronto');



    if (mod((time-round(3/2*ISI, 1)), 4*ISI)==0) && (time >1) && length(flashAnalysis(2,:))==4  && tempiConfronto~=flashAnalysis(1, 1)% && (getappdata(0, 'flight')==1) %questo permette di avere abbastanza tempo per prendere i dati e avere un intervallo di tempo sufficiente per fare l'analisi
       

        if getappdata(0, 'timeFlag')==1

            setappdata(0, 'tempiAnalisi', [getappdata(0, 'tempiAnalisi'), get_param(mp.modelName,'SimulationTime')]);
            setappdata(0, 'flashAnalisi', [getappdata(0, 'flashAnalisi'), flashAnalysis]);
        end


        setappdata(0, 'tempiFlashPerConfronto', flashAnalysis(1, 1));


        bin=getappdata(0, 'bin');  
        datiUtili=getappdata(0, 'EEG');
        timeIndex = find(datiUtili(9,:)==getappdata(0, 'beginTime'));
        setappdata(0, 'timeSlice', timeIndex);
        
        
        timeIndexPartial = find(datiUtili(9,:)==flashAnalysis(1,1));

        toProcess=datiUtili(:, timeIndexPartial:timeIndexPartial+(3*ISI+1)*250-1);    %questo permette di far partire l'analisi con sincronia tra dati e flash

        setappdata(0, 'partial4Windows', [getappdata(0, 'partial4Windows');toProcess]);
        


        M=provaPrepr3(toProcess, getappdata(0, 'filter'));

        p= classify(getappdata(0, 'net'),M);

        setappdata(0, 'classif', [getappdata(0, 'classif'); p]);

        y=str2double(cellstr(p));

        t=y==1;

        setappdata(0, 'flagD', (getappdata(0, 'flagD')+1));
        
        s=flashAnalysis(2, t);

        bin(s)=bin(s)+1;

        setappdata(0, 'cicli', (getappdata(0, 'cicli')+1));
        setappdata(0, 'conteggioCicli', [getappdata(0, 'conteggioCicli'), getappdata(0, 'cicli')]);
        setappdata(0, 'bin', bin);
        setappdata(0, 'binbin', [getappdata(0, 'binbin'); bin]);



        if (time ~=0) && (length(find(bin==max(bin)))==1) && (getappdata(0, 'cicli'))>=8 %servono tot cicli per avere la risposta giusta      
            
            switch find(bin==max(bin))
            
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
   
       
        end

    end


%--------------------------------------------------------------------------

%Callback function per cancellare in sicurezza la GUI

function safelyCloseGUI(hObject,~)

    mp = guidata(hObject);

    %Per chiudere la GUI bisogna prima fermare il modello



    if modelIsLoaded(mp.modelName)

        switch get_param(mp.modelName,'SimulationStatus')

            case 'stopped'

                removeListenersFromStartFcn;  
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
%--------------------------------------------------------------------------


function M= provaPrepr3(toProcess, D) 

    dataset_filt= transpose(filtfilt(D, transpose(toProcess(1:8, :))));   

    dataset_wins=permute(filloutliers(permute(dataset_filt, [2, 1]), 'clip', 'percentiles', [10 90]), [2, 1]);


    dataset_resc(1,:) =  rescale(dataset_wins(1,:),-1,1); 
    dataset_resc(2,:) =  rescale(dataset_wins(2,:),-1,1); 
    dataset_resc(3,:) =  rescale(dataset_wins(3,:),-1,1); 
    dataset_resc(4,:) =  rescale(dataset_wins(4,:),-1,1); 
    dataset_resc(5,:) =  rescale(dataset_wins(5,:),-1,1); 
    dataset_resc(6,:) =  rescale(dataset_wins(6,:),-1,1); 
    dataset_resc(7,:) =  rescale(dataset_wins(7,:),-1,1); 
    dataset_resc(8,:) =  rescale(dataset_wins(8,:),-1,1); 
  

    dataset_subs=dataset_resc(:, 1:10:end); %25 campioni/sec


    trials=zeros(4, 8, 25);


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
