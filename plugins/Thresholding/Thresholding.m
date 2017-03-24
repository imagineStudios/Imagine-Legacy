function xArgOut = Thresholding(sContext, dImg, lMask, hDrawFcn, cParams)

switch sContext    %This distinguishes the contexts in which the plugin function is called

    % ---------------------------------------------------------------------
    % The tooltip context: Simply return a tooltip string
    case 'tooltip', xArgOut = 'Thresholding';
    % End of the tooltip path
    % ---------------------------------------------------------------------
    
    % ---------------------------------------------------------------------
    % The input context: Return input type: 'roi', 'seed', or 'start'
    case 'input', xArgOut = 'start';
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % The parameter context: Return a struct with a list of parameters
    case 'params'
        xArgOut = [];
    % End of the parameter path
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % The execution context
    case 'exe'
        
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % Check the input arguments
        dImg = double(dImg);
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        hDrawFcn(iMask);

        xArgOut = lMask;
    % end of the execution path
    % ---------------------------------------------------------------------
    
    otherwise, xArgOut = [];
        
end
% of the switch statement
% -------------------------------------------------------------------------





end