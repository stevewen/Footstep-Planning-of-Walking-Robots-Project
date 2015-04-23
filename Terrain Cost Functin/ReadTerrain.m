function [ ret ] = ReadTerrain(filename, Show)

% generate terrain from terrain height mape all; clear all
A = imread(filename); 
% A = imread('EasyTest.png','png'); 
B = im2double(A); % change data type

[c1, c2, c3] = size(B);
% first scale the terrain height to desired height
BMax = max(max(max(B)));
BMin = min(min(min(B)));
BScale = (BMax - BMin);
B = B / 20 / BScale;  % usually be 0-0.05

% generate input matrixes as training data
% % Training data num = 20
% idx = floor(rand(20, 1).*(c1-11)) + 1; % random position in the height map
% idy = floor(rand(20, 1).*(c2-11)) + 1;

% reshape the terrain height map into a 100 by 100 matrix

idx_row = linspace(1,floor(c1/100)*100+1, 101);
idx_col = linspace(1,floor(c2/100)*100+1, 101);
B = B(idx_row, idx_col);
x = linspace(0,10,101);
y = linspace(0,10,101);

% x = linspace(0,10,c2);
% y = linspace(0,10,c1);
[X, Y] = meshgrid(x, y);

% global WholeTerrain
% Result = zeros(91, 91);
% for i = 1:91
%     Result(i, :) = WholeTerrain.y(91*(i-1)+1:91*i, 1);
% end

if Show == 1
for i=1:1 % i = 1:3
    
    figure
    mesh(X, Y, B(:,:,i))
    axis([0 10 0 10 0 .5])
    hold on
    
end
end
ret = B(:, :, 1);

end