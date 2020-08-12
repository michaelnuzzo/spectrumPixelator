% % % Functionality
% This class inherits from the audioPlugin class to create a VST.
% The algorithm uses the Modified Discrete Cosine Transform (MDCT)
% to split the audio into its component sine waves.
%
% % % Usage
% To generate the VST, type "generateAudioPlugin Pixelator" into the command
% window.
%
% % % Purpose
% This effect uses the technology of the MDCT to isolate the most
% prominent sine waves in a signal. The prominence sensitivity can be
% altered by the user. Because the MDCT is windowed to reduce
% time-domain aliasing, the size of the window can be altered
% in tandem with the prominence sensitivity to create different
% timbral effects based on the signal. It is inspired by the
% bitcrusher effect and by the "MP3 sound".
%
% % % References
% [1] Princen, J., A. Johnson, and A. Bradley. "Subband/Transform
% Coding Using Filter Bank Designs Based on Time Domain Aliasing
% Cancellation." IEEE International Conference on Acoustics, Speech,
% and Signal Processing (ICASSP). 1987, pp. 2161-2164.
%
% [2] Princen, J., and A. Bradley. "Analysis/Synthesis Filter Bank
% Design Based on Time Domain Aliasing Cancellation." IEEE
% Transactions on Acoustics, Speech, and Signal Processing. Vol. 34,
% Issue 5, 1986, pp. 1153-1161.

% % % Credits
% Created by Michael Nuzzo for the AES Student Matlab Plugin Competition
% Aug 16, 2019
%

