classdef SyringePump < handle
    
    properties
        serial
    end
    
    methods
        function obj = SyringePump(comport,baudrate)
            if nargin < 2
                baudrate = 19200;
            end
            
            old = instrfind('Type', 'serial', 'Port', comport, 'Tag', '');
            delete(old);
            
            obj.serial = serial(comport);
            fopen(obj.serial);
            set(obj.serial, 'BaudRate', baudrate);
            set(obj.serial, 'Timeout', 1.0);
            set(obj.serial, 'Terminator', {'ETX','ETX'});
        end
        
        function diam = GetDiameter(obj,address)
            if nargin < 2
                address = 0;
            end
            diam = str2double(obj.SendCommand(address,'DIA'));                                    
        end
        
        function SetDiameter(obj,diam,address)
            if nargin < 3
                address = 0;
            end
            obj.SendCommand(address,['DIA' FloatToString(diam)]);                                                            
        end
        
        function [rate,units] = GetRate(obj,address)
            if nargin < 2
                address = 0;
            end            
            data = obj.SendCommand(address,'RAT');                                    
            S = regexp(data,'(\d+(\.\d+)?)(UM|MM|UH|MH)','tokens','once');            
            if isempty(S)
                error('Invalid response to RAT command from the pump');
            end
            rate = str2double(S{1});                                    
            units = S{2};                                    
        end
        
        function SetRate(obj,rate,units,address)
            if nargin < 4
                address = 0;
            end    
            expectedUnits = {'UM','MM','UH','MH'};
            if ~any(validatestring(units,expectedUnits))
                error('The units of rate should be ''UM'',''MM'',''UH'' or ''MH'', corresponding to µl/min, ml/min, µl/h and ml/h, respectively');
            end
            obj.SendCommand(address,['RAT' obj.FloatToString(rate) units]);                                                            
        end           
        
        function SetVolume(obj,vol,address)
            if nargin < 3
                address = 0;
            end                      
            obj.SendCommand(address,['VOL' obj.FloatToString(vol)]);                                                            
        end
        
        function [vol,units] = GetVolume(obj,address)
            if nargin < 2
                address = 0;
            end          
            data = obj.SendCommand(address,'VOL');                                    
            S = regexp(data,'(\d+(\.\d+)?)(UL|ML)','tokens','once');
            if isempty(S)
                error('Invalid response to VOL command from the pump');
            end            
            vol = num2str(S{1});
            units = num2str(S{2});
        end
        
        function SetDirection(obj,dir,address)
            if nargin < 3
                address = 0;
            end      
            % dir = 0: infuse
            % dir = 1: withdraw
            % dir = 2: reverse pumping, whatever that is
            switch(dir)
                case 0
                    dirStr = 'INF';
                case 1
                    dirStr = 'WDR';
                case 2
                    dirStr = 'REV';
                otherwise
                    error('The pumping direction should be 0 (infuse), 1 (withdraw) or 2 (reverse)');
            end
            obj.SendCommand(address,['DIR' dirStr]);                                                            
        end
        
        function dir = GetDirection(obj,address)
            if nargin < 2
                address = 0;
            end          
            data = obj.SendCommand(address,'DIR');                                    
            if strcmp(data,'INF')
                dir = 0;
            elseif strcmp(data,'WDR')
                dir = 1;
            else
                error('Invalid response to DIR query');
            end
        end               
        
        function Start(obj,phase,address)
            if nargin < 2
                phase = [];
            end          
            if nargin < 3
                address = 0;
            end          
            obj.SendCommand(address,['RUN' floor(phase)]);                                                                        
        end
        
        function Stop(obj,address)
            if nargin < 2
                address = 0;
            end          
            obj.SendCommand(address,'STP');                                                                        
        end
                
        function [data,state] = SendCommand(obj,address,command)
            addressInt = floor(address);
            
            if addressInt < 0 || addressInt > 99
                error('Pump address should be between 0 - 99 (was: %d)',address);
            end
            
            commandJoined = [num2str(addressInt) command];
            
            % TODO: implement safe mode
            response = query(obj.serial, commandJoined, '%s\x0D' ,'\x02%s');
            if response(end) ~= 3
                error('ETX not received in the end of packet');
            end
            response = response(1:(end-1));
            
            [S,nomatch] = regexp(response,'(\d\d?)([IWSPTU]|A\?[RSTEO])(\?(NA|OOR|COM|IGN)?)?','tokens','split','once');            
            state = S{2};
            errorstr = S{3};
            data = nomatch{2};
            
            if strcmp(errorstr,'?')
                error('Pump did not recognize the command');
            elseif strcmp(errorstr,'?NA')
                error('Pump command is not currently applicable');
            elseif strcmp(errorstr,'?OOR')
                error('Pump command data is out of range');
            elseif strcmp(errorstr,'?COM')
                error('Pump received invalid communications packet');
            elseif strcmp(errorstr,'?IGN')
                error('Pump ignored command due to simultaneous Phase start');
            end
        end
        
        function delete(obj)
            if ~isempty(obj.serial)
                delete(obj.serial);
                obj.serial = [];
            end
        end
    end
    
	methods (Static)    
        function str = FloatToString(value)
            % makes sure there's maximum of 3 digits after decimal point
            % as dictated by the protocol
            str = regexprep(sprintf('%.3f', value), '(\.*0+)$', '');
        end        
    end
end

