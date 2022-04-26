clear all;
close all;

exper = 1;

for i = 1:10
    seed = i + 1000;
    phase = 2;
    nameFileToLoad = ['r95e' num2str(exper) 'p' num2str(phase) 's' num2str(seed) '.mat'];
    load(nameFileToLoad);
    phase = 3;
    env = netEnvRECO(exper,phase,seed,nameFileToLoad);
    
    env.net.dyn.longTermW  = net.dyn.longTermW;
    env.net.dyn.shortTermW = net.dyn.shortTermW;
   
    env.mainLoop;
    
    env.net.log.stimuli = env.log.stimuli;
    env.net.log.actions = env.log.actions;

    net = env.net;
    pause(1);
    nameFileToSave = ['r95e' num2str(exper) 'p' num2str(phase) 's' num2str(seed) '.mat'];
    save(nameFileToSave,'net');
    clear net;
    clear env;

    phase = 3;
    nameFileToLoad = ['r95e' num2str(exper) 'p' num2str(phase) 's' num2str(seed) '.mat'];
    load(nameFileToLoad);
    phase = 1;
    nameFileToSave = ['r95e' num2str(exper) 'p' num2str(phase) 'bis_s' num2str(seed) '.mat'];

    env = netEnvRECO(exper,phase,seed,nameFileToSave);
    
    env.net.dyn.shortTermW = net.dyn.shortTermW;
    env.net.dyn.longTermW  = net.dyn.longTermW;
     
    env.mainLoop;
    
    env.net.log.stimuli = env.log.stimuli;
    env.net.log.actions = env.log.actions;

    net = env.net;
    pause(1);
    save(nameFileToSave,'net');
    clear net;
    clear env;
end
