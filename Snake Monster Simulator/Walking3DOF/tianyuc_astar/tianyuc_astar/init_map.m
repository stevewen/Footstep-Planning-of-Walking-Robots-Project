function [ map, obs_mat, tar_mat, rob_mat ] = init_map( x_map, y_map, obs_num, tar_num, rob_num )
%   init_map: input size of the map, number of the obstacles targets, 
%   robots return the terrain map
%   DEFINITION: -1 = obs, 1 = tar, 0 = robot, space = 2;
    map = 2 .* ones(x_map, y_map);
    map(1,1) = 0; % robot
    rob_mat = [1, 1];
    map(x_map, y_map)= 1; % target
    tar_mat = [x_map, y_map];
    obs_mat = floor(10 .* rand(obs_num, 2)) + 1; % obstacle
    while process_obs(obs_mat, tar_mat, rob_mat) == 1
        obs_mat = floor(10 .* rand(obs_num, 2)) + 1; % obstacle
    end
    for i = 1:obs_num
        map(obs_mat(i,1), obs_mat(i, 2)) = -1;
    end
end
