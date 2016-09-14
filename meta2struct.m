function [events_map]=meta2struct(clean)

filename=uigetfile('.meta','select metada data files', 'multiselect','on');
if ~iscell(filename)
    filename={filename};
end

% so we can have seprate description structures
study_str=cell(1,length(filename));
for i=1:length(filename)
    study_str{i}=['study_', num2str(i)];
end

% preallocate
emark=false(1,length(filename));
skipstd=false(1,length(filename));

%% read file lines ignoring blanks

% keep track of how many info lines there are per header
% helpful for struct assignment later
indx=1;
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
    info_store=[info_store infosum];
    
    % where the headers are
    isheader=cellfun(@(s) ~isempty(strfind(s,'%%HEADER')), proptext);
    
    % format headers and info for later struct assignment
    heads=proptext(isheader);
    for i=1:length(heads)
        heads{i}=strrep(strtrim(heads{i}(9:end)),' ','_');
    end
    info=strrep(strtrim(proptext(~isheader)),' ','_');
    
    % put humpty dumpty back together again
    orig_proptext=proptext;
    proptext(~isheader)=info;
    proptext(isheader)=heads;
    
    %% build main property structure
    
    % grab study name
    study_name=info{1}; % assumes standard position
    
    % grab event labels
    ind_head=strcmpi(heads,'event_labels'); % where to look
    len=info_store(ind_head); % how far to look
    ind_prop=find(strcmpi(proptext,'event_labels')); % where to look
    
    % add numbers that will later turn invisible
    % this is an indexing strategy
    evelabs=['event_labels_', num2str(indx)];
    %evelabs='event_labels';
    
    if ~len==0;
        for i=1:len;
            
            field=proptext{ind_prop+i};
            
            if ~isempty(str2num(field));
                field=['E',field];
                
                % take note
                emark(fi)=1;
            end
            studies.(study_name).(evelabs).(field)=[];
        end
        
        %% build description structure
        description.(study_name)=struct;
        description.(study_name)=link_description(description.(study_name), info_store, heads, proptext, orig_proptext, study_name, 'study_details');
        description.(study_name)=link_description(description.(study_name), info_store, heads, proptext, orig_proptext, evelabs, 'event_details');
        
        
        %% add headers to field
        [studies]=header2field(heads,info_store,proptext,'channel_locations',studies,study_name);
        [studies]=header2field(heads,info_store,proptext,'relative_gain',studies,study_name);
        [studies]=header2field(heads,info_store,proptext,'number_of_channels',studies,study_name);
        [studies]=header2field(heads,info_store,proptext,'sampling_rate',studies,study_name);
        [studies]=header2field(heads,info_store,proptext,'no_data_channel',studies,study_name);
        
        %% add check box
        studies.(study_name).include_study=true;
        
        %% add subject structure and subject check boxes
        
        d=dir('data_files');
        
        % truncate to names only
        df={d.name};
        
        % find names matching study
        dfm=strncmp(study_name,df,length(study_name));
        
        % return only matching names
        df_list=df(dfm);
        if ~iscell(df_list); df_list={df_list}; end
        
        % find meta files
        df_meta=strfind(df_list,'.meta');
        
        % find files that are not meta data
        no_meta=cellfun('isempty', df_meta);
        
        % get list of data files
        df_data=df_list(no_meta);
        
        % append to structure
        for sub=1:length(df_data)
            studies.(study_name).subjects.(df_data{sub}(1:end-4))=true;
        end
        
        % add subject descriptions
        description=subject_meta(df_list(~no_meta),description,(study_name));
        indx=indx+1;
        
    else
        skipstd(fi)=1;
        disp('no events for at least one study. Study ignored.');
    end
    
    clear proptext info_store
end % study loop

%% add fields to control later indexing during grid construction
%description.nstudies=length(fieldnames(description));
%description.nfields=length(fieldnames(description));
%description.startfield=1;
%description.startstudy=1;
%description.subisnext=0;

%% Build grid, passing descriptions globally

global DES %STUDIES

DES=description;
try
    [g events_map cancelhit]=propertiesGUI(studies);
    clear -global DES test_data
    
    % see if cancel was hit
    if cancelhit; clear -global DES test_data; return; end;
    
catch E_ID
    clear -global DES
    error(E_ID.message);
end

% hold study updated study names
updatedstudies=fieldnames(events_map);

% collect study names that have fields that were prefixed
% remove inds corresponding to skipped study
%Eprefix=filename(emark);
emark(skipstd)=[];
Eprefix=updatedstudies(emark);

% remove studies that were deselected

j=1;
inds_to_rem=[];
for i=1:length(updatedstudies)
    if events_map.(updatedstudies{i}).include_study==false;
        events_map=rmfield(events_map, updatedstudies{i});
        inds_to_rem(j)=i;
        j=j+1;
    end
end

if ~isempty(inds_to_rem);
    updatedstudies(inds_to_rem)=[];
end

% find a data file list
datfiles=dir('data_files');
dirflags = [datfiles.isdir];
datfiles(dirflags)=[];
metafiles=dir('data_files/*.meta');
mefi={metafiles.name};
dafi={datfiles.name};
ind=ismember(dafi,mefi);
dafi(ind)=[];

% removing subject identifiers
for i=1:length(dafi);
    %dafi_trim{i}=[dafi{i}(1:end-9), '.meta'];
    dafi_trim{i}=[dafi{i}(1:end-9)];
end