classdef spectrumPixelator < audioPlugin
    properties
        % User Interface Parameters
        % These public internal variables are meant to be
        % modified and accessed by the end-user in the GUI.
        
        % This parameter controls the sensitivity of the peak-finding
        % algorithm by altering the minimum prominence trigger.
        freqRes     = 10;
        % This parameter allows expansion of the buffer to sizes
        % not allowed by some DAWs.
        timeRes     = 1;
        % This parameter is a time-aligned dry/wet percentage adjuster
        dryWet      = 100;
    end
    properties (Access = private)
        % These private internal variables can only be accessed
        % by the class methods
        
        % Asynchronous buffer for input audio to allow overlapping
        inCollector;
        % Asynchronous buffer for output audio
        outCollector;
        % Asynchronous buffer for input audio to allow
        % time-synchronization of dry and wet audio
        dry;
        % Stores the environment buffer size
        bufferLength   = 0;
        % Stores the window size
        windowLength  = 0;
        % Stores the number of written samples
        bufferCounter  = 0;
        % Stores Kaiser-Bessel-derived window
        kbdWindow     = 0;
        % Stores second half of MDCT output to allow overlapping
        outputMemory;
    end
    properties (Constant)
        % User Interface mappings and deployment identification
        PluginInterface = audioPluginInterface(...
            audioPluginParameter('freqRes',...
            'DisplayName','Spectral Resolution',...
            'Mapping',{'lin',1,100}),...
            audioPluginParameter('timeRes',...
            'DisplayName','Time Resolution',...
            'Mapping',{'lin',.01,1}),...
            audioPluginParameter('dryWet',...
            'DisplayName','Dry/Wet',...
            'Mapping',{'lin',0,100}),...
            'PluginName','Spectrum Pixelator',...
            'VendorName','Michael Nuzzo',...
            'VendorVersion','1.0.0',...
            'UniqueId','k0m5');
    end
    methods
        function outBuffer = process(plugin,inBuffer)
            % This is the real-time DSP loop. Audio gets passed in to
            % the VST unit here from the DAW, gets processed, then
            % outputted back to the DAW.
            
            % Check to see if this is the first time through, or if
            % the environment buffer or window length have changed.
            if(plugin.bufferLength ~= length(inBuffer) || plugin.windowLength ~= 2*floor(plugin.timeRes*plugin.getSampleRate/2))
                % Store the environment buffer length
                plugin.bufferLength = length(inBuffer);
                % Set all the parameters according to the window length
                reset(plugin);
                plugin.bufferLength
            end
            
            % Default output is 0
            outBuffer = zeros(plugin.bufferLength,2);
            
            for k = 0:floor(plugin.bufferLength/(plugin.windowLength/2))
                % Transfer input buffer to the asynchronous storage buffers
                currentFrame = 1+(k*(plugin.windowLength/2):min((k+1)*(plugin.windowLength/2),plugin.bufferLength-1));
                write(plugin.inCollector,inBuffer(currentFrame,:));
                write(plugin.dry,inBuffer(currentFrame,:));
                
                % Once there are enough input samples that a window is
                % full, start processing.
                if(plugin.inCollector.NumUnreadSamples >= plugin.windowLength/2)
                    % Read a window's worth of samples, and mark half
                    % as being read (50% overlap)
                    mdctInput = read(plugin.inCollector,plugin.windowLength,plugin.windowLength/2);
                    % Convert to frequency domain
                    y_mdct = mdct(mdctInput,plugin.kbdWindow,'PadInput',false);
                    % Convert to decibels
                    y_mdct_db = mag2db(abs(y_mdct));
                    % Peakfinding requires at least three samples
                    if(size(y_mdct_db,1) < 4)
                        % Don't process
                        mask = ones(plugin.windowLength/2,1,2);
                    else
                        % Initialize an empty mask
                        mask = zeros(plugin.windowLength/2,1,2);
                        % For left and right channels
                        for ch = 1:2
                            % Save indices of frequency domain peaks
                            [pks,locs] = findpeaks(y_mdct_db(:,1,ch),'MinPeakProminence',plugin.freqRes);
                            % For each peak index, mark 1 in the mask index
                            mask(locs,ch) = 1;
                        end
                    end
                    % Save only the frequency bins where a peak was detected
                    y_mdct = y_mdct.*mask;
                    % Convert back to time domain with the reduced data
                    mdctOutput = imdct(y_mdct,plugin.kbdWindow,'PadInput',false);
                    % Save the first half plus the previous window's
                    % second half to the output buffer
                    write(plugin.outCollector,mdctOutput(1:(plugin.windowLength/2),:) + plugin.outputMemory(1:(plugin.windowLength/2),:));
                    % Save the second half to memory to add to next window
                    plugin.outputMemory = mdctOutput(end-(plugin.windowLength/2)+1:end,:);
                end
            end
            % If there are enough samples in the output buffer, start
            % playing the processing audio
            if(plugin.outCollector.NumUnreadSamples >= plugin.bufferLength)
                % Calculate the dry/wet mixture
                dry = read(plugin.dry,plugin.bufferLength);
                wet = read(plugin.outCollector,plugin.bufferLength);
                outBuffer = (wet*plugin.dryWet/100)+(dry*(100-plugin.dryWet)/100);
            end
        end
        function plugin = spectrumPixelator()
            % This function is not part of the main DSP loop. It only runs
            % upon initialization.
            
            plugin.inCollector = dsp.AsyncBuffer(1000000);
            plugin.outCollector = dsp.AsyncBuffer(1000000);
            plugin.dry = dsp.AsyncBuffer(1000000);
            plugin.outputMemory = zeros(plugin.windowLength/2,2);
            % This is required to define the dimensions of the
            % output buffer - they are otherwise only defined within
            % an if-statement in the main loop which is not allowed
            write(plugin.outCollector,[0 0;0 0]);
            read(plugin.outCollector,2);
            % initialize with zeros (important)
            write(plugin.dry,zeros(plugin.windowLength/2,2));
            write(plugin.inCollector,zeros(plugin.windowLength/2,2));
        end
        function reset(plugin)
            % This function resets the plugin. It runs automatically upon
            % initialization, if the sample rate is changed, or if the
            % VST is restarted in the DAW.
            
            % Clear contents of all buffers
            reset(plugin.inCollector)
            reset(plugin.outCollector)
            reset(plugin.dry)
            write(plugin.outCollector,[0 0;0 0]);
            read(plugin.outCollector,2);
            % Window length is the next power of 2 up from the current
            % environment buffer length
            plugin.windowLength = 2*floor(plugin.timeRes*plugin.getSampleRate/2);
            if(plugin.windowLength > 0)
                plugin.kbdWindow = kbdwin(plugin.windowLength);
            end
            plugin.outputMemory = zeros(plugin.windowLength/2,2);
            write(plugin.inCollector,zeros(plugin.windowLength/2,2));
        end
    end
end