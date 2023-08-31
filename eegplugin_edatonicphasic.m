function vers = eegplugin_edatonicphasic( fig, try_strings, catch_strings )
%EEGLAB plugin for EDA processing
%   Label independent components using ICLabel. Go to
%   https://sccn.ucsd.edu/wiki/ICLabel for a tutorial on this plug-in. Go
%   to labeling.ucsd.edu/tutorial/about for more information. To report a
%   bug or issue, please create an "Issue" post on the GitHub page at 
%   https://github.com/sccn/ICLabel/issues or send an email to 
%   eeglab@sccn.ucsd.edu.
%
%   Results are stored in EEG.etc.ic_classifications.ICLabel. The matrix of
%   label vectors is stored under "classifications" and the cell array of
%   class names are stored under "classes". The matrix stored under
%   "classifications" is organized with each column matching to the
%   equivalent element in "classes" and each row matching to the equivalent
%   IC. For example, if you want to see what percent ICLabel attributes IC
%   7 to the class "eye", you would look at:
%       EEG.etc.ic_classifications.ICLabel.classifications(7, 3)
%   since EEG.etc.ic_classifications.ICLabel.classes{3} is "eye".

% version
vers = 'edatonicphasic1.0';

% input check
if nargin < 3
    error('eegplugin_edatonicphasic requires 3 arguments');
end

% add items to EEGLAB tools menu
menui3 = findobj(fig, 'label', 'Tools');
com = [try_strings.no_check '[EEG LASTCOM] = pop_eda(EEG);' catch_strings.new_and_hist];

uimenu( menui3, 'label', 'Process EDA/GDR data', ...
    'callback', com, 'userdata', 'startup:off;study:on');


