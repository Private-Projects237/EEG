function cfg = cfg_chntrfft()
% CFG_CHNTRFFT Default parameters to use the `ft_plotchantrialfft()` function.

    cfg = [];
    cfg.plotchantrial.method       = 'mtmfft';
    cfg.plotchantrial.taper        = 'hanning';
    cfg.plotchantrial.output       = 'pow';
    cfg.plotchantrial.deltafoilim  = [1 4];
    cfg.plotchantrial.thetafoilim  = [4 8];
    cfg.plotchantrial.alphafoilim  = [8 12];
    cfg.plotchantrial.betafoilim   = [13 30];

end