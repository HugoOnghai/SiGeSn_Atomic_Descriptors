% Define base directories
dft_dir = './DataExtraction_Featurization/DFT Calculations';
sad_dir = './DataExtraction_Featurization/SAD Calculations';

dft_folders = dir(fullfile(dft_dir, 'sys_*'));

num_systems = length(dft_folders);

for k = 1:num_systems
    % Extract the number from the folder name
    system_name = dft_folders(k).name;
    idx = sscanf(system_name, 'sys_%d'); % extract the numeric index of the system (k should equal idx ideally)

    % construct the paths to the corresponding systems (DFT and SAD)
    dft_path = fullfile(dft_dir, sprintf('sys_%d', idx));
    sad_path = fullfile(sad_dir, sprintf('sys_SAD_%d', idx));

    % grab electron density matrix at the k_points, as calculated by both
    % methods
    rho_DFT = load(fullfile(dft_path, 'sim.mat')).density;
    rho_SAD = load(fullfile(sad_path, 'sim.mat')).density;

    rho_DIFF = rho_DFT - rho_SAD;

    % find the latvec_scaling of the systems so we can convert to real
    % space, let's assume both are the same and just find it from the DFT
    % system.
    
    filename = fullfile(dft_path, 'sim.inpt');
    fid = fopen(filename, 'r');

    latvec_scale = [];

    while ~feof(fid)
        line = fgetl(fid);
        if startsWith(strtrim(line), 'LATVEC_SCALE:')
            % Extract numbers using sscanf
            latvec_scale = sscanf(line, 'LATVEC_SCALE: %f %f %f');
            break;  % Exit loop once found
        end
    end
    
    fclose(fid);
    
    % Optional: assign to named variables
    latvec_scale_x = latvec_scale(1);
    latvec_scale_y = latvec_scale(2);
    latvec_scale_z = latvec_scale(3);

    % map rho_diff to cartesian coordinates based on the indexing of the
    % point in the matrix THIS MIGHT BE WRONG
    % Map rho_diff points to physical space with latvec
    [xdim, ydim, zdim] = size(rho_DIFF);
    % rho_coord = ones(xdim,ydim,zdim);
    x_spacing = latvec_scale_x / xdim;
    y_spacing = latvec_scale_y / ydim;
    z_spacing = latvec_scale_z / zdim;

    % reformate rho_diff into the form explained in Generate K Points
    % rho_diff value ... x-coord ... y-coord ... z-coord
    reshaped_rho_diff = rho_DIFF(:);
    [row, col, depth] = ind2sub([xdim, ydim, zdim], 1:numel(rho_DIFF));
    
    i = x_spacing*(row-1);
    j = y_spacing*(col-1);
    k = z_spacing*(depth-1);
    
    reformated_rho_diff = [reshaped_rho_diff, i', j', k'];
    k_point_coords = array2table(reformated_rho_diff, 'VariableNames', {'rho_diff', 'x', 'y', 'z'});
    
    % for now, lets just turn this into a .csv to see the coordinates
    output_filepath = fullfile('./DataExtraction_Featurization/Rho_Diff', [system_name, '_kpointcoords.csv']);  % concatenate strings
    % Write the table to CSV
    writetable(k_point_coords, output_filepath);
end