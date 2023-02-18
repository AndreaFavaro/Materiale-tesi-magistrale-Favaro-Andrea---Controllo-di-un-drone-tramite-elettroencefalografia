
clear

myFolder = 'D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale';


filePattern = fullfile(myFolder, '*.mat'); 
filenames = dir(filePattern);

D=designfilt('bandpassiir', 'FilterOrder', 8, 'PassbandFrequency1', 1, 'PassbandFrequency2', 12, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);

net=load('D:\Users\206180-favaro\Documents\GitHub\TesiMagistrale\bestNetMineNewPrepCorrWind_completa.mat');
NN=net.examinedNet;

for k = 1 : length(filenames)
    
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
    bin=[0 0 0 0];
    binbinbin=[];
 
    
    for min=4:11

%         min=8;

        cicli=0;
        bin=[0 0 0 0];
        quantity=0;
        errori=0;
        delay=0;

        for num=1:length(binbin)

            trials=zeros(4, 8, 25);

            flashes=flashAnalisi(2, 1+4*(num-1): 4+4*(num-1));

            dataset_filt= transpose(filtfilt(D, transpose(partials(1+9*(num-1):8+9*(num-1), :))));   

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


            p= classify(NN,M);
            y=str2double(cellstr(p));
            t=y==1;

  
            s=flashes(t);
            bin(s)=bin(s)+1;
            binbinbin=[binbinbin;bin];

            cicli=cicli+1;
 
            if  (length(find(bin==max(bin)))==1) && (cicli>=min)
           
                fprintf('%d con %d; ',find(bin==max(bin)), cicli);

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
        fprintf('\n');

    end

    fprintf('\n');  

end