function xArgOut = RegionGrowing(sMode, dImg, iSeed, hDrawFcn, cParams)
%REGIONGROWING A 2D/3D region growing algorithm plugin for imagine3D
%
%   lMASK = REGIONGROWING(dIMG, dMAXDIF, iSEED) Returns a binary mask
%   lMASK, the result of growing a region from the seed point iSEED.
%   The stoping critereon is fulfilled if no voxels in the region's
%   4-neighbourhood have an intensity difference smaller than dMAXDIF to
%   the region's mean intensity.
%
%   If the seed point is not supplied, a GUI lets you select it. If no
%   output is requested, the result of the region growing is visualized
%
% IMPORTANT NOTE: This Matlab function is a front-end for a fast mex
% function. Compile it by making the directiory containing this file your
% current Matlab working directory and typing
%
% >> mex RegionGrowing_mex.cpp
%
% in the Matlab console.
%
%
% Copyright 2013 Christian Wuerslin, University of Tuebingen and
% University of Stuttgart, Germany.
% Contact: christian.wuerslin@med.uni-tuebingen.de

% =========================================================================
% *** FUNCTION RegionGrowing
% ***
% *** See above for description.
% ***
% =========================================================================

switch sMode    %This distinguishes the contexts in which the plugin function is called
    
    % ---------------------------------------------------------------------
    % The tooltip path: Simply return a tooltip string
    case 'tooltip'
        xArgOut = 'Region Growing';
    % End of the tooltip path
    % ---------------------------------------------------------------------    
    
    % ---------------------------------------------------------------------
    % The input context: Return input type: 'roi', 'seed', or 'start'
    case 'input', xArgOut = 'seed';
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % The parameter path: Return a struct with a list of parameters
    case 'params'
        xArgOut = struct( ...
            'Name',         {'Max Dist'},...
            'Type',         {  'double'}, ...
            'Min',          {         0}, ...
            'Max',          {       inf}, ...
            'Def',          {        10});
    % End of the parameter path        
    % ---------------------------------------------------------------------
        
    % ---------------------------------------------------------------------
    % The execution path
    case 'exe'

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Check the input arguments
        dImg = double(dImg);
        iSeed = uint16(iSeed);
        
        dMaxDif = cParams{1};
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % If the mex file has not been compiled yet, try to do so.
        if exist('RegionGrowing_mex') ~= 3
            fprintf(1, 'Trying to compile mex file...');
            sCurrentPath = cd;
            sPath = fileparts(mfilename('fullpath'));
            cd(sPath)
            try
                mex([sPath, filesep, 'RegionGrowing_mex.cpp']);
                fprintf(1, 'done\n');
            catch
                error('Could not compile the mex file :(. Please try to do so manually!');
            end
            cd(sCurrentPath);
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Start the region growing process by calling the mex function
        if isempty(hDrawFcn)
            xArgOut = RegionGrowing_mex(dImg, iSeed, dMaxDif);
        else
            xArgOut = RegionGrowing_mex(dImg, iSeed, dMaxDif, hDrawFcn);
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    % end of the execution path
    % ---------------------------------------------------------------------
    
    otherwise
        xArgOut = [];

end
% of the switch statement
% -------------------------------------------------------------------------

% =========================================================================
% *** END FUNCTION RegionGrowing
% =========================================================================