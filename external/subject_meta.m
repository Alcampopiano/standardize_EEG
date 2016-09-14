function description=subject_meta(filename,description,stdinx)

for fi=1:length(filename);
    
    a=1;
    b=1;
    infosum=0;
    fid=fopen(filename{fi});
    while 1
        tline = fgetl(fid);
        if ~ischar(tline), break, end
        if ~isempty(tline);
            proptext{a}=tline;
            if ~any(strfind(tline,'%%HEADER'))
                infosum=infosum+1;
            elseif any(strfind(tline,'%%HEADER')) && a~=1;
                info_store(b)=infosum;
                infosum=0;
                b=b+1;
            end
            a=a+1;
        end
    end
    fclose(fid); 
    
 prop_strs = sprintf('%s\n\n' ,proptext{:});
 prop_strs=strrep(prop_strs,'%%HEADER','***');
 description.(stdinx).(filename{fi}(1:end-5))=prop_strs;

end