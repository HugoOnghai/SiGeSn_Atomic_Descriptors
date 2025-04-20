% Generate list of atoms for a run e.g. sys4
at = ones(1,4);
z_Ge = 32;
z_Sn = 50;
% Need to extract atomic radii from psp files, using wiki values as placeholder
r_Ge = 2.36; % [Bohr] just like everything else should be :]
r_Sn = 2.74; % [Bohr]
descrip_list = [];
rho_pts = [];

% File reading from M-SPARC

% Read .inpt for latvec scale
fid1 = fopen("sys4.inpt");
if (fid1 == -1) 
    error('Cannot open .inpt file');
end

while(~feof(fid1))
	C_inpt = textscan(fid1,'%s',1,'delimiter',' ','MultipleDelimsAsOne',1);
	str = char(C_inpt{:}); % for R2016b and later, can use string()
	% skip commented lines starting by '#'
	%if (isempty(str) || str(1) == '#' || strcmp(str,'undefined'))
	if (isempty(str) || str(1) == '#')
		textscan(fid1,'%s',1,'delimiter','\n','MultipleDelimsAsOne',0); % skip current line
		%fprintf('skipping current line!\n');
		continue;
	end

    if (strcmp(str,'LATVEC_SCALE:'))
	    C_param = textscan(fid1,'%f %f %f',1,'delimiter',' ','MultipleDelimsAsOne',1);
	    latvec_scale_x = C_param{1}; % [Bohr]
	    latvec_scale_y = C_param{2}; % [Bohr]
	    latvec_scale_z = C_param{3}; % [Bohr]
	    textscan(fid1,'%s',1,'delimiter','\n','MultipleDelimsAsOne',0); % skip current line 
    end
end

% Read .ion file for coordinates of atoms
fid2 = fopen("sys4.ion");
if (fid2 == -1) 
    error('\n Cannot open .ion file');
end

%% Need to Generalize with Parser 
% (was getting stuck so reverted to manually getting atomic coordinates)
%{
% identify total number of atom types
typcnt = 0;
while (~feof(fid2)) 
	%fscanf(fid1,"%s",str);
	C_inpt = textscan(fid2,'%s',1,'delimiter',' ','MultipleDelimsAsOne',1);
	str = char(C_inpt{:});
	if (strcmp(str, 'ATOM_TYPE:')) 
		typcnt = typcnt + 1;
	end
	% skip current line
	textscan(fid2,'%s',1,'delimiter','\n','MultipleDelimsAsOne',0);  
end
%}
%%
str = textscan(fid2,'%s','Delimiter','\n');
fclose(fid2);
Ge_coord_cell = split(str{1}(5:36),' ');
Ge_coord = str2double(string(Ge_coord_cell));
[Ge_num,~] = size(Ge_coord);

for i=1:Ge_num
    at(i,:) = [z_Ge, Ge_coord(i,:)];
end

Sn_coord_cell = split(str{1}(42:73),' ');
Sn_coord = str2double(string(Sn_coord_cell));
[Sn_num,~] = size(Sn_coord);

for i=1:Sn_num
    at(i+Ge_num,:) = [z_Sn, Sn_coord(i,:)];
end

% Construct rho diff
DFT = load('sim sys4 run1.mat');
density1 = DFT.density;
SAD = load('sys4 SAD run1.mat');
density2 = SAD.density;
rho_diff = density1 - density2;

% Sort list in order of atomic coord
[num_at,~] = size(at);

for i=1:num_at
    for j=1:num_at-1
        if at(j,2) > at(j+1,2)
            t = at(j+1,:);
            at(j+1,:) = at(j,:);
            at(j,:) = t;
        end
    end
end

for i=1:num_at
    for j=1:num_at-1
        if (at(j,2) == at(j+1,2)) && (at(j,3) > at(j+1,3))
                 t = at(j+1,:);
                 at(j+1,:) = at(j,:);
                 at(j,:) = t;
        end
    end
end

for i=1:num_at
    for j=1:num_at-1
        if (at(j,2) == at(j+1,2)) && (at(j,3) == at(j+1,3)) && (at(j,4) > at(j+1,4))
             t = at(j+1,:);
             at(j+1,:) = at(j,:);
             at(j,:) = t;
        end
    end
