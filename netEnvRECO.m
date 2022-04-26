
% Developed in May-September 2013 by Andrea Soltoggio, 
%in collaboration with Albert Mukovskiy

classdef netEnvRECO < netEnv
    
    properties
        
       IOrewardingMap;
       description;
                                              
      end
    
    methods
        
        function env = netEnvRECO(experiment, phase, seed, description)
             
            env = env@netEnv(seed);
             
            % Additional/rewriting child parameters for RECO exp
            env.description = description;
                                    
            env.par.simTime                     = 3600 * 24;              % duration of the experiment in seconds
            env.par.nrStimuli                   = 300;                     % number of stimuli
            env.par.nrActions                   = 30;                      % number of outputs
            env.par.nrOutputs = env.par.nrActions;
            
            env.par.stimulusMinDuration         = 0.5;
            env.par.stimulusMaxDuration         = 1.5;
            
            env.fix.stimulusMinDurationSteps    = env.par.stimulusMinDuration/env.par.samplingTime;
            env.fix.stimulusMaxDurationSteps    = env.par.stimulusMaxDuration/env.par.samplingTime;
             
            env.par.WTAactionMinDuration        = 1;
            env.par.WTAactionMaxDuration        = 2;
                                    
            env.par.positiveReward              = 1;                       % intensity of modulation/per step for reward episode
            
            env.par.minTimeToReward             = 1;
            env.par.maxTimeToReward             = 4;
            
            env.par.refreshGraphsEvery          = 60;
            
            env.par.nrNeurons                   = env.par.nrStimuli + env.par.nrActions ;
            env.par.nrExcitatory                = env.par.nrNeurons;
            
            env.par.connectivityCase            = 2;
            env.par.probConnect                 = 1;
            env.par.WTAonOutputs                = 1;
            env.par.strengthOfWTAFeedback       = 0.5;    
            env.par.transmissionNoiseFactor     = 0.02;           % Xi in Eq. ??
            env.par.activationFactor            = 0.5;            % Gamma in Eq. ?? (gain of the output neural function)
            
            env.par.targetRCPercentPerSecond    = 0.1;   

            env.par.adaptiveThetaThresholds     = 1;
            env.par.initialThetaLo              = -0.2;
            env.par.initialThetaHi              = 0.2;
            
            env.par.maxLTWeight                 =  1.0;
            env.par.minLTWeight                 =  0.0;
            env.par.weightInitValue             =  0.0;

                
            %% Settings for experiment comparision
            env.par.experiment                  = experiment;
            env.par.phase                       = phase;

            if env.par.experiment == 1 % 1 standard RCHP
                env.par.shortTW_TC                          =  3600 * 100000; 
                env.par.baseModulation                      =  0;  
                env.par.conversionToLTW                     =  0;
                env.par.adaptiveThetaLo                     =  1;
                env.par.maxSTWeight                         =  1;
                env.par.minSTWeight                         =  0;
                env.par.STW_updateRate                      =  1/10;       % also lambda          
            end
            
            if env.par.experiment == 2 % new RCHP
                env.par.shortTW_TC                          =  3600 * 8;
                env.par.conversionToLTW                     =  1;
                env.par.adaptiveThetaLo                     =  0;
                env.par.maxSTWeight                         =  1;
                env.par.minSTWeight                         = -1;
                env.par.STW_updateRate                      =  1/10;
                env.par.baseModulation                      = -0.25 * env.par.STW_updateRate;
            end
            
            if env.par.phase == 1
                env.IOrewardingMap = [1 1; 2 2; 3 3; 4 4; 5 5; 6 6; 7 7; 8 8; 9 9; 10 10];
            end
            if env.par.phase == 2
                env.IOrewardingMap = [11 6; 12 7; 13 8; 14 9; 15 10; 16 11; 17 12; 18 13; 19 14; 20 15];
            end
            if env.par.phase == 3
                env.IOrewardingMap = [21 1; 22 2; 23 3; 24 4; 25 5; 26 6; 27 7; 28 8; 29 9; 30 10];
            end
            
            env.net = netSimRECO(env.par);
       
            env.initialiseRuntimeVariables();    
            
            % child runtime variables here
            env.dyn.durationOfStimulus          = 0;
            
            env.showSettings();
            
        end
        
        function initialiseRuntimeVariables(env)
            initialiseRuntimeVariables@netEnv(env);
            
            env.log.stimuli = zeros(env.fix.totalSteps, 1);
            env.log.actions = zeros(env.fix.totalSteps, 1);
            env.dyn.action = 1;
          
        end
        
        %        function running(env,src,evn)
        %            if get(src, 'Value')
        
        %              while get(src, 'Value') && env.ser.currentStep < env.par.simTime/env.par.samplingTime
        function mainLoop(env)
            %            if get(src, 'Value')
            
            %              while get(src, 'Value') && env.ser.currentStep < env.par.simTime/env.par.samplingTime
            
            while env.running && env.ser.currentStep < env.par.simTime/env.par.samplingTime
                
                % feeding INPUT HERE and setting reward ##############
                env.writeStimuli();
                
                % UPDATE NETWORK HERE #################################
                env.net.update(env.stimuli, env.currentModulation);
                
                % READ OUTPUT #########################################
                env.readOutput();
                
                if mod(env.ser.currentStep * env.par.samplingTime, env.par.refreshGraphsEvery) == 0
                    pause(0.1);
                    env.refreshGraphs();
                end
                
                env.takeLogs();
                
                if env.ser.proceedOneStepDebug == 1
                    disp(['S: ' num2str(env.ser.currentStep) ' R-stimulus nr: ' num2str(env.dyn.currentStimulus)...
                        ' action is ' num2str(env.dyn.action)]);
                    
                    % keyboard;
                end
                
                env.ser.currentStep = env.ser.currentStep + 1;
                env.dyn.stepsToReward = env.dyn.stepsToReward - 1;
                
            end
            
            %   else
            %run button released
            %       env.stopRunning();
            %   end
        end
        
        function writeStimuli(env)
            
            % In this configuration, one and only one stimulus each time
            % step. Other regimens could be tested
            env.dyn.durationOfStimulus = env.dyn.durationOfStimulus + 1;
            
            if env.dyn.durationOfStimulus > env.net.myrandi(1,1,env.fix.stimulusMinDurationSteps,env.fix.stimulusMaxDurationSteps)
                
                env.dyn.durationOfStimulus = 0;
                
                env.dyn.currentStimulus = env.net.myrandi(1,1,1,env.par.nrStimuli);

                if env.par.phase == 1
                    while env.dyn.currentStimulus < 31 && env.dyn.currentStimulus > 10
                        env.dyn.currentStimulus = env.net.myrandi(1,1,1,env.par.nrStimuli);
                    end
                end
                if env.par.phase == 2
                    while (env.dyn.currentStimulus < 11 && env.dyn.currentStimulus > 0) ||...
                            (env.dyn.currentStimulus < 31 && env.dyn.currentStimulus > 20)
                        env.dyn.currentStimulus = env.net.myrandi(1,1,1,env.par.nrStimuli);
                    end
                end
                if env.par.phase == 3
                    while env.dyn.currentStimulus < 21 && env.dyn.currentStimulus > 0
                        env.dyn.currentStimulus = env.net.myrandi(1,1,1,env.par.nrStimuli);
                    end
                end
                
                env.stimuli = zeros(env.par.nrStimuli,1);
            end
            
            env.stimuli(env.dyn.currentStimulus) = 1;
                  
            if env.dyn.stepsToReward == 0
                env.currentModulation = env.ser.nextModulation;
            else
                env.currentModulation = 0;
            end
            
        end
        
        function readOutput(env)
            
            env.dyn.action = env.net.dyn.indexWinningNeuron;   % returns WTA from net
            
            env.dyn.rewardingActionIndices = find(env.IOrewardingMap(:,1) == env.log.stimuli(env.ser.currentStep - 1));
            
            if size(env.dyn.rewardingActionIndices,1) > 0
                disp(['S: ' num2str(env.ser.currentStep) ' R-stimulus nr: ' num2str(env.IOrewardingMap(env.dyn.rewardingActionIndices(1),1))...
                    ' action is ' num2str(env.dyn.action)]);
                % if there is at least one action paired with the current
                % stimulus
                if sum(env.dyn.action == env.IOrewardingMap(env.dyn.rewardingActionIndices, 2)) > 0
                    disp([' -- stimuli-action ' num2str(env.log.stimuli(env.ser.currentStep - 1))...
                        '/' num2str(env.dyn.action) ' matching reward conditions']);
                    if env.dyn.stepsToReward <= 0
                        env.dyn.stepsToReward = env.net.myrandi(1, 1, round(env.par.minTimeToReward/env.par.samplingTime), round(env.par.maxTimeToReward/env.par.samplingTime));
                        env.ser.nextModulation = 1;
                    end
                   
                end
            end

        end
       
        function takeLogs(env)
             env.log.stimuli(env.ser.currentStep) = env.dyn.currentStimulus;
             env.log.actions(env.ser.currentStep) = env.dyn.action;

        end
        
        
        function stopRunning(env)
            env.stimuli = zeros(9,1);
            env.ser.actionCompleted = 1;
        end
        
        function keypressed(env, src, evt)
            %disp(evt.Key);
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
            
            
            env.fig.mod = subplot('Position',[0.09 0.81 0.2 0.17],'Parent',env.fig.genPanel);
            env.fig.thresholds = subplot('Position',[0.35 0.81 0.25 0.17],'Parent',env.fig.genPanel);
            env.fig.rcrates = subplot('Position',[0.68  0.81 0.25 0.17],'Parent',env.fig.genPanel);
            
            env.fig.etraces = subplot('Position',[0.04 0.05 0.25 0.31],'Parent',env.fig.genPanel);
            env.fig.outputs = subplot('Position',[0.35 0.05 0.20 0.31],'Parent',env.fig.genPanel);
            env.fig.weights = subplot('Position',[0.6 0.05 0.35 0.3],'Parent',env.fig.genPanel);
            env.fig.weights2 = subplot('Position',[0.7 0.45 0.25 0.3],'Parent',env.fig.genPanel);
            
            env.fig.STW = subplot('Position',[0.35 0.45 0.31 0.31],'Parent',env.fig.genPanel);
            env.fig.LTW = subplot('Position',[0.03 0.45 0.25 0.31],'Parent',env.fig.genPanel);
            
            
        end
        
        function refreshGraphs(env)
                        
            if env.fig.on == 1
                
                plot(env.net.log.modulation,'Parent',env.fig.mod);
                set(env.fig.mod,'XLim',[1 env.net.dyn.currentStep-1],'YGrid','on');
                ylabel(env.fig.mod,'Modulation');
                
                plot([env.net.log.thresholdCor(max(1, env.net.dyn.currentStep - 999):env.net.dyn.currentStep)'...
                    env.net.log.thresholdDec(max(1, env.net.dyn.currentStep - 999):env.net.dyn.currentStep)'],'Parent',env.fig.thresholds);
                ylabel(env.fig.thresholds,'Thresholds');
                %set(env.fig.outputs,'XLim',[1 env.net.dyn.currentStep-1],'YGrid','on');
                
                
                plot([env.net.log.RCrate(max(1, env.net.dyn.currentStep - 999):env.net.dyn.currentStep)'...
                    env.net.log.RDrate(max(1, env.net.dyn.currentStep - 999):env.net.dyn.currentStep)'],'Parent',env.fig.rcrates);
                ylabel(env.fig.rcrates,'RC rate');
                
                plot(env.net.dyn.neuralOutputs,'Parent',env.fig.outputs);
                
                if env.par.phase == 1
                bar(full(env.net.dyn.wST1),'Parent',env.fig.weights);
                bar(full(env.net.dyn.wLT1),'Parent',env.fig.weights2);
                end
                if env.par.phase == 2
                bar(full(env.net.dyn.wST2),'Parent',env.fig.weights);
                bar(full(env.net.dyn.wLT2),'Parent',env.fig.weights2);
                end
                
                set(env.fig.weights,'YLim',[-1 1],'XLim',[1 10],'XGrid','on','YGrid','on');
                title(env.fig.weights,'weights');
                set(env.fig.weights2,'YLim',[-1 1],'XLim',[1 10],'XGrid','on','YGrid','on');
                title(env.fig.weights2,'LT weights on diag');
                
                
                mesh(full(env.net.dyn.eTraces(:,(env.par.nrStimuli + 1):env.par.nrStimuli + env.par.nrActions)),'Parent',env.fig.etraces)
                set(env.fig.etraces,'XLim',[1 20],'ZLim',[-1 1]);
                title(env.fig.etraces,'e traces');
                
                colormap('gray');
                image(full((1 + env.net.dyn.shortTermW(:,(env.par.nrStimuli + 1):env.par.nrStimuli + env.par.nrActions)) / 2 * 70)','Parent',env.fig.STW)
                title(env.fig.STW,'short term w');
                
                
                %  view(env.fig.STW,[0.5 90]);
                %shading faceted;
                %set(env.fig.STW,'YLim',[1 env.par.nrStimuli+env.par.nrActions]);
                set(env.fig.STW,'YLim',[0.5 env.par.nrActions+0.5]);
                set(env.fig.STW,'XLim',[0.5 50.5]);
                
                % colormap('pink');
                
                image(full((1 + env.net.dyn.longTermW(:,(env.par.nrStimuli + 1):env.par.nrStimuli + env.par.nrActions)) / 2 * 70)','Parent',env.fig.LTW);
                set(env.fig.LTW,'YLim',[0.5 env.par.nrActions + 0.5]);
                set(env.fig.LTW,'XLim',[0.5 40.5]);
                
                
                title(env.fig.LTW,'long term weight');
                
                pause(0.1);
            end
        end
    end
end
