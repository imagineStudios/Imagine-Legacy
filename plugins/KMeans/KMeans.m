function xArgOut = KMeans(sMode, dImg, iSeed, hDrawFcn, cParams)
%REGIONGROWING A 2D/3D region growing algorithm plugin for imagine3D
%
%   lMASK = REGIONGROWING(dIMG, dMAXDIF, iSEED) Returns a binary mask
%   lMASK, the result of growing a region from the seed point iSEED.
%   The stoping critereon is fulfilled if no voxels in the region's
%   4-neighbourhood have an intensity difference smaller than dMAXDIF to
%   the region's mean intensity.
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
    % The tooltip context: Simply return a tooltip string
    case 'tooltip'
        xArgOut = 'K-Means';
    % End of the tooltip context
    % ---------------------------------------------------------------------    
    
    % ---------------------------------------------------------------------
    % The input context: Return input type: 'roi', 'seed', or 'start'
    case 'input', xArgOut = 'start';
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % The parameter context: Return a struct with a list of parameters
    case 'params'
        xArgOut = struct( ...
            'Name',         {  'Classes',  'Power'},...
            'Type',         {  'integer', 'double'}, ...
            'Min',          {          2,        1}, ...
            'Max',          {        255,       10}, ...
            'Def',          {          3,        2});
    % End of the parameter context        
    % ---------------------------------------------------------------------
        
    % ---------------------------------------------------------------------
    % The execution context
    case 'exe'
        
        iMAXITER = 20;

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Check the input arguments
        dImg = single(dImg);
        
        iNClasses = uint16(cParams{1});
        dPower    = double(cParams{2});
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Start the kmeans clustering
        dCentroids = single(linspace(min(dImg(:)), max(dImg(:)), iNClasses));
        iSize = size(dImg);
        dImg = dImg(:);
        
        iN = length(dImg);

        iC = zeros(iN, 1, 'uint8');
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Main iteration loop.
        for iI = 1:iMAXITER
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            %Calculate new probabilities
            dProb = (repmat(dCentroids, [iN, 1]) - repmat(dImg, [1, iNClasses])).^2;
            dProb = (dProb + eps).^(1./(1 - dPower));
            dPnorm = sum(dProb, 2);
            dPnorm = repmat(dPnorm, [1, iNClasses]);
            dProb = dProb./dPnorm;
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Hard clustering
            iCOld = iC(:);
            [temp, iC] = max(dProb, [], 2);
            iC = uint8(iC);
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Exit if less that 1% change
            if sum(iCOld ~= iC) < iN./100
                iC = reshape(iC, iSize);
                break;
            end
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Draw
            iC = reshape(iC, iSize);
            hDrawFcn(iC);
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Calculate new centroids.
            dPPower = dProb.^dPower;
            dCentroids = (dPPower'*dImg)'./sum(dPPower);
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        xArgOut = iC;
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    % end of the execution context
    % ---------------------------------------------------------------------
    
    otherwise
        xArgOut = [];

end
% of the switch statement
% -------------------------------------------------------------------------

% =========================================================================
% *** END FUNCTION RegionGrowing
% =========================================================================