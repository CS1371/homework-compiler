classdef tcpip < icinterface 
    %TCPIP Construct TCPIP client or server object.
    %
    %   OBJ = TCPIP('RHOST') constructs a TCPIP client or server object,
    %   OBJ, associated with remote host, RHOST, and the default remote
    %   port value of 80.
    %
    %   In order to communicate with the instrument, the object, OBJ, must
    %   be connected to RHOST with the FOPEN function.
    %
    %   OBJ = TCPIP('RHOST', RPORT) constructs a TCPIP object, OBJ,
    %   associated with remote host, RHOST, and remote port value, RPORT.
    %
    %   By default, the TCPIP client support is selected. When the TCPIP
    %   object is constructed, the object's Status property is closed. Once
    %   the object is connected to the host with the FOPEN function, the
    %   Status property is configured to open.
    %
    %   OBJ = TCPIP(..., RPORT, 'P1',V1,'P2',V2,...) construct a TCPIP
    %   object with the specified property values. If an invalid property
    %   name or property value is specified the object will not be created.
    %
    %   Note that the property value pairs can be in any format supported
    %   by the SET function, i.e., param-value string pairs, structures,
    %   and param-value cell array pairs.
    %
    %   The default local host in multi-homed hosts is the systems default.
    %   LocalPort defaults to a value of [], and it causes any free local
    %   port to be picked up as the local port. The LocalPort property is
    %   updated when FOPEN is issued.
    %
    %   A property value pair of 'NetworkRole', 'server' will cause TCPIP
    %   to block and wait for a connection from a single remote client
    %   matching the 'RHOST' when FOPEN is called.  In a trusted
    %   environment, the remote host may be set to the wild card address of
    %   '0.0.0.0' to accept connections from any single client. While a
    %   valid connection is open, the TCPIP RemoteHost will be set to the
    %   address of the client that is connected.
    %
    %   At any time you can view a complete listing of TCPIP functions and
    %   properties with the INSTRHELP function, i.e., instrhelp tcpip.
    %
    %   Client Example:
    %       echotcpip('on',4012) 
    %       t = tcpip('localhost',4012); 
    %       fopen(t)
    %       fwrite(t,65:74) 
    %       A = fread(t, 10); 
    %       fclose(t);
    %       delete(t)
    %       echotcpip('off')
    %
    %   Server Example:
    %       t=tcpip('localhost', 4012, 'NetworkRole', 'server');
    %       fopen(t);  % this will block until a connection is received.
    %
    %   See also ECHOTCPIP, ICINTERFACE/FOPEN, INSTRUMENT/PROPINFO,
    %   INSTRHELP, SENDMAIL, UDP, URLREAD, URLWRITE.
    %
    
    %   Copyright 1999-2017 The MathWorks, Inc.
    
    properties(Hidden, SetAccess = 'public', GetAccess = 'public')
        icinterface
    end    
    
    methods
        function obj = tcpip(varargin)
            defaultPort = 80;
            
            obj = obj@icinterface('tcpip');
            % Create the parent class.
            try
                obj.icinterface = icinterface('tcpip');
            catch %#ok<CTCH>
                error(message('instrument:tcpip:nojvm'));
            end
            
            % convert to char in order to accept string datatype
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);
            
            switch (nargin)
                case 0
                    error(message('instrument:tcpip:invalidSyntax'));
                case 1
                    host = varargin{1};
                    port = defaultPort;
                    props = {};
                case 2
                    host = varargin{1};
                    port = varargin{2};
                    if ~(localIsValidPort(port))
                        error(message('instrument:tcpip:invalidRPORT'));
                    end
                    props = {};
                otherwise
                    % Ex. t = tcpip('144.212.100.10', 8080, 'p','v',...);
                    host = varargin{1};
                    port = varargin{2};
                    if (isa(port,'numeric'))
                        if ~(localIsValidPort(port))
                            error(message('instrument:tcpip:invalidRPORT'));
                        end
                        iniprop = 3;
                    else
                        port = defaultPort;
                        iniprop = 2;
                    end
                    props = varargin(iniprop:end);
            end

            % Set the doc ID for the interface object. This sets values for
            % DocIDNoData and DocIDSomeData
            obj = obj.setDocID('tcpip');

            % parse the host
            if ischar(host)
                % Ex. t = tcpip('144.212.100.10')
                % Call the java constructor and store the java object in the
                % tcpip object.
                if isempty(host)
                    error(message('instrument:tcpip:invalidRHOSTEmpty'));
                end
                try
                    obj.jobject = handle(com.mathworks.toolbox.instrument.TCPIP(host,port));
                catch aException
                    newExc = MException('instrument:tcpip:cannotCreate',aException.message);
                    throw(newExc);
                end
            elseif isa(host, 'tcpip')
                obj = host;
            elseif isa(host, 'com.mathworks.toolbox.instrument.TCPIP')
                obj.jobject = handle(host);
            elseif isa(host, 'javahandle.com.mathworks.toolbox.instrument.TCPIP')
                obj.jobject = host;
            elseif ishandle(host)
                % True if loading an array of objects and the first is a TCPIP object.
                if ~contains(class(host(1)), 'com.mathworks.toolbox.instrument.TCPIP')
                    obj.jobject = host;
                else
                    error(message('instrument:tcpip:invalidRHOST'));
                end
            else
                error(message('instrument:tcpip:invalidRHOST'));
            end
            
            if ~isempty(props)
                % Try setting the object properties.
                try
                    set(obj, varargin{iniprop:end});
                catch aException
                    delete(obj);
                    localFixError(aException);
                end
            end
            
             setMATLABClassName( obj.jobject(1),obj.constructor);
            
            % Pass the OOPs object to java. Used for callbacks.
            if isvalid(obj)
                % Pass the OOPs object to java. Used for callbacks.
                obj.jobject(1).setMATLABObject(obj);
            end
        end
        
    end
    
    methods(Static = true, Hidden = true)
        obj = loadobj(B);
    end
    
end
% *******************************************************************
% Determine if the specified port is in a valid range.
function out = localIsValidPort(port)

out = true;
if (~(isa(port,'numeric') && (port >= 1) && (port <= 65535) && (fix(port) == port)))
    out = false;
end
end

% *******************************************************************
% Fix the error message.
function localFixError (exception)

% Initialize variables.
id = exception.identifier;
errmsg =  exception.message;

% Remove the trailing carriage returns from errmsg.
while errmsg(end) == newline
    errmsg = errmsg(1:end-1);
end

newExc = MException(id, errmsg);
throwAsCaller(newExc);

end