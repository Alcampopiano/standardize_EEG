function prepcommands

EEG=pop_prepPipeline(EEG, struct('ignoreBoundaryEvents', true, 'cleanupReference', true, 'keepFiltered', true, 'removeInterpolatedChannels', true,'reportMode', 'skipReport','publishOn', true,'sessionFilePath', './testCNTReport.pdf','summaryFilePath', './testCNTSummary.html','consoleFID', 1));


end
