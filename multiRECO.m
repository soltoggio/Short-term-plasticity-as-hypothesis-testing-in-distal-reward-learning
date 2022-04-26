clear all;
close all;

exper = 2;


for i = 1:10
    seed = i + 1000;
    phase = 1;
    name = ['r95e' num2str(exper) 'p' num2str(phase) 's' num2str(seed)];
    env = netEnvRECO(exper,phase,seed,name);
    
    env.mainLoop;
    
    env.net.log.stimuli = env.log.stimuli;
    env.net.log.actions = env.log.actions;
    
    net = env.net;
    pause(1);
    save(name,'net');
    clear net;
    clear env;
    
    nameFileToLoad = ['r95e' num2str(exper) 'p' num2str(phase) 's' num2str(seed) '.mat'];
    load(nameFileToLoad);

    phase = 2;
    name = ['r95e' num2str(exper) 'p' num2str(phase) 's' num2str(seed)];
    env = netEnvRECO(exper,phase,seed,name);
  
    env.net.dyn.shortTermW = net.dyn.shortTermW;
    env.net.dyn.longTermW  = net.dyn.longTermW;
    
    env.mainLoop;

    env.net.log.stimuli = env.log.stimuli;
    env.net.log.actions = env.log.actions;
    
    net = env.net;
    pause(1);
    save(name,'net');
    clear net;
    clear env;
    
end
