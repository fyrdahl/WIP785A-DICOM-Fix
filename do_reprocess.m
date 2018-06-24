function do_reprocess(pos,fileID,files,metadata,path,series_number)

% This is all a bit of a hack but the error only seems to occur on
% the last few frames, so I propose we assume the first set of frames
% are correct and just copy their positions downstream.

fprintf('Patching series %i...',series_number); tic;
patch_path = fullfile(path,'PATCHED/');
if ~exist(patch_path,'dir') mkdir(patch_path); end

% The absolute value is needed for generality, i.e. positive/negative positions
first_in_slab1 = [1 find(diff(abs(pos(1,:)))<0)+1];
first_in_slab2 = [1 find(diff(abs(pos(2,:)))<0)+1];
first_in_slab3 = [1 find(diff(abs(pos(3,:)))<0)+1];

if(numel(first_in_slab1)>1)
    first_in_slab = first_in_slab1;
    slices_per_slab = first_in_slab(2);
elseif(numel(first_in_slab2)>1)
    first_in_slab = first_in_slab2;
    slices_per_slab = first_in_slab(2);
elseif(numel(first_in_slab3)>1)
    first_in_slab = first_in_slab3;
    slices_per_slab = first_in_slab(2);
end

ii = 0; buff = {};
if exist('slices_per_slab','var')
    
    % This is all a bit of a hack – but the error only seems to occur on 
    % the last few frames, so I propose we assume the first set of frames 
    % are correct and just copy their positions to downstream.
    
    fprintf('Patching series %i...',series_number); tic;
    patch_path = fullfile(path,'PATCHED/');
    if ~exist(patch_path,'dir') mkdir(patch_path); end

    first_in_slab1 = [1 find(diff(abs(pos(1,:)))<0)+1]; % The absolute value is needed for generality, i.e. positive/negative positions
    first_in_slab2 = [1 find(diff(abs(pos(2,:)))<0)+1]; % The absolute value is needed for generality, i.e. positive/negative positions
    first_in_slab3 = [1 find(diff(abs(pos(3,:)))<0)+1]; % The absolute value is needed for generality, i.e. positive/negative positions

    if(numel(first_in_slab1)>1)
        first_in_slab = first_in_slab1; 
        slices_per_slab = first_in_slab(2)-1;
    elseif(numel(first_in_slab2)>1)
        first_in_slab = first_in_slab1; 
        slices_per_slab = first_in_slab(2)-1;
    elseif(numel(first_in_slab2)>1)
        first_in_slab = first_in_slab1; 
        slices_per_slab = first_in_slab(2)-1;
    end
    
    ii = 0; buff = {};
    for ID = fileID
        ii = ii + 1;
        IM = dicomread(fullfile(path,files(ID).name));
        if ii < slices_per_slab
            % Fill a buffer with locations from the first "slab".
            buff{ii} = metadata{ID}.ImagePositionPatient;
        else
            % Overwrite whatever position is in the header with the
            % hopefully correct positions from the first "slab".
            metadata{ID}.ImagePositionPatient = buff{mod(ii-slices_per_slab,...
                slices_per_slab-1)+1};
        end

        try
            strStudyDescriptionOld = metadata{ID}.StudyDescription;
        catch err
            strStudyDescriptionOld = '';
        end
        metadata{ID}.StudyDescription = ['Flow4D_', strStudyDescriptionOld];

        dicomwrite(IM, fullfile(patch_path,files(ID).name), metadata{ID},...
            'CreateMode', 'copy', 'WritePrivate', 'true');
    end
end
fprintf('Done!\n');
fprintf('Patched %i files in %.0f seconds!\n',ii,toc);
end
