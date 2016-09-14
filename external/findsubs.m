
% get file list
d=dir('data_files');

% truncate to names only
df={d.name};

% find names matching study
dfm=strncmp(study_name,df,length(study_name));

% return only matching names
df_list=df(dfm);

% find meta files
df_meta=strfind(df_list,'.meta');

% find files that are not meta data
no_meta=cellfun('isempty', df_meta);

% get list of data files
df_data=df_list(no_meta);