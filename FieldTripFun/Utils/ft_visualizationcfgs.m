function [cfg_view, cfg_time, cfg_fft, cfg_topo, cfg_sum, cfg_stack, cfg_chntrfft] = ft_visualizationcfgs()
% FT_VISUALIZATION This function will call in several data visualization
%   configuration structures. This is to minimize the code lines needed to
%   parameterize the different plots we want to use to visualize the EEG
%   preprocessing process.

    cfg_view     = feval('cfg_view');
    cfg_time     = feval('cfg_time');
    cfg_fft      = feval('cfg_fft');
    cfg_topo     = feval('cfg_topo');
    cfg_sum      = feval('cfg_sum');
    cfg_stack    = feval('cfg_stack');
    cfg_chntrfft = feval('cfg_chntrfft');
end