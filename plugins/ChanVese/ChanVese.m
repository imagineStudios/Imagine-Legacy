function xArgOut = ChanVese(sContext, dImg, lMask, hDrawFcn, cParams)

switch sContext    %This distinguishes the contexts in which the plugin function is called

    % ---------------------------------------------------------------------
    % The tooltip context: Simply return a tooltip string
    case 'tooltip', xArgOut = 'Chan-Vese Segmentation';
    % End of the tooltip path
    % ---------------------------------------------------------------------
    
    % ---------------------------------------------------------------------
    % The input context: Return input type: 'roi', 'seed', or 'start'
    case 'input', xArgOut = 'roi';
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % The parameter context: Return a struct with a list of parameters
    case 'params'
        xArgOut = struct( ...
            'Name',         {'Lambda 1 (Out)', 'Lambda 2',    'Mu', 'Delta T', 'Iterations'},...
            'Type',         {  'double'      ,   'double','double',  'double',    'integer'}, ...
            'Min',          {               0,          0,       0,         0,            1}, ...
            'Max',          {             100,        100,     inf,       inf,           50}, ...
            'Def',          {                1,          1,       1,         4,            5});
    % End of the parameter path
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % The execution context
    case 'exe'
        
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Check the input arguments
        dImg = double(dImg);
        dImg = dImg./max(dImg(:));
        
        dLambda1 = cParams{1};
        dLambda2 = cParams{2};
        dNu      = cParams{3};
        dDeltaT  = cParams{4};
        iNIter   = cParams{5};
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        dPhi = double(lMask);
        dPhi = fCVReinit(dPhi - 0.5);
        lMask = dPhi > 0;
        
        if isa(hDrawFcn, 'function_handle')
            hDrawFcn(lMask);
        elseif ~isempty(hDrawFcn)            
            [iNR, iNC] = fGetRC(size(dImg(:,:,1:hDrawFcn)));
            iInd = round(linspace(1, size(dImg, 3), iNR*iNC));
            
            dDrawImg = fCollage(dImg(:,:,iInd), iNR);
            imshow(dDrawImg./max(dDrawImg(:)));
            hold on
            set(gcf, 'Name', sprintf('CV: Mu_out = %3.2f, Mu_in = %3.2f, Nu = %3.2f, DT = %3.2f', dLambda1, dLambda2, dNu, dDeltaT));
            
            dColormap = [0 0 0; lines(10)];
            iMask = uint8(lMask(:,:,iInd)) + 1;
            dMaskImg = reshape(dColormap(iMask(:), :), [size(iMask), 3]);
            dMaskImg = fCollage(dMaskImg, iNR);
            hMask = image(dMaskImg, 'AlphaData', 0.3);
            drawnow
        end

        fprintf('ChanVese Iteration %02d/%02d', 0, iNIter);
        for iI = 1:iNIter
            fprintf('\b\b\b\b\b%02d/%02d', iI, iNIter);
            
            dPhi = fCVIterate(dImg, dPhi, dNu, dLambda1, dLambda2, dDeltaT);
        
            lMask = dPhi > 0;
            if isa(hDrawFcn, 'function_handle')
                hDrawFcn(lMask);
            elseif ~isempty(hDrawFcn)
                iMask = uint8(lMask(:,:,iInd)) + 1;
                dMaskImg = reshape(dColormap(iMask(:), :), [size(iMask), 3]);
                dMaskImg = fCollage(dMaskImg, iNR);
                set(hMask, 'CData', dMaskImg);
                drawnow
            end
            
        end
        fprintf('\n');
        xArgOut = lMask;
    % end of the execution path
    % ---------------------------------------------------------------------
    
    otherwise, xArgOut = [];
        
end
% of the switch statement
% -------------------------------------------------------------------------



    function dPhi = fCVIterate(dImg, dPhi, dNu, dLambda1, dLambda2, dDeltaT)
        dMuIn  = mean(dImg(dPhi >  0));
        dMuOut = mean(dImg(dPhi <= 0));
        dPhi = fCVReinit(dPhi);
        dPhi = dPhi + dDeltaT.*100.*(dLambda1.*(dImg - dMuOut).^2 - dLambda2.*(dImg - dMuIn).^2);
        dPhi = fCVReinit(dPhi);
        dPhi = ac_div_AOS_3D_dll(dPhi, ones(size(dPhi)), dDeltaT.*dNu);
    end



    function dPhi = fCVReinit(dPhi)
        dPhi0 = zy_binary_boundary_detection(uint8(dPhi > 0));
%         dPhi0 = padarray(dPhi0, [1 1 1]);
        dPhi0 = ac_distance_transform_3d(dPhi0);
%         dPhi0 = dPhi0(2:end - 1, 2:end - 1, 2:end - 1);
        dPhi  = dPhi0.*sign(dPhi);
    end


    function [iNR, iNC] = fGetRC(iSize)
        % -------------------------------------------------------------------------
        % Try to get an ideal grid for the montage
        dScreenSize   = get(0, 'ScreenSize');
        dImgAspect    = iSize(2) /iSize(1);
        dScreenAspect = dScreenSize(3)/dScreenSize(4);
        dCol2RowRatio = dScreenAspect/dImgAspect;
        
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Check all possible combinations of NRows and NCols using prime factor
        % decomposition. If the ratio is bad, pad the image and try again.
        dFit = 1000;
        dTol = 1;
        if iSize(3) > 3, dTol = 0.7; end
        if iSize(3) > 10, dTol = 0.5; end
        
        iNImages = iSize(3);
        while dFit > dTol
            iF = factor(iNImages);
            if isscalar(iF), iF = [iF, 1]; end % If length is a prime number
            
            % Divide the prime factors into two classes, with each class having at
            % least 1 member. Get all combinations
            dRatio = zeros(2.^length(iF) - 2, 1);
            for iC = 1:(2^length(iF) - 2)
                lM = bitget(iC, length(iF):-1:1, 'uint16');
                dRatio(iC) = prod(iF(lM == 1))/prod(iF(lM == 0));
            end
            
            % Determine the optimal combination
            [dFit, iC] = min(abs(log(dRatio/dCol2RowRatio)));
            if dFit > dTol, iNImages = iNImages + 1; end % For next iteration
        end
        lM = bitget(iC, length(iF):-1:1, 'uint16');
        iNC = prod(iF(lM == 1));
        iNR = prod(iF(lM == 0));
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % -------------------------------------------------------------------------
    end



    function dCollage = fCollage(dImg, iNR)
                
        dImg = reshape(dImg, size(dImg, 1), [], size(dImg, 4));
        
        dCollage = zeros(size(dImg, 1)*iNR, size(dImg, 2)/iNR, size(dImg, 3), 'like', dImg);
        for iR = 0:iNR - 1
            dCollage(iR*size(dImg, 1) + 1:(iR + 1)*size(dImg, 1), :, :) = ...
                dImg(:, iR*size(dImg, 2)/iNR + 1:(iR + 1)*size(dImg, 2)/iNR, :);
        end
        
    end

end