end

% Map DFT rho points to physical space with latvec
[xdim, ydim, zdim] = size(rho_diff);
% rho_coord = ones(xdim,ydim,zdim);
x_spacing = latvec_scale_x / xdim;
y_spacing = latvec_scale_y / ydim;
z_spacing = latvec_scale_z / zdim;

% Generate atomic coordinates
x = x_spacing:x_spacing:latvec_scale_x;
y = y_spacing:y_spacing:latvec_scale_y;
z = z_spacing:z_spacing:latvec_scale_z;
% Old approach with mesh [X_coord, Y_coord, Z_coord]=meshgrid(x,y,z);

% Extract electron density info for chosen set of interior points
r_cut = 4; % [Bohr]
int_pts = [latvec_scale_x - 20*x_spacing, latvec_scale_y - 20*y_spacing, latvec_scale_z - 20*z_spacing;
           latvec_scale_x - 15*x_spacing, latvec_scale_y - 15*y_spacing, latvec_scale_z - 15*z_spacing;
           latvec_scale_x - 20*x_spacing, latvec_scale_y - 15*y_spacing, latvec_scale_z - 20*z_spacing;
           latvec_scale_x - 15*x_spacing, latvec_scale_y - 20*y_spacing, latvec_scale_z - 20*z_spacing;
           latvec_scale_x - 20*x_spacing, latvec_scale_y - 20*y_spacing, latvec_scale_z - 15*z_spacing;
           latvec_scale_x - 15*x_spacing, latvec_scale_y - 15*y_spacing, latvec_scale_z - 20*z_spacing;
           latvec_scale_x - 20*x_spacing, latvec_scale_y - 15*y_spacing, latvec_scale_z - 15*z_spacing;
           latvec_scale_x - 15*x_spacing, latvec_scale_y - 20*y_spacing, latvec_scale_z - 15*z_spacing;
           ];
[num_pts,~] = size(int_pts);

% index for num pts
% begin with one pt
int_pt = int_pts(1,:);
int_index = int_pt/x_spacing;
rho_diff_pt = rho_diff(int_index);

% Map atomic spheres to real space
z_map = zeros(xdim,ydim,zdim);

for i=1:num_at
    if at(i,1) == z_Ge
        r_sph = r_Ge;
        z_sph = z_Ge;        
    elseif at(i,1) == z_Sn
        r_sph = r_Sn;
        z_sph = z_Sn;
    end
    center = at(i,2:4);
    for ii=1:xdim
        for jj=1:ydim
            for kk=1:zdim
                loc = [x(ii),y(jj),z(kk)];
                if norm(loc-center) <= r_sph
                    z_map(ii,jj,kk) = z_sph;
                end
            end
        end
    end
end

% Check density points
% If point within a sphere specified by atomic cutoff radius, 
% add atomic info and coord

for i=1:xdim
    for j=1:ydim
        for k=1:zdim
            rho_pt = rho_diff(i,j,k);
            loc = [x(i),y(j),z(k)];
            I = sub2ind([xdim ydim zdim],i,j,k);
            z_val = z_map(I);
            if (norm(loc-int_pt) <= r_cut && z_val~=0)
                % Not great to be appending values like this
                descrip_list = [descrip_list; norm(loc-int_pt), z_val];
                rho_pts = [rho_pts; rho_pt];
            end
        end
    end
end

%{

% Redo with logical array?

for i=1:xdim
    for j=1:ydim
        for k=1:zdim
            rho_pt = rho_diff(i,j,k);
            loc = [x(i),y(j),z(k)];
            I = sub2ind([xdim ydim zdim],i,j,k);
            z_val = z_map(I);
            if  norm(loc-int_pt) <= r_cut
                descrip_list = [descrip_list; loc, z_val];
                rho_pts = [rho_pts; rho_pt];
            end
        end
    end
end

%}

% Generate Table
T = array2table([rho_pts,descrip_list],'VariableNames',{'rho_diff','r_diff','z'});
