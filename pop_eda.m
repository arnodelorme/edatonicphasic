% POP_EDA - create tonic and phasic channel for electro-dermal channel
%           (also know as GSR)
%
% Usage:
%   >> OUTEEG = pop_eda(INEEG, 'key1', value1, 'key2', value2 ...);
%
% Inputs:
%   INEEG         - input EEG dataset structure
%
% Optional inputs
%   'channel'     - [integer|string] channel index containing the EDA
%                   signal
%   'method'      - ['cvxEDA'|'fieldtrip'] method to compute tonic and
%                   phasic component of the EDA channel 
%   'methodparams' - [cell] additional method parameters
%
% Outputs:
%   OUTEEG        - new EEG dataset structure with additional EDA-related 
%                   channel and addition OUTEEG.eda structure (cvxEDA
%                   method only)
% 
% Author: Arnaud Delorme, SCCN/INC/UCSD, 2023-
% 
% see also: EEGLAB

% Copyright (C) 2023 Arnaud Delorme
%
% This file is part of EEGLAB, see http://www.eeglab.org
% for the documentation and details.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

function [EEG, com] = pop_eda( EEG, varargin)

com = '';
if nargin < 1
    help pop_eda;
    return;
end
    
if nargin < 2
   geometry = { 1 [1 1 0.51] [1 1] [1 1]};
   methods  = { 'cvxEDA' 'fieldtrip' };
   uilist = { ...
         { 'Style', 'text', 'string', 'Compute tonic and phasic component of EDA channel', 'fontweight', 'bold'  }, ...
         ...
         { 'Style', 'text', 'string', 'EDA channel' }, ...
         { 'Style', 'edit', 'string', '', 'tag', 'chans' }, ...
         { 'style' 'pushbutton' 'string'  '...', 'enable' fastif(isempty(EEG(1).chanlocs), 'off', 'on') ...
           'callback' 'pop_chansel(get(gcbf, ''userdata''), ''field'', ''labels'',   ''handle'', findobj(''parent'', gcbf, ''tag'', ''chans''));' }, ...
           ...
         { 'Style', 'text', 'string', 'Computation method' }, ...
         { 'Style', 'popupmenu', 'string', methods, 'tag', 'method' }, ...
         ...
         { 'Style', 'text', 'string', 'Method parameter(s)' }, ...
         { 'Style', 'edit', 'string', '', 'tag', 'methodparams' } };
   [results,~,~,res] = inputgui( 'geometry', geometry, 'uilist', uilist, 'helpcom', 'pophelp(''pop_eda'');', 'title', 'Process EDA channel -- pop_eda()', 'userdata', EEG(1).chanlocs );
   if isempty(results), return; end

   args = { 'channel' res.chans 'method' methods{res.method} 'methodparams' eval(['{' res.methodparams '}']) };

else
    args = varargin;
end

% process multiple datasets
% -------------------------
if length(EEG) > 1
    if nargin < 2
        [ EEG, com ] = eeg_eval( 'pop_select', EEG, 'warning', 'on', 'params', args);
    else
        [ EEG, com ] = eeg_eval( 'pop_select', EEG, 'warning', 'off', 'params',args);
    end
    return;
end
        
g = finputcheck(args, { 'channel'   { 'integer','string' }  []   [];
                        'method'    'string'              { 'fieldtrip' 'cvxEDA' }   'cvxEDA';
                        'methodparams'   'cell'    { }  {}}, 'pop_eda');
if ischar(g), error(g); end
g.channel = eeg_chaninds(EEG.chanlocs, g.channel);
if isempty(g.channel)
    error('You need to specify a channel')
end

if EEG.srate > 20
    fprintf('Warning: EDA data sampled higher than 20 Hz; you might want to resample the data to 20 Hz\n')
end

if strcmpi(g.method, 'cvxEDA')
    [phasic, sparsep, tonic, toniccoef, offset, residuals, obj] = cvxEDA(zscore(double(EEG.data(g.channel,:)')), 1/EEG.srate, g.methodparams{:});
    EEG.data(end+1,:) = phasic;
    EEG.data(end+1,:) = sparsep;
    EEG.data(end+1,:) = tonic;
    EEG.data(end+1,:) = residuals;
    EEG.eda.toniccoef = toniccoef;
    EEG.eda.offset    = offset;
    EEG.eda.obj       = obj;

    if ~isempty(EEG.chanlocs)
        if ~isfield(EEG.chanlocs, 'type') || isempty(EEG.chanlocs(g.channel).type)
            EEG.chanlocs(g.channel).type = 'GSR';
        end
        EEG.chanlocs(end+1).labels = [ EEG.chanlocs(g.channel).labels '-phasic' ];
        EEG.chanlocs(end  ).type   = 'GSR';
        EEG.chanlocs(end+1).labels = [ EEG.chanlocs(g.channel).labels '-sparse-phasic' ];
        EEG.chanlocs(end  ).type   = 'GSR';
        EEG.chanlocs(end+1).labels = [ EEG.chanlocs(g.channel).labels '-tonic' ];
        EEG.chanlocs(end  ).type   = 'GSR';
        EEG.chanlocs(end+1).labels = [ EEG.chanlocs(g.channel).labels '-residual' ];
        EEG.chanlocs(end  ).type   = 'GSR';
    end
    fprintf('Four additional EDA channels have been added\n')
else
    data = eeglab2fieldtrip(EEG, 'raw');
    if ~isempty(g.methodparams)
        cfg = struct(g.methodparams{:});
        elsec
        cfg = [];
    end
    if EEG.trials == 1
        cfg.feedback = 'yes';
    else
        cfg.feedback = 'no';
    end
    cfg.channel = g.channel;
    eda = ft_electrodermalactivity(cfg, data);
    tmpdata = [ eda.trial{:} ];
    EEG.data(end+1,:) = tmpdata(1,:);
    EEG.data(end+1,:) = tmpdata(2,:);

    if ~isempty(EEG.chanlocs)
        if ~isfield(EEG.chanlocs, 'type') || isempty(EEG.chanlocs(g.channel).type)
            EEG.chanlocs(g.channel).type = 'GSR';
        end
        EEG.chanlocs(end+1).labels = [ EEG.chanlocs(g.channel).labels '-' eda.label{1} ];
        EEG.chanlocs(end  ).type   = 'GSR';
        EEG.chanlocs(end+1).labels = [ EEG.chanlocs(g.channel).labels '-' eda.label{2} ];
        EEG.chanlocs(end  ).type   = 'GSR';
    end
    fprintf('Two additional EDA channels have been added\n')
end

% generate command
if nargout > 1
    com = sprintf('EEG = pop_eda( EEG, %s);', vararg2str(args));
end
