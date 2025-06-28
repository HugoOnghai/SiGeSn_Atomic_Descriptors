function ExtractElements(input_filename)
    
    % Derive output filename with .csv extension
    [filepath, name, ~] = fileparts(input_filename);
    output_filename = fullfile(filepath, [name, '.csv']);
    
    % Open and check the input file
    fid = fopen(input_filename, 'r');
    if fid == -1
        error('Failed to open the file: %s', input_filename);
    end
    
    atom_types = {};
    coords = [];
    
    line = fgetl(fid);
    while ischar(line)
        if contains(line, 'ATOM_TYPE:')
            atom_type = strtrim(extractAfter(line, 'ATOM_TYPE:'));
            fgetl(fid); % skip PSEUDO_POT
            line = fgetl(fid); % read N_TYPE_ATOM
            n_atoms = str2double(strtrim(extractAfter(line, 'N_TYPE_ATOM:')));
            fgetl(fid); % skip COORD:
    
            % Read the coordinate lines
            for i = 1:n_atoms
                coord_line = fgetl(fid);
                xyz = str2double(strsplit(strtrim(coord_line)));
                coords = [coords; xyz]; %#ok<AGROW>
                atom_types{end+1} = atom_type; %#ok<AGROW>
            end
        end
        line = fgetl(fid);
    end
    fclose(fid);
    
    % Write to the CSV file
    fid_out = fopen(output_filename, 'w');
    fprintf(fid_out, 'ATOM_TYPE,X_COORD,Y_COORD,Z_COORD\n');
    for i = 1:length(atom_types)
        fprintf(fid_out, '%s,%.10f,%.10f,%.10f\n', atom_types{i}, coords(i,1), coords(i,2), coords(i,3));
    end
    fclose(fid_out);
    
    fprintf('CSV file written to: %s\n', output_filename);
end