% Developed in May-September 2013 by Andrea Soltoggio, 
%in collaboration with Albert Mukovskiy

classdef netEnv < handle
    
    properties
        
        par;                             % parameters and settings for the environment
        netpar;                          % parameters and settings for the network
        dyn;                             % dynamic problem-variables
        net;                             % neural network
        stimuli;                         % vector of input stimuli
        fix;
        
        % particular type of input working as modulatory signal
        currentModulation                = 0;
        running                          = 1;    % switch to start/stop execution;
        log;                             % variable logs
        fig;                             % figures
        ser;                             % service variables
        
    end
    
    methods
        
        function env = netEnv(seed)
 
            % Shared parameter with children
            env.par.revision                    = 1;
            env.par.seed                        = seed;                    % random seed for pseudo number generator
            rng(env.par.seed);                                             % to make runs reproducible

            env.par.simTime                     = 1000;                    % max duration of the experiment in seconds
            env.par.samplingTime                = 0.1;                     % sampling time in seconds
                        
            env.par.nrStimuli                   = 100;                     % number of stimuli
            env.par.nrActions                   = 30;                      % number of actions
            env.par.nrOutputs = env.par.nrActions;                         % number of output neurons
                                    
            env.par.positiveReward              = 1;                       % intensity of modulation/per step for reward episode
            
            env.par.minTimeToReward             = 0.5;                     % min delay in seconds to the reward
            env.par.maxTimeToReward             = 3;                       % max delay in seconds to the rewrd
            
            env.par.nrNeurons                   = 20;                      % number of neurons in the network (passed as parameter to netSim)
            env.par.nrExcitatory                = 16;                      % number of excitatory neurons in the network (passed as parameter to netSim)
            
            env.par.connectivityCase            = 0;                       % 0 random connectitivy (no self connections)
                                                                           % 1 regular random (equal number of incoming and outgoing connections)
                                                                           % 2 feedforward
 
            env.par.probConnect                 = 0.1;                     % probability of two neurons being connected: 
                                                                           % see also env.par.connectivityCase and functions 
                                                                           
            env.par.WTAonOutputs                = 0;                       % if 1, one output is chosen to be very high and its output increased. 
                                                                           % if 0 no WTA takes place
            % following three parameters only significant when previous parameter is 1                                                               
            env.par.strengthOfWTAFeedback       = 1;                       % output value of the winner neuron (only when WTAonOutput is 1                   
            env.par.WTAactionMinDuration        = 1;                       % duration in s of the winner (min time)
            env.par.WTAactionMaxDuration        = 1;                       % duration in s of the winner (max time) 
            
            env.par.refreshGraphsEvery          = 60;                      % interval in s between graphical refresh
            
            % in child class please include the lines:
            %env.net = netSim(env.netpar);
            %env.initialiseRuntimeVariables(env);           
            
        end
        
        function initialiseRuntimeVariables(env)
                     
            env.stimuli                         = zeros(env.par.nrStimuli,1); 
            
            env.fix.totalSteps                  = env.par.simTime / env.par.samplingTime;
            
            env.dyn.stepsToReward               = -1;                      % dynamic variable indicating the nr of steps to next reward
                                                                           % initialised to -1 because at the start of the sim no reward is planned
            env.dyn.currentStimulus             = 1;                       % if one stimulus at a time is given, this is the index: initialised to 1                      
            
            env.ser.proceedOneStepDebug         = 0;                       % service debug variable to proceed one step at a time
            env.ser.currentStep                 = 2;                       % current simulation step, it updates at every step 
            env.fig.on                          = 0;                       % switch to 1 if the panel figure is created

           % env.createWindow();
            
        end
        
%        function mainLoop(env, src, ~)
         function mainLoop(env)
            
       %     if get(src, 'Value') 
       %        while get(src, 'Value') && env.ser.currentStep < env.par.simTime/env.par.samplingTime
                while env.running && env.ser.currentStep < env.par.simTime/env.par.samplingTime
                   
                   % feeding INPUT HERE and setting reward ##############
                   env.writeStimuli();
                   
                   % UPDATE NETWORK HERE #################################
                   env.net.update(env.stimuli, env.currentModulation);
                   
                   % READ OUTPUT #########################################
                   env.readOutput();
                   
                   if mod(env.ser.currentStep * env.par.samplingTime, env.par.refreshGraphsEvery) == 0
                       env.refreshGraphs();
                   end
                   
                   env.takeLogs();
                   
                   if env.ser.proceedOneStepDebug == 1
                       keyboard;
                   end
                   
                   env.ser.currentStep = env.ser.currentStep + 1;
                   env.dyn.stepsToReward = env.dyn.stepsToReward - 1;
                   
               end
               
            %   fileName = ['envNet_r'  num2str(env.par.revision)...
            %      'seed' num2str(env.par.seed) '.mat'];
            %  save(fileName);
                env.plotFinalResults();
                disp('Simulation finished.')

          %  else
                %run button released
          %      env.stopRunning();
          %  end
        end
        
        function writeStimuli(env)
            % child class implement how stimuli are generated and write
            % them to the network by updating the vector "env.stimuli"
            
        end
        
        function readOutput(env)            
        end
                
        function stopRunning(env)
        end
                
        function createWindow(env)
            env.fig.on = 1;
            env.fig.panel = figure('Position',[0 200 800 600]);
            set(env.fig.panel,'Units','normalized');
            set(env.fig.panel,'Name','Output');

            env.fig.genPanel = uipanel(env.fig.panel,'Position',[0 0 1 1]);
            
            env.ser.runbutton = uicontrol('Style', 'togglebutton',...
                'String','Start/Stop','Min',0,'Max',1,...
                'Parent',env.fig.panel,'Units','normalized','Position', [0 0 0.1 0.05],...
                'FontSize', 12,'Callback',@env.startStop);
            
            env.ser.proceedOneStepDebugbutton = uicontrol('Style', 'togglebutton',...
                'String','GoOneStep','Min',0,'Max',1,...
                'Parent',env.fig.panel,'Units','normalized','Position', [0.1 0 0.1 0.05],...
                'FontSize', 12,'Callback',@env.onestep);

                        
        end
        
        function showSettings(env)
            disp('env');
            env
            disp('env.par');
            env.par
            disp('env.net');
            env.net
            disp('env.net.par');
            env.net.par
            disp('env.net.dyn');
            env.net.dyn
            disp('env.net.fix');
            env.net.fix
           
            estimatedCorrPerSec = env.net.fix.nrOfPlasticSynapses * 0.01 * env.net.par.targetRCPercentPerSecond;
            estimatedCorrPerStep = env.net.fix.nrOfPlasticSynapses * 0.01 * env.net.par.targetRCPercentPerSecond * env.net.par.samplingTime;
            
            disp(['Estimated average rare correlations per second: ' num2str(estimatedCorrPerSec)]);
            disp(['Estimated average rare correlations per step: ' num2str(estimatedCorrPerStep)]);
            disp(' ');
            disp('Start the graphical interface with function "createWindow()".');
            disp('This creates the button to start/stop the exectution');
            disp('To start without graphics, use function "mainLoop()".');
            disp('In this case the execution will go to the end');
           
        end
        
        function refreshGraphs(env)
        end
        
        function plotFinalResults(env)
        end
        
        function startStop(env, src, evn)
            
            if get(src,'Value') == 1
                env.running = 1;
                disp('Execution started');
            else
                env.running = 0;
                disp('Execution suspended');
            end
            env.mainLoop();
        end
        
        function onestep(env, src, evn)
            if env.ser.proceedOneStepDebug == 1
                env.ser.proceedOneStepDebug = 0;
            else
                env.ser.proceedOneStepDebug = 1;
            end
        end
        
    end
end
