function param = getParameter_withload(varargin)
% class化したほうが良い．
mass = 0.2355;
length = 0.075;% モーター間の距離：正方形を仮定している
jx = 0.002237568;
jy = 0.002985236;
jz = 0.00480374;
gravity = 9.81;
km1 = 0.03010685884691849; % ロータ定数
km2 = 0.03010685884691849; % ロータ定数
km3 = 0.03010685884691849; % ロータ定数
km4 = 0.03010685884691849; % ロータ定数
k1 = 0.000008048;          % 推力定数
k2 = 0.000008048;          % 推力定数
k3 = 0.000008048;          % 推力定数
k4 = 0.000008048;          % 推力定数
loadmass = 0.1;            % 牽引物体の重さ
L = 0.5;                   % 紐の長さ
% T = k*w^2  
% T : thrust , w : angular velocity of rotor
% M = km * T = km* k * w^2
% M : zb moment  ：そのため普通の意味でのロータ定数とは違う
param= [mass, length, jx, jy, jz, gravity, km1, km2, km3, km4, k1, k2, k3, k4 ,loadmass, L];
if size(varargin) >= 1
    if strcmp(varargin{1},'Plant')% for Plant parameter
        param= [mass, length, jx, jy, jz, gravity, km1, km2, km3, km4, k1, k2, k3, k4, loadmass, L];
    end
end
% if size(varargin) >= 1
%     if contains(varargin,'m')
%         mass = varargin.m;
%         length = varargin.l;
%         jx = varargin.jx;
%         jy = varargin.jy;
%         jz = varargin.jz;
%         km1 = varargin.km1;
%         km2 = varargin.km2;
%         km3 = varargin.km3;
%         km4 = varargin.km4;
%         k1 = varargin.k1;
%         k2 = varargin.k2;
%         k3 = varargin.k3;
%         k4 = varargin.k4;
%         param= [mass, length, jx, jy, jz, gravity, km1, km2, km3, km4, k1, k2, k3, k4];
%     else
%         param = varargin;
%     end
% end
end

