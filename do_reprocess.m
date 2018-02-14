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