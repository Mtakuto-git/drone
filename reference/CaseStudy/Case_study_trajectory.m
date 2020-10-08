function [ref] = Case_study_trajectory(X0)
%UNTITLED ���̊֐��̊T�v�������ɋL�q
%   �ڍא����������ɋL�q

syms t real
x_0 = X0(1);
y_0 = X0(2);
z_0 = X0(3);

s = 4; % s = 2 �� period = 4*pi (12 sec)�n�[�g1��
y_offset = 5;
r = 0.1;

x = x_0+r*16*sin(t/s)^3;
y = y_0+r*(13*cos(t/s)-5*cos(2*t/s)-2*cos(3*t/s)-cos(4*t/s)-y_offset);
z = z_0;

ref=@(t)[x;y;z;0];
end
