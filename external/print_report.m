function print_report(instruct,varargin)

if nargin==1;
    fid = fopen('report.txt', 'wt+');
elseif nargin>1;
    fid=varargin{2};
    parent=varargin{1};
end

nl=0;
fn=fieldnames(instruct);

for i = 1:length(fn)
    
    if iscell(instruct.(fn{i}))
        
        fprintf(fid, '%d\t',instruct.(fn{i}));
        
    elseif isnumeric(instruct.(fn{i}))
        
        if isempty(instruct.(fn{i}))
            
            fprintf(fid, '%s\t',fn{i});
        else
            %fprintf(fid, '%s\t',fn{i});
            fprintf(fid, '%s\t',num2str(instruct.(fn{i})));
        end
        
        % special case
        if  ~strncmp('event_labels',parent,10);
            nl=1;
        end
        
    elseif ischar(instruct.(fn{i}))
        
        if ~isempty(instruct.(fn{i}))
            fprintf(fid, '%s\t',fn{i});
            fprintf(fid, '%s\t',instruct.(fn{i}));
        end
        
        % special case
        if  ~strncmp('event_labels',parent,12);
            nl=1;
        end
        
        
    elseif isstruct(instruct.(fn{i}))
        
        fprintf(fid, '%s\n',fn{i});
        print_report(instruct.(fn{i}),fn{i},fid);
        
    elseif islogical(instruct.(fn{i}))
        fprintf(fid, '%s\t',fn{i});
        fprintf(fid, '%s\t',num2str(instruct.(fn{i})));
        nl=1;
    end
    
    if nl==1 || i==length(fn)
        fprintf(fid, '%s\n','');
        nl=0;
    end
end

if nargin==1;
    fclose(fid);
end
end

