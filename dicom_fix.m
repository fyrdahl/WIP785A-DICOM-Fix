prev_series = []; pos = []; fileID = []; headers = [];
series_number = ''; imagetype = ''; seqname = '';

path = uigetdir(pwd,'Select folder containing DICOM-images');
files = dir(path);
metadata = cell(numel(files));


fprintf('\n\nWIP785A DICOM Fix\n------------------\n');
fprintf('Searching for DICOM-files in %s\n',path);
fprintf('Found %i files!\n',numel(files)-2);
fprintf('Scanning...');
for ID = 2:numel(files)
    
    [~,filename,ext] = fileparts(files(ID).name);
    
    if any(strcmp(ext,{'.IMA','.dcm'}))
        
        metadata{ID} = dicominfo(fullfile(files(ID).folder,files(ID).name));

        try
            % Try and grab some tags
            seqname = metadata{ID}.SequenceName;
            imagetype = metadata{ID}.ImageType;
            series_number = metadata{ID}.SeriesNumber;
        catch
            % If this failed we can skip to the next file since non of the
            % below checks will make any sense
            continue;
        end
        
        % Depending on how the data is exported, there could be multiple
        % series to process in the same folder. Let's make sure we call
        % do_reprocess before we start reading a new series.
        if  ~isempty(prev_series) && (series_number~=prev_series)
            disp('\nFound multiple series!');
            do_reprocess(pos,fileID,files,metadata,path,series_number)
            pos = []; fileID = []; headers = [];
        end
        
        % Sanity check to see if this is appropriate data
        % Should at least be magnitude and 3D.
        
        %if contains(imagetype, '\M\') && contains(seqname, 'fl3d') % Not backwards compatible
        if strfind(imagetype, '\M\') && strfind(seqname, 'fl3d')
            tmp_pos = metadata{ID}.ImagePositionPatient;
            pos = cat(3,pos,tmp_pos);
            fileID = cat(3,fileID,ID);
            prev_series = series_number;
        end
    end
end
fprintf('Scanning done!\n');

do_reprocess(pos,fileID,files,metadata,path,series_number)

function do_reprocess(pos,fileID,files,metadata,path,series_number)
    
    % This is all a bit of a hack – but the error only seems to occur on 
    % the last few frames, so I propose we assume the first set of frames 
    % are correct and just copy their positions to downstream.
    
    fprintf('Patching series %i...',series_number); tic;
    patch_path = fullfile(path,'PATCHED/');
    if ~exist(patch_path,'dir') mkdir(patch_path); end

    first_in_slab = [1 find(diff(abs(pos(1,:)))<0)+1]; % The absolute value is needed for generality, i.e. positive/negative positions
    slices_per_slab = first_in_slab(2)-1;
    
    ii = 0; buff = {};
    for ID = fileID
        ii = ii + 1;
        IM = dicomread(fullfile(path,files(ID).name));
        if ii < first_in_slab(2)
            % Fill a buffer with locations from the first "slab".
            buff{ii} = metadata{ID}.ImagePositionPatient;
        else
            % Overwrite whatever position is in the header with the
            % hopefully correct positions from the first "slab".
            metadata{ID}.ImagePositionPatient = buff{mod(ii-first_in_slab(2),first_in_slab(2)-1)+1};
        end
        dicomwrite(IM, fullfile(patch_path,files(ID).name), metadata{ID}, 'CreateMode', 'copy');
    end
    fprintf('Done!\n');
    fprintf('Patched %i files in %.0f seconds!\n',ii,toc);
end