function EVAL = confMatrixValues(ACTUAL,PREDICTED)

% Questa funzione calcola la performance del classificatore
% utilizzando accuracy, recall, precision, f-score
% Input: ACTUAL = vettore colonna con i label effettivi delle finestre
%        PREDICTED = vettore colonna contenente l'output del classificatore
% Output: EVAL = vettore riga con i parametri 


idx = (ACTUAL()==categorical(1));

p = length(ACTUAL(idx)); %positives
n = length(ACTUAL(~idx)); %negatives

N = p+n;

tp = sum(ACTUAL(idx)==PREDICTED(idx)); %true positives
tn = sum(ACTUAL(~idx)==PREDICTED(~idx)); %true negatives
fp = n-tn; %false positives
fn = p-tp; %false negatives

tp_rate = tp/p;
tn_rate = tn/n;

accuracy = (tp+tn)/N;
precision = tp/(tp+fp);
recall = sensitivity;
f_measure = 2*((precision*recall)/(precision + recall));

fprintf("accuracy    recall    precision    f-score\n")
EVAL = [accuracy recall precision f_measure ]