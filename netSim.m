% Developed in May-September 2013 by Andrea Soltoggio, 
%in collaboration with Albert Mukovskiy


classdef netSim < handle
    
    properties
        
        par;                            % network parameters
        dyn;                            % variable computing neural dynamics
        fix;                            % fixed features of the network (build from parameters)
        
        log;                            % logging variables
        graph;                          % graphic objects
        
    end
    
    methods
        function net = netSim(param)
            
            %% Parameter settings (given)
            
            net.par.samplingTime                        =  param.samplingTime;
            net.par.connectivityCase                    =  param.connectivityCase;
            % 0 random connectitivy (no self connections)
            % 1 regular random (equal number of incoming and outgoing connections)
            % 2 feedforward fully connect (no inhib)
            net.par.seedNumber = param.seed;
            net.par.simTime    = param.simTime;
            
            % if 1, the output neurons can be high only one at at time
            net.par.WTAonOutputs                        = param.WTAonOutputs;
            net.par.strengthOfWTAFeedback               = param.strengthOfWTAFeedback;          
            
            net.par.nrNeurons                           = param.nrNeurons;
            net.par.nrExcitatory                        = param.nrExcitatory;
            net.par.nrInhibitory                        = net.par.nrNeurons - net.par.nrExcitatory;
            
            % probability of one connection to exist between two neurons
            net.par.probConnect                         = param.probConnect;
            net.par.nrStimuli                           = param.nrStimuli;
            net.par.nrOutputs                           = param.nrOutputs;
            
            net.par.shortTW_TC                          = param.shortTW_TC; 
            net.par.transmissionNoiseFactor             = param.transmissionNoiseFactor;
            net.par.activationFactor                    = param.activationFactor; 
            net.par.conversionToLTW                     = param.conversionToLTW;
            net.par.targetRCPercentPerSecond            = param.targetRCPercentPerSecond;
            net.par.baseModulation                      = param.baseModulation; 
            net.par.adaptiveThetaThresholds             = param.adaptiveThetaThresholds;
            net.par.adaptiveThetaLo                     = param.adaptiveThetaLo;
            net.par.initialThetaLo                      = param.initialThetaLo;
            net.par.initialThetaHi                      = param.initialThetaHi;
            net.par.weightInitValue                     = param.weightInitValue;
            
            net.par.maxLTWeight                         = param.maxLTWeight;
            net.par.minLTWeight                         = param.minLTWeight;
            net.par.maxSTWeight                         = param.maxSTWeight;
            net.par.minSTWeight                         = param.minSTWeight;
            net.par.STW_updateRate                      = param.STW_updateRate;


            %% Paremeter settings (internal)
            
            net.par.nrNeuronsInGroup                   = 1;     % number of neurons in an input group
            net.par.nrNeuronsOutGroup                  = 1;     % number of neurons in an output group
            
            net.par.eTracesTC                          = 4;     % eligibility traces time constant (4 seconds)
            net.par.modTC                              = 0.1;   % mod time constant
            net.par.inhibWeightStrength                = 1;     % fixed weight of inhibitory synapses
            
            net.par.durationMonitoringWindow           = 5.0;   % duration is seconds of the sliding window, that 
                                                                % monitors the number of rare correlations

            net.par.corrTollerance                     = 2;     % multiplication/division factor for upper and lower tolerance
            net.par.thetaUpdateRate                    = 0.001; % per sec, rate of change in the RCHP thresholds (only for adaptive tresholds)
           
            net.par.traceIncrementWithCor              =  1;    % alfa in Eq. ?? (like in Izhikevich paper)
            net.par.traceDecrementWithDec              = -2;    % beta in Eq. ??
                        
            net.par.shortToLongTWconversionThreshold   = 0.95;  % if conversionToLTW is 1, this parameter set the value at which
                                                                % STW trigger the change of LTW from 0 to 1
            
            net.par.k                                  =[1 -5]; % Kappa in Eq. ?? (effect of excitatory/inhibitory connections)
                                                                % (multiplicative constant for outputs, like in Izhikevich paper)
                        
            net.par.maxModulation                      = 0.5;     % maximum amount of modulatory signal
                        
            net.par.stimuliStrength                    = 12;    % input current added to the activity level of input neurons 
                                                                % when an external signal (input) is received
                                                                
            net.par.STLTconversionRate                 = 1/1200;% conversion rate of weights from ST to LT
            
            
            %% Initialisation of network, variables and logs.
            % Do the following operations in child classes after
            % overwriting parameters
            
            %net.validateParameters(param);
            %net.initialiseFixedNetworkFeatures(param);
            %net.initialiseDynamicVariables(param);
            %net.initialiseLogVariables();
            
        end
        
        function [] = update(net, stimuli, modulation)
            
            net.dyn.stimuli         = stimuli;
            net.dyn.InputModulation      = modulation;
            
            net.readWriteSignalsToNeurons();
            
            net.neuralComputation();
            
            if net.par.WTAonOutputs == 1
                net.WTAactions();
            end
            
            net.computeCorrelations();
            
            net.monitorCorrelations;
            
            net.plasticity;
            
            net.updateTraces;
            
            net.logCurrentStep;
            
            net.dyn.currentStep = net.dyn.currentStep + 1;
            
        end
        
        function [] = readWriteSignalsToNeurons(net)
            
            % uncomment here if you need output groups
            %   net.dyn.output = sum(sum(net.dyn.neuralOutputs(net.fix.outputNeuronsGroups(:,:))))...
            %       /size(net.fix.outputNeuronsGroups,2);
            
            net.dyn.stimuliInputToNeurons = zeros(net.par.nrNeurons,1);    % reset inputs
            
            net.dyn.stimuliInputToNeurons(net.fix.stimuliNeuronsGroups(net.dyn.stimuli >= 1,:)) =...
                net.par.stimuliStrength .* net.par.samplingTime;
            
            net.dyn.modulation =  net.dyn.modulation .* exp(-net.par.samplingTime/net.par.modTC)...
                + net.par.baseModulation * net.par.samplingTime...
                + net.dyn.InputModulation; %...
            
            % clipping modulation
            net.dyn.modulation = min(max(net.dyn.modulation, -1 * net.par.maxModulation),net.par.maxModulation);
            
        end
        
        function [] = neuralComputation(net)
            
            net.dyn.neuralOutputsPrevious = net.dyn.neuralOutputs;
            % computing inputs to outputs
            net.dyn.neuronInputs = net.dyn.stimuliInputToNeurons' +...
                net.dyn.neuralOutputs' * (net.dyn.weightMatrix .* net.fix.connectionTypeStrength);
            
            % computing new outputs and adding noise
            net.dyn.neuralOutputs =  max(tanh(net.par.activationFactor .* net.dyn.neuronInputs),0.0)'...
                + net.mysymrand(net.par.nrNeurons, 1) * net.par.transmissionNoiseFactor;
                        
        end
        
        function [] = WTAactions(net)
            
            net.dyn.durationOfAction = net.dyn.durationOfAction + 1;
            [val val2] = max(net.dyn.neuralOutputs(net.par.nrStimuli + 1:net.par.nrStimuli + net.par.nrOutputs));
            
            if net.dyn.durationOfAction > net.dyn.endOfAction %|| val > 0.4;
                
                net.dyn.endOfAction = net.myrandi(1,1,net.fix.WTAactionMinDurationSteps,net.fix.WTAactionMaxDurationSteps);
                net.dyn.durationOfAction = 0;
                net.dyn.indexWinningNeuron = val2;
                net.dyn.neuralOutputWinner = net.par.strengthOfWTAFeedback;
            end
            
            % set winning output to high
            net.dyn.neuralOutputs(net.dyn.indexWinningNeuron + net.par.nrStimuli) = net.dyn.neuralOutputWinner;
            
        end
        
        function [] = computeCorrelations(net)
            
            net.dyn.allCorr = net.fix.plasticityMatrix...
                .* sparse(net.dyn.neuralOutputsPrevious * net.dyn.neuralOutputs');
            
            % resetting rare correlationa from previous time step
            net.dyn.rareCorr = sparse(net.par.nrExcitatory,net.par.nrNeurons);
            
            % finding rarely correlating synapses
            net.dyn.rareCorr(net.dyn.allCorr(1:net.par.nrExcitatory,:) > net.dyn.thresholdCor) = net.par.traceIncrementWithCor;
            
            net.dyn.nrOfRareCorrPerStep = nnz(net.dyn.rareCorr);
            
            % finding rarely decorrelating synapses
            net.dyn.rareCorr(net.dyn.allCorr(1:net.par.nrExcitatory,:) < net.dyn.thresholdDec) = net.par.traceDecrementWithDec;
            
            net.dyn.nrOfRareDecorrPerStep = nnz(net.dyn.rareCorr == net.par.traceDecrementWithDec);
            
        end
        
        function [] = monitorCorrelations(net)
            % Shifting FIFO
            % case in which the monitorying window has more than one sample, i.e. nearly
            % always
            if net.fix.nrStepsInMonitoringWindow > 1
                net.dyn.FIFOwindowOfNumberOfRareCorr(2:net.fix.nrStepsInMonitoringWindow) =...
                    net.dyn.FIFOwindowOfNumberOfRareCorr(1:net.fix.nrStepsInMonitoringWindow - 1);
                net.dyn.FIFOwindowOfNumberOfRareDecorr(2:net.fix.nrStepsInMonitoringWindow) =...
                    net.dyn.FIFOwindowOfNumberOfRareDecorr(1:net.fix.nrStepsInMonitoringWindow - 1);
                
            end
            net.dyn.FIFOwindowOfNumberOfRareCorr(1) = net.dyn.nrOfRareCorrPerStep;
            net.dyn.FIFOwindowOfNumberOfRareDecorr(1) = net.dyn.nrOfRareDecorrPerStep;
            
            net.dyn.RCpercentPerSecond = sum(net.dyn.FIFOwindowOfNumberOfRareCorr) / (net.fix.nrOfPlasticSynapses * net.par.durationMonitoringWindow) * 100;
            net.dyn.RDpercentPerSecond = sum(net.dyn.FIFOwindowOfNumberOfRareDecorr) / (net.fix.nrOfPlasticSynapses * net.par.durationMonitoringWindow) * 100;
            
            if net.par.adaptiveThetaThresholds == 1
                % too many rare correlations
                if net.dyn.RCpercentPerSecond > net.par.corrTollerance * net.par.targetRCPercentPerSecond
                    net.dyn.thresholdCor = net.dyn.thresholdCor + net.par.thetaUpdateRate * net.par.samplingTime ;
                end
                % too few rare correlations
                if  net.dyn.RCpercentPerSecond < 1/net.par.corrTollerance * net.par.targetRCPercentPerSecond
                    net.dyn.thresholdCor = net.dyn.thresholdCor - net.par.thetaUpdateRate * net.par.samplingTime;
                end
                if net.par.adaptiveThetaLo == 1
                    % too many rare decorrelations
                    if net.dyn.RDpercentPerSecond > net.par.corrTollerance * net.par.targetRCPercentPerSecond
                        net.dyn.thresholdDec = net.dyn.thresholdDec - net.par.thetaUpdateRate * net.par.samplingTime;
                    end
                    % too few rare decorrelations
                    if  net.dyn.RDpercentPerSecond < 1/net.par.corrTollerance * net.par.targetRCPercentPerSecond
                        net.dyn.thresholdDec = net.dyn.thresholdDec + net.par.thetaUpdateRate * net.par.samplingTime;
                    end
                end
            end
        end
        
        function [] = plasticity(net)  % copy localy as new f. inside netSimA
            
            % compute update on STW (short-term weight)
            STW_update = (net.dyn.eTraces(1:net.par.nrExcitatory,:) .* net.dyn.modulation * net.par.STW_updateRate);
            
            % update STW with update and decay
            net.dyn.shortTermW = net.dyn.shortTermW .* exp(-net.par.samplingTime/net.par.shortTW_TC)  + STW_update;
            
            % clipping STW
            net.dyn.shortTermW = min(max(net.dyn.shortTermW, net.par.minSTWeight), net.par.maxSTWeight);
            
            % update LTW when STW reach threshold
            if net.par.conversionToLTW  == 1
                net.dyn.longTermW(1:net.par.nrExcitatory,:) = sparse(net.dyn.longTermW(1:net.par.nrExcitatory,:)) ...
                    +  net.par.STLTconversionRate .* net.par.samplingTime .* sparse(net.dyn.shortTermW > net.par.shortToLongTWconversionThreshold * net.par.maxLTWeight);
            end
            
            % LTW clippling
            net.dyn.longTermW = sparse(max(min(net.dyn.longTermW, net.par.maxLTWeight), net.par.minLTWeight));
            
            % sum STW and LTW to get the overall weight
            net.dyn.weightMatrix = sparse(net.dyn.longTermW + net.dyn.shortTermW);
            
        end
        
        function [] = updateTraces(net)
            
            % traces decay and increase with correlations
            net.dyn.eTraces = sparse (  (net.dyn.eTraces )...
                .* exp(-net.par.samplingTime/net.par.eTracesTC) +...
                net.dyn.rareCorr);
            
            % clipping
            net.dyn.eTraces = max(min(net.dyn.eTraces, net.par.traceIncrementWithCor), net.par.traceDecrementWithDec);
        end
        
        function [] = logCurrentStep(net)
            
            net.log.modulation(net.dyn.currentStep) = net.dyn.modulation;
            net.log.RCrate(net.dyn.currentStep) = net.dyn.RCpercentPerSecond;
            net.log.RDrate(net.dyn.currentStep) = net.dyn.RDpercentPerSecond;
            net.log.thresholdCor(net.dyn.currentStep) = net.dyn.thresholdCor;
            net.log.thresholdDec(net.dyn.currentStep) = net.dyn.thresholdDec;
            
            
        end
        
        function [] = initialiseConnectivity(net)
            
            net.fix.connectivity = sparse(net.par.nrNeurons,net.par.nrNeurons);
            
            % random connectivity
            if net.par.connectivityCase == 0
                net.fix.connectivity = sparse((round(rand(net.par.nrNeurons) + net.par.probConnect - 0.5))...
                    .* (ones(net.par.nrNeurons) - diag(ones(1,net.par.nrNeurons))));
            end
            
            % regular connectivity
            if net.par.connectivityCase == 1
                t_axonCount = zeros(net.par.nrNeurons,1);
                for i = 1:net.par.nrNeurons
                    % disp(['Setting dendrides for neuron ' num2str(i)]);
                    t_avgExcitatoryDendrides = net.par.nrExcitatory * net.par.probConnect;
                    t_dendrides = net.myrandi(1,1, round(t_avgExcitatoryDendrides * 1.00), round(t_avgExcitatoryDendrides * 1.00));
                    t_fromExc = zeros(t_dendrides,1);
                    
                    for j = 1:t_dendrides
                        t_fromExc(j) = net.myrandi(1,1,1,net.par.nrExcitatory);
                        while size(find(t_fromExc == t_fromExc(j)),1) > 1 || t_fromExc(j) == j...
                                || t_axonCount(t_fromExc(j)) > ( net.par.nrNeurons * net.par.probConnect)
                            t_fromExc(j) = net.myrandi(1,1,1,net.par.nrExcitatory);
                        end
                    end
                    t_axonCount(t_fromExc) = t_axonCount(t_fromExc) + 1;
                    
                    t_avgInhibitoryDendrides = net.par.nrInhibitory * net.par.probConnect;
                    t_dendrides = net.myrandi(1,1,round(t_avgInhibitoryDendrides * 0.9), round(t_avgInhibitoryDendrides * 1.1));
                    t_fromInh = zeros(t_dendrides,1);
                    
                    for j = 1:t_dendrides
                        t_fromInh(j) = net.myrandi(1,1,net.par.nrExcitatory+1,net.par.nrNeurons);
                        while size(find(t_fromInh == t_fromInh(j)),1) > 1 || t_fromInh(j) == j...
                                || t_axonCount(t_fromInh(j)) > ( net.par.nrNeurons * net.par.probConnect)
                            t_fromInh(j) = net.myrandi(1,1,net.par.nrExcitatory+1,net.par.nrNeurons);
                        end
                    end
                    t_axonCount(t_fromInh) = t_axonCount(t_fromInh) + 1;
                    net.fix.connectivity(t_fromExc,i) = 1;
                    net.fix.connectivity(t_fromInh,i) = 1;
                end
            end
            
            % for all cases of recurrent connectivitiy:
            if net.par.connectivityCase == 0 || net.par.connectivityCase == 1
                
                % If output neurons do not send signals back to the network, i.e. do
                % not contribute to recurrent connections, uncomment following
                % line:
                %net.fix.connectivity(net.fix.outputNeuronsGroups(:),:) = 0;
                
                % Important: input neurons do not receive inputs from the network
                %net.fix.connectivity(:,net.fix.stimuliNeuronsGroups(:)) = 0;
                
                % inhibitory neurons do not inhibit other inhibitory neurons
                %net.fix.connectivity(net.par.nrExcitatory + 1:net.par.nrNeurons,net.par.nrExcitatory + 1:net.par.nrNeurons) = 0;
                % inhibitory neurons do not inhibit output neuron groups
                
            end
            
            % Feed-forward network
            if net.par.connectivityCase == 2
                
                net.fix.connectivity(1:net.par.nrStimuli,net.par.nrStimuli + 1:net.par.nrOutputs + net.par.nrStimuli) =...
                    (rand(net.par.nrStimuli,net.par.nrOutputs) < net.par.probConnect);
                
            end
        end
        
        function [] = initialiseNeuronGroups(net)
            
            % here group neurons have adjacent indexes
            endIndex = 0;
            
            for i = 1:net.par.nrStimuli
                startIndex = net.par.nrNeuronsInGroup * (i - 1) + 1;
                endIndex = net.par.nrNeuronsInGroup * (i - 1) + net.par.nrNeuronsInGroup;
                indexes = startIndex:endIndex;
                net.fix.stimuliNeuronsGroups(i,:) = indexes;
            end
            
            startIndex = endIndex + 1;
            for i = 1:net.par.nrOutputs
                endIndex = startIndex + net.par.nrNeuronsOutGroup - 1;
                indexes = startIndex:endIndex;
                net.fix.outputNeuronsGroups(i,:) = indexes;
                startIndex = endIndex + 1;
            end
        end
        
        function [] = initialiseFixedNetworkFeatures(net, param)
            
            net.initialiseNeuronGroups();
            net.initialiseConnectivity();
            
            net.fix.WTAactionMinDurationSteps           = param.WTAactionMinDuration /  net.par.samplingTime;
            net.fix.WTAactionMaxDurationSteps           = param.WTAactionMaxDuration /  net.par.samplingTime;

            
            net.fix.neuronTypes = [ones(1,net.par.nrExcitatory) -ones(1,net.par.nrInhibitory)];
            net.fix.connectionType = net.fix.connectivity .* repmat(net.fix.neuronTypes, net.par.nrNeurons, 1)';
            
            net.fix.connectionTypeStrength  = sparse(net.par.nrNeurons, net.par.nrNeurons) ...
                + net.fix.connectivity .* net.par.k(2) .* (net.fix.connectionType == -1)...
                + net.fix.connectivity .* net.par.k(1) .* (net.fix.connectionType == 1);
            
            net.fix.plasticityMatrix = net.fix.connectivity;
            net.fix.plasticityMatrix(net.par.nrExcitatory + 1:net.par.nrNeurons,:) = 0;
            
            net.fix.nrOfSynapses            = nnz(net.fix.connectivity);
            net.fix.nrOfPlasticSynapses     = nnz(net.fix.plasticityMatrix);
            
            net.fix.totalSteps              = 1/net.par.samplingTime * net.par.simTime;
            net.fix.nrStepsInMonitoringWindow           = net.par.durationMonitoringWindow /net.par.samplingTime;
        end
        
        function [] = initialiseDynamicVariables(net, param)
            net.dyn.stimuli                             = zeros(net.par.nrStimuli, 1);
            net.dyn.stimuliInputToNeurons               = zeros(net.par.nrNeurons, 1);
            % nrNeurons x 1 vector feeding neurons with external input
            
            net.dyn.neuronInputs            = zeros(net.par.nrNeurons, 1);
            net.dyn.neuralOutputs           = zeros(net.par.nrNeurons, 1);
            net.dyn.neuralOutputsPrevious   = zeros(net.par.nrNeurons, 1);
            % similar to neuralOutput but remembers the values of the
            % previous step. Necessary to compute the Hebbian product
            % 1-step episodes with such minimum interval
            
            net.dyn.weightMatrix    = sparse(net.par.nrNeurons, net.par.nrNeurons);
            net.dyn.longTermW       = sparse(net.par.nrNeurons, net.par.nrNeurons);
            net.dyn.shortTermW      = sparse(net.par.nrExcitatory, net.par.nrNeurons);
            net.dyn.eTraces         = sparse(net.par.nrExcitatory, net.par.nrNeurons);
            
            net.dyn.longTermW       = ...
                sparse(net.par.maxLTWeight .* net.par.weightInitValue .* net.fix.connectivity);
            
            
            net.dyn.longTermW(net.par.nrExcitatory + 1:net.par.nrNeurons,:) = ...
                sparse(net.par.maxLTWeight .* net.par.inhibWeightStrength .* net.fix.connectivity(net.par.nrExcitatory + 1:net.par.nrNeurons,:));
            
            net.dyn.thresholdCor            = net.par.initialThetaHi;
            net.dyn.thresholdDec            = net.par.initialThetaLo;
            
            net.dyn.FIFOwindowOfNumberOfRareCorr       = zeros(net.fix.nrStepsInMonitoringWindow,1);
            net.dyn.FIFOwindowOfNumberOfRareDecorr     = zeros(net.fix.nrStepsInMonitoringWindow,1);
            
            net.dyn.currentStep             = 3;
            net.dyn.modulation              = 0;
            net.dyn.indexWinningNeuron      = 1;
            net.dyn.durationOfAction        = 0;
            net.dyn.endOfAction             = 0;
            net.dyn.neuralOutputWinner      = 0;
            
        end
        
        function [] = initialiseLogVariables(net)
            net.log.modulation          = zeros(1, net.fix.totalSteps);
            net.log.RCrate              = zeros(1, net.fix.totalSteps);
            net.log.RDrate              = zeros(1, net.fix.totalSteps);
            net.log.thresholdCor        = zeros(1, net.fix.totalSteps);
            net.log.thresholdDec        = zeros(1, net.fix.totalSteps);
        end
        
        function [values] = mysymrand(net, row, col)
            values = randn(row, col);
        end
        
        function [value] = myrandi(net, rows, cols, min_i, max_i)
            value = min_i + round(rand(rows,cols) * (max_i-min_i+1) - 0.5);
            %   value = min_i + round( rand(rows,cols) * (max_i-min_i+1) - 0.5);
            
        end
        
        function [] = validateParameters(net)
            if net.par.samplingTime > 1
                error('The sampling time must be less than or equal to 1 s');
            end
            if rem(1,net.par.samplingTime) > 0
                error('The sampling step must be set such that 1 is a multiple');
            end
        end
    end
end
