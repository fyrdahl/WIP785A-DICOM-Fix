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
        if ~isfield(files(ID), 'folder')
            for IDn = ID:numel(files)
                files(IDn).folder=[path,'\'];
            end
        end

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
            disp('\nFound multiple series!\n');
            do_reprocess(pos,fileID,files,metadata,path,series_number)
            pos = []; fileID = []; headers = [];
        end

        % Sanity check to see if this is appropriate data
        % Should at least be magnitude and 3D.

        %if contains(imagetype, '\M\') && contains(seqname, 'fl3d') % Not backwards compatible
        if isempty(strfind(imagetype, '\M\'))
           bImageTypeMAGN = 0;
        else
           bImageTypeMAGN = 1;
        end

        if isempty(strfind(imagetype, '\P\'))
           bImageTypePHASE = 0;
        else
           bImageTypePHASE = 1;
        end

        if isempty(strfind(seqname, 'fl3d'))
           bSeqName = 0;
        else
           bSeqName = 1;
        end

        if(bSeqName && (bImageTypeMAGN || bImageTypePHASE))
            tmp_pos = metadata{ID}.ImagePositionPatient;
            pos = cat(3,pos,tmp_pos);
            fileID = cat(3,fileID,ID);
            prev_series = series_number;
        end
    end
end
fprintf('Scanning done!\n');
if(bSeqName && bImageTypeMAGN)
do_reprocess(pos,fileID,files,metadata,path,series_number)
elseif(bSeqName && bImageTypePHASE)
do_reprocessStudyDesc(pos,fileID,files,metadata,path,series_number)
end
fprintf('Patch finished!\n');
