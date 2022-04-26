classdef netSimRECO < netSim
      
    methods
        function net = netSimRECO(param)
            
            net = net@netSim(param);
            
            % overwrite parent parameters here if necessary
                        
            disp('Initialising...');
            
            net.validateParameters();
            net.initialiseFixedNetworkFeatures(param);
            net.initialiseDynamicVariables();
            net.initialiseLogVariables();
            disp('Initialisation complete.');
            
        end
        
        function [] = logCurrentStep(net)
            logCurrentStep@netSim(net);
            
            % Need to log more things? add them here.
            net.dyn.wST1 = diag(net.dyn.shortTermW(1:10, net.par.nrStimuli + 1:net.par.nrStimuli  +10));
            net.dyn.wST2 = diag(net.dyn.shortTermW(11:20, net.par.nrStimuli + 6:net.par.nrStimuli + 15));
            net.dyn.wST3 = diag(net.dyn.shortTermW(21:30, net.par.nrStimuli + 1:net.par.nrStimuli + 10));
           
            net.log.wsumST1(net.dyn.currentStep) = sum(net.dyn.wST1(1:10));
            net.log.wsumST2(net.dyn.currentStep) = sum(net.dyn.wST2(1:10));
            net.log.wsumST3(net.dyn.currentStep) = sum(net.dyn.wST3(1:10));
            
            net.dyn.wLT1 = diag(net.dyn.longTermW(1:10,net.par.nrStimuli + 1:net.par.nrStimuli + 10));
            net.dyn.wLT2 = diag(net.dyn.longTermW(11:20,net.par.nrStimuli + 6:net.par.nrStimuli + 15));
            net.dyn.wLT3 = diag(net.dyn.longTermW(21:30,net.par.nrStimuli + 1:net.par.nrStimuli + 10));
           
            net.log.wsumLT1(net.dyn.currentStep) = sum(net.dyn.wLT1(1:10));
            net.log.wsumLT2(net.dyn.currentStep) = sum(net.dyn.wLT2(1:10));
            net.log.wsumLT3(net.dyn.currentStep) = sum(net.dyn.wLT3(1:10));
            
            
        end

        function [] = initialiseLogVariables(net)
            initialiseLogVariables@netSim(net);
            
            net.log.wsumLT1 = zeros(net.fix.totalSteps,1);
            net.log.wsumLT2 = zeros(net.fix.totalSteps,1);
            net.log.wsumLT3 = zeros(net.fix.totalSteps,1);
            net.log.wsumST1 = zeros(net.fix.totalSteps,1);
            net.log.wsumST2 = zeros(net.fix.totalSteps,1);
            net.log.wsumST3 = zeros(net.fix.totalSteps,1);

        end
        
        function [] = setOneSynapseOC(net)
            % pick one random A neuron, repeat to change the precise neuron chosen.
            net.fix.neuronB       = net.myrandi(1,1,1,net.par.nrExcitatory);
            
            net.fix.neuronB       = 1;
            
            net.fix.connectivity(net.fix.neuronB,:) = 0;
            net.fix.plasticityMatrix(net.fix.neuronB,:) = 0;
            
            afferentNeurons = find(net.fix.connectivity(:,net.fix.neuronB) == 1);
            
            net.fix.neuronA1 = afferentNeurons(1);
            %            net.fix.neuronA2 = afferentNeurons(2);
            %            net.fix.neuronA3 = afferentNeurons(3);
            
            net.fix.connectivity(:,net.fix.neuronA1) = 0;
            %            net.fix.connectivity(:,net.fix.neuronA2) = 0;
            %            net.fix.connectivity(:,net.fix.neuronA3) = 0;
            net.fix.plasticityMatrix(:,net.fix.neuronA1) = 0;
            %           net.fix.plastictyMatrix(:,net.fix.neuronA2) = 0;
            %           net.fix.plastictyMatrix(:,net.fix.neuronA3) = 0;
            
            net.dyn.longTermW(net.fix.neuronA1,net.fix.neuronB) = 0;
            %       net.dyn.longTermW(net.fix.neuronA2,net.fix.neuronB) = 0;
            %       net.dyn.longTermW(net.fix.neuronA3,net.fix.neuronB) = 0;
            
            
        end
                
        function [] = validateParameters(net)
            validateParameters@netSim(net);
        end
    end
end



