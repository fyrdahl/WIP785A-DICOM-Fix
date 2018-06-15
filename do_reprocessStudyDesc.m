function do_reprocessStudyDesc(pos,fileID,files,metadata,path,series_number)

fprintf('Patching series study Desription name %i...',series_number); tic;
patch_path = fullfile(path,'PATCHED/');
if ~exist(patch_path,'dir') mkdir(patch_path); end

ii = 0; buff = {};
for ID = fileID
    ii = ii + 1;
    IM = dicomread(fullfile(path,files(ID).name));

    try
        strStudyDescriptionOld = metadata{ID}.StudyDescription;
    catch err
        strStudyDescriptionOld = '';
    end
    metadata{ID}.StudyDescription = ['Flow4D_', strStudyDescriptionOld];

    dicomwrite(IM, fullfile(patch_path,files(ID).name), metadata{ID}, 'CreateMode', 'copy', 'WritePrivate', 'true');
end

fprintf('Done!\n');
fprintf('Patched %i files in %.0f seconds!\n',ii,toc);

end