for st=1:length(updatedstudies);
    
    % find data files that match study name
    datinds=strmatch(updatedstudies{st}, dafi_trim);
    datafiles=dafi(datinds);
    
    
    
    %% pipe files to import
    for fi=1:length(datinds);
        
        % determine if subjects were included
        if events_map.(updatedstudies{st}).subjects.(datafiles{fi}(1:end-4)); % if subject is included
            
            % get one filename
            dat=datafiles{fi};
            
            % get extension
            ext=dat(end-2:end);
            
            % pipe to import function
            switch lower(ext)
                
                case 'bdf'
                    
                    EEG=pop_biosig(dat);
                    
                case 'cnt'
                    
                    EEG=pop_loadcnt(dat);
                    
                case 'rdf'
                    
                    % get sampling rate
                    samprate=str2double(events_map.(updatedstudies{st}).sampling_rate);
                    EEG = pop_read_erpss(dat, samprate);
                    
                case 'sma'
                    
                    % get relative gain
                    gain=str2double(events_map.(updatedstudies{st}).relative_gain);
                    EEG = pop_snapread(dat, gain);
                    
                case 'edf'
                    
                    EEG=pop_biosig(dat);
                    
                case 'raw'
                    
                    EEG=pop_readegi(dat);
                    
                case 'eeg'
                    
                    EEG = pop_loadeeg(dat);
            end
            
            %% recode events
            %cur_study=updatedstudies{st}(1:end-5);
            cur_study=updatedstudies{st};
            curfield=fieldnames(events_map.(cur_study));
            eve_field=strncmp('event_labels_', curfield,13);
            evelabs=curfield(eve_field); evelabs=evelabs{:};
            
            %evelabs=['event_labels_',num2str(st)];
            curlabs=fieldnames(events_map.(cur_study).(evelabs));
            curstd=updatedstudies(st);
            
            if any(strcmp(curstd,Eprefix));
                
                for i=1:length(curlabs);
                    rename_event=events_map.(cur_study).(evelabs).(curlabs{i});
                    oldevent=str2num(curlabs{i}(2:end));
                    
                    % strip event prefixes
                    if ~isempty(rename_event);
                        EEG=pop_selectevent(EEG,'event', [], 'type', oldevent, 'renametype', rename_event, 'deleteevents','off');
                        pop_saveset(EEG,'filename', [dat(1:end-4), '_std'], 'filepath', 'data_files/standardized_files');
                        
                    else
                        pop_saveset(EEG,'filename', [dat(1:end-4), '_std'], 'filepath', 'data_files/standardized_files')
                    end
                end
                
            else
                for i=1:length(curlabs);
                    rename_event=events_map.(cur_study).(evelabs).(curlabs{i});
                    oldevent=curlabs{i};
                    if ~isempty(rename_event);
                        EEG=pop_selectevent(EEG,'event', [], 'type', oldevent, 'renametype', rename_event, 'deleteevents','off');
                        pop_saveset(EEG,'filename', [dat(1:end-4), '_std.set'], 'filepath', 'data_files/standardized_files')
                        
                    else
                        pop_saveset(EEG,'filename', [dat(1:end-4), '_std.set'], 'filepath', 'data_files/standardized_files')
                    end
                end
                
            end
            
            %% basic init procedure
            if strcmp(clean, 'PREP');
                EEG=pop_loadset('filename',[dat(1:end-4), '_std.set'], 'filepath', 'data_files/standardized_files');
                
                % channels without data
                try
                    nodatchan=events_map.(updatedstudies{st}).no_data_channel;
                    EEG = pop_select( EEG,'nochannel',{nodatchan});
                    EEG = eeg_checkset( EEG );
                catch
                end
                
                % channel locations
                chanfile=events_map.(updatedstudies{st}).channel_locations;
                EEG=pop_chanedit(EEG, 'load',{['misc/', chanfile], 'filetype' 'autodetect'});
                EEG = eeg_checkset( EEG );
                disp(['***** ', EEG.chaninfo.filename, ' *****']);
                
                % EEG = warp_locs( EEG, 'analysis/support/misc/standard_1020.elc', ...
                %   'landmarks',{'Nz','LPA','RPA'}, ...
                %   'transform',[1 -21 -48.01 -0.075 0.005 -1.58 1065 1140 1105], ...
                %   'manual','off');
                
                
                %% artifact rejection
                
                % light-handed cleaning with prep pipline
                EEG=pop_prepPipeline(EEG, struct('ignoreBoundaryEvents', true, 'cleanupReference', true, 'keepFiltered', ...
                    true, 'removeInterpolatedChannels', true,'reportMode', 'skipReport','publishOn', true,'sessionFilePath', ...
                    './testCNTReport.pdf','summaryFilePath', './testCNTSummary.html','consoleFID', 1));
                
                pop_saveset(EEG,'filename', [dat(1:end-4), '_PREP.set'], 'filepath', 'data_files/PREP_files')
                
            end
            
        end
    end
end
print_report(events_map)
end

%% add description
function description=link_description(description, info_store, heads, proptext, orig_proptext, field_mirror, detail_str)

% grab event labels
ind_deets=strcmpi(heads,detail_str); % where to look
len=info_store(ind_deets); % how far to look
ind_prop=find(strcmpi(proptext,detail_str)); % where to look

des_str='';
for i=1:len;
    tmp=orig_proptext{ind_prop+i};
    des_str=[des_str, ' ', tmp ];
end
description.(field_mirror)=des_str;
end

%% additional header to field in study struct
function [studies]=header2field(heads,info_store,proptext,headstr,studies,study_name)

ind_head=strcmpi(heads,headstr); % where to look
len=info_store(ind_head); % how far to look
ind_prop=find(strcmpi(proptext,headstr)); % where to look
%chanlocs=[headstr,'_', num2str(indx)];

if ~len==0;
    for i=1:len;
        field=proptext{ind_prop+i};
        studies.(study_name).(headstr)=field;
    end
    
end


end

