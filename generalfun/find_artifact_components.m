% INPUT
% ic_scores = Generated from iclabel(EEG)
% num_components = Number of components we care to investige (ex: top 20)
% preprocParams = The specified parameters with needed IC thresholds
% result = The result struct that keeps track of identified artifacts

% OUTPUT (result Structure):
% Basically modifies the result structure to include information about the
% IC artifact identification process. 

% Description: This code will take in a matrix generated from the iclabel()
% function which informs us how likely one of the independent components
% corresponds to brain activity or a specific type of noise. It will then
% identify the number of components (from the number specified) that
% correspond to brain, muscle, eye, heart, line, channel, and other
% components. It will also report the order of components and the
% components that need to be removed. 


function [result, components_to_reject] = find_artifact_components(ic_scores, num_components, preprocParams, result)
    % Validate required threshold fields
    required_fields = {'brain', 'muscle', 'eye', 'heart', 'line', 'chan', 'other'};
    if ~isfield(preprocParams, 'ICL') || ~isfield(preprocParams.ICL, 'thresh') || ...
       ~all(isfield(preprocParams.ICL.thresh, required_fields))
        error('Missing required threshold fields in preprocParams.ICL.thresh');
    end

    % Define component types and their indices
    component_types = struct(...
        'name', {'Brain', 'Muscle', 'Eye', 'Heart', 'Line', 'Channel', 'Other'}, ...
        'index', {1, 2, 3, 4, 5, 6, 7}, ...
        'field', {'brain', 'muscle', 'eye', 'heart', 'line', 'chan', 'other'});

    % Process each component type and update existing result struct
    for i = 1:length(component_types)
        comp_name = component_types(i).name;
        comp_idx = component_types(i).index;
        thresh_field = component_types(i).field;
        
        % Calculate total components exceeding threshold
        comp_order = find(ic_scores(1:num_components, comp_idx) > preprocParams.ICL.thresh.(thresh_field));
        result.(['Total', comp_name, 'Components']) = sum(ic_scores(1:num_components, comp_idx) > preprocParams.ICL.thresh.(thresh_field));
        
        % Save component indices
        if length(comp_order) > 1
            result.([comp_name, 'ComponentsIdx']) = strjoin(arrayfun(@num2str, comp_order, 'UniformOutput', false), ', ');
        elseif length(comp_order) == 1
            result.([comp_name, 'ComponentsIdx']) = [num2str(comp_order), ', '];
        end
    end
    
    % Identify components to reject (all non-brain components exceeding thresholds)
    components_to_reject = find(ic_scores(1:num_components, 2) > preprocParams.ICL.thresh.muscle | ...
                                      ic_scores(1:num_components, 3) > preprocParams.ICL.thresh.eye | ...
                                      ic_scores(1:num_components, 4) > preprocParams.ICL.thresh.heart | ...
                                      ic_scores(1:num_components, 5) > preprocParams.ICL.thresh.line | ...
                                      ic_scores(1:num_components, 6) > preprocParams.ICL.thresh.chan | ...
                                      ic_scores(1:num_components, 7) > preprocParams.ICL.thresh.other);
end