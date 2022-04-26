% Developed in May-September 2013 by Andrea Soltoggio and Albert Mukovskiy

classdef netEnvA < netEnv
    
    properties
                
    end
    
    methods
        
        function env = netEnvA(par)
            env = env@netEnv(par);            
            
            % Additional/rewriting parameter for child class
            env.par.simTime                     =  50;             % total max simulation time in s
            env.par.samplingTime                =  0.01;           % sampling time in s
            env.par.nrStimuli                   =  2;              % number of inputs created by the env and given to the net                     
            
            env.par.nrNeurons                   =  2;                 % nr of total neurons in the net (sum of excit and inhib)
            env.par.nrExcitatory                =  env.par.nrNeurons; % nr of excitatory neurons
            env.par.nrOutputs                   =  0;                 % nr of output neurons (exceeding inputs, i.e. not input) one neuron may be only input or output, not both
            env.par.connectivityCase            =  0;                 % (0,1 - fully connected, 2 - feedforward)see netEnv for cases
            env.par.probConnect                 =  1;                 % probability of connection between two neurons (no self connections anyway)
            env.par.WTAonOutputs                =  0;                 % if 0 no WTA (no Winner-Take All)
            env.par.shortTW_TC                  =  3600 * 10000;      % Decay Time-constant for STW (short-time weights): if the value is large,
                                                                      % STW do not decay: useful when not using conversion to LTW (long-time)
                                                                           
            env.par.transmissionNoiseFactor     =  0.05;  % (e.g. STD for gaussian) intensity of noise, see also netEnv
            env.par.activationFactor            =  0.2;   % gain of the output neural function (sigmoid), see net.neuralComputation
            env.par.baseModulation              =  0;     % default level of modulation, see: net.readWriteSignalsToNeurons
            env.par.conversionToLTW             =  0;     % if 0, LTW are not used (in 'net.dyn.weightMatrix'). 
            
            env.par.targetRCPercentPerSecond    =  0.5;   % target percent of rare correlations: only for adaptive thresholds
            
            env.par.adaptiveThetaThresholds     =  1;     % if 0, theta thresholds are not adaptive (not for 2-neurons)
            env.par.adaptiveThetaLo             =  0;     % if 0, thataLo is not adaptive
            env.par.initialThetaHi              =  0.2;   % initial value of thetaHi, particularly important if thresholds are not adaptive
            env.par.initialThetaLo              = -0.2;   % initial value of thetaLo, particularly important if thresholds are not adaptive
            
            env.par.maxSTWeight                 =  1.0;   % max value for STW weights
            env.par.minSTWeight                 =  0.0;   % min value for STW weights
            env.par.maxLTWeight                 =  1.0;   % max value for LTW weights
            env.par.minLTWeight                 =  0.0;   % min value for LTW weights
            env.par.weightInitValue             =  0.0;   % value of weights after initialisation
            env.par.STW_updateRate              =  1/10;  % learning rate for weight change, see net.plasticity

            
            % starting net and variables
            env.net = netSimA(env.par);

            env.initialiseRuntimeVariables();     
            
            env.showSettings();

        end
        
        function initialiseRuntimeVariables(env)
            initialiseRuntimeVariables@netEnv(env)
            
            % child runtime variable here:
            
            env.fix.inputstreams = 0.5 * rand(env.fix.totalSteps , 2) + 0.25; % random but filtered inputs
            
            ff=[0.1 0.3 0.8 1.2 0.8 0.3 0.1]; % from A.M.'s code
            ff = ff/norm(ff);
            env.fix.inputstreams = filter(ff,[2 1], env.fix.inputstreams,[],1);
            env.fix.d = round(rand(env.fix.totalSteps,1)-0.45);
            
            % initialising log variables
            env.log.Outputs = zeros(env.fix.totalSteps, env.par.nrNeurons);
            env.log.NeuralActivities = zeros(env.fix.totalSteps, env.par.nrNeurons);
            env.log.weights = zeros(env.fix.totalSteps,2);
            env.log.eTraces = zeros(env.fix.totalSteps,2);
                        
        end
        
        function writeStimuli(env)
            
            env.stimuli(1:2) = env.fix.inputstreams(env.ser.currentStep,1:2);
            env.currentModulation = env.fix.d(env.ser.currentStep);
            
        end
        
        function readOutput(env)
                        
        end
        
        function takeLogs(env)
            
            env.log.Outputs(env.ser.currentStep,:) = env.net.dyn.neuralOutputs;
            env.log.Activities(env.ser.currentStep,:) = (env.net.par.activationFactor .* env.net.dyn.neuronInputs); 
            env.log.weights(env.ser.currentStep,:) = [env.net.dyn.weightMatrix(1,2) env.net.dyn.weightMatrix(2,1)];
                
            env.log.eTraces(env.ser.currentStep,:) = [env.net.dyn.eTraces(1,2) env.net.dyn.eTraces(2,1)];
        end
        
        function createWindow(env)
            createWindow@netEnv(env);
            
            %   env.fig.splot{1} = subplot('Position',[0.09 0.81 0.2 0.17],'Parent',env.fig.genPanel);
            %   env.fig.splot{2} = subplot('Position',[0.35 0.81 0.25 0.17],'Parent',env.fig.genPanel);
            %   env.fig.splot{3} = subplot('Position',[0.68  0.81 0.25 0.17],'Parent',env.fig.genPanel);
            
            %   env.fig.splot{4} = subplot('Position',[0.09 0.05 0.31 0.31],'Parent',env.fig.genPanel);
            %   env.fig.splot{5} = subplot('Position',[0.51 0.45 0.31 0.31],'Parent',env.fig.genPanel);
            %   env.fig.splot{8} = subplot('Position',[0.09 0.45 0.31 0.31],'Parent',env.fig.genPanel);
            
            
        end
        
        function refreshGraphs(env)
            
            pause(0.1);
        end
        
        function plotFinalResults(env)
            
            h=figure; set(h,'position', [5, 35, 520, 840]);
            subplot(6,1,1), plot(env.fix.inputstreams); title('Inputs');
            subplot(6,1,2), plot(env.fix.d); title('Rewards');
            subplot(6,1,3), plot(env.log.eTraces); title('Eligibility traces');
            subplot(6,1,4), plot(env.log.weights); title('Weights');
            subplot(6,1,5), plot(env.log.Outputs); title('Neural Outputs');
            subplot(6,1,6), plot(env.log.Activities); title('Neural Activations');
            
        end
    end
end
