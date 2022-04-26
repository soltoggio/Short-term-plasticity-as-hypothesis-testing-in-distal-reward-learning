classdef netSimA < netSim
  
    methods
        function net = netSimA(param)  
            
            net = net@netSim(param);
            
            % overwrite parent parameters here if necessary
            
            net.par.activationFactor            =  0.1;       % or gain in the neural transfer function 
            net.par.transmissionNoiseFactor     =  0.1;       % intensity of noise 
                                                              % (stdev, or interval according to which noise sourse is used, see function mysymrand 
            net.par.weightInitValue             =  0.01;      % initial value of weights 
            net.par.initialThetaHi              =  0.009;     % initial value of threshold thetaHi for detection of high correlations
            net.par.initialThetaLo              = -0.009;     % initial value of threshold thetaLo for detection of low correlations
            net.par.adaptiveThresholds          =  0;         % if 1 the previous two values will chance (adapt) during simulation
            net.par.conversionToLTW             =  0;         % if 1 the weight STW will trigger LTW to be 1 when reaching the threshold shortToLongTWconversionThreshold

            disp('Initialising...');
            net.validateParameters();
            net.initialiseFixedNetworkFeatures(param);
            net.initialiseDynamicVariables(param);
            net.initialiseLogVariables();
            disp('Initialisation complete.');
        end
        
        function [] = update(net, stimuli, modulation)
            update@netSim(net, stimuli, modulation);
        end
        
        function [] = logCurrentStep(net)
            logCurrentStep@netSim(net);
            
            % Need to log more things? add them here.
        end
        
        function [] = initialiseDynamicVariables(net,param)
            initialiseDynamicVariables@netSim(net,param);
            
            % Are there more dynamic variables in the child class that need
            % to be initialised? Do it here.
        end
        
        function [] = validateParameters(net)
            validateParameters@netSim(net);
            
            % Are there more parameters in the child class that need to be
            % validated? Do it here.
        end
    end
end



