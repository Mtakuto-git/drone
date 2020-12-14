% -------------------------------------------------------------------------
% File : genFminconGradSample.m
% Discription : Ganerating the evalation function and constraint automatically
% Environment : MATLAB 2019b
% Author : Koji Shibata
% -------------------------------------------------------------------------
%% Global settings
% Initialize previous results and figures
tmp = matlab.desktop.editor.getActive;
dir = cd(fileparts(tmp.Filename));
[TT,tmp]=regexp(genpath('.'),'\.\\\old.*?;','match','split');
cellfun(@(xx) addpath(xx),tmp,'UniformOutput',false);
close all hidden; clear all; clc;
userpath('clear'); 
warning('off','all')
%% Parameters
Horizon = 10;
obj.stateNum = 8;
obj.inputNum = 2;
obj.slackNum = 2;
obj.totalNum = obj.stateNum + obj.inputNum ;
obj.H = Horizon + 1;
%% Symbolic variables
param.X0   = sym('X0',  [obj.stateNum, 1], 'real');
param.A    = sym('A',   [obj.stateNum, obj.stateNum], 'real');
param.B    = sym('B',   [obj.stateNum, obj.inputNum], 'real');
param.R    = sym('R',   [obj.inputNum, obj.inputNum], 'real');
param.Q    = sym('Q',   [obj.stateNum, obj.stateNum], 'real');
param.Qf   = sym('Qf',  [obj.stateNum, obj.stateNum], 'real');
param.Qd_f = sym('Qdf', 'real');
param.Qd_b = sym('Qdb', 'real');
param.Qt   = sym('Qt','real');
param.Qtf   = sym('Qtf','real');
param.Qdf_f = sym('Qdff', 'real');
param.Qdf_b = sym('Qdfb', 'real');
param.W_s   = sym('Ws','real');
param.W_r   = sym('Wr','real');
param.W_wx   = sym('Wwx','real');
param.W_wy   = sym('Wwy','real');
param.front  = sym('front',[2,obj.H],'real');
param.behind = sym('behind',[2,obj.H],'real');
param.D      = sym('D',[1,obj.H],'real');
param.D_lim  = sym('Dlim',[1,2],'real');
param.Slew   = sym('Sr','real');
param.r_limit = sym('rlim',[1,2],'real');
%�O�������K�v
param.Sectionconect = sym('Sc',[obj.H,2],'real');
param.wall_width_x = sym('wwx',[obj.H,2],'real');
param.wall_width_y = sym('wwy',[obj.H,2],'real');
param.LY   = sym('LY',   [obj.H, 1], 'real');
% param.Xr   = sym('Xr',  [obj.stateNum, obj.H], 'real');
% param.Ur   = sym('Ur',  [obj.inputNum, obj.H], 'real');
% param.umin = sym('umin',[obj.inputNum, 1], 'real');
% param.umax = sym('umax',[obj.inputNum, 1], 'real');
% param.S    = sym('S',   [obj.inputNum, 1], 'real');


%����
param.V = sym('V',[2,2],'real');
param.Qm = sym('Qm','real');
param.Qmf = sym('Qmf','real');
% param.sectionpoint = sym('sp',[3,2],'real');
% param.Section_change = sym('Schange',[1,4],'real');
% param.Qt = sym('Qt','real');
% param.Qtf = sym('Qtf','real');
% param.R = sym('R','real');
% param.W_s = sym('W_s','real');
% param.W_r = sym('W_r','real');
param.Cdis = sym('Cdis',[1,11],'real');
param.FLD = sym('FLD',[1,11],'real');
param.BLD = sym('BLD','real');
param.P_chips = sym('P_chips',[2,19],'real');
param.Line_Y = sym('Line_Y',[1,11],'real');

x   = sym('x',[obj.totalNum + obj.slackNum, obj.H], 'real');
vec = reshape(x, 1, (obj.totalNum+obj.slackNum) * obj.H);%1�s�̃x�N�g���`���ɕύX

%-- MPC�ŗp����\����� X�Ɨ\������ U��ݒ�
X = x(1 : obj.stateNum, :);
U = x(obj.stateNum + 1 : obj.totalNum, :);
S = x(obj.totalNum + 1:end,:);
%% Equality and inequality constraints
%-- ������Ԃ����ݎ����ƈ�v���邱�ƂƏ�ԕ������ɏ]�����Ƃ�ݒ�
% assumeAlso(X(1,:)~=param.front(1,:));
% assumeAlso(X(5,:)~=param.front(2,:));
% assumeAlso(X(1,:)~=param.behind(1,:));
% assumeAlso(X(5,:)~=param.behind(2,:));
ceqTEMP(1, :) = X(:, 1) - param.X0;
for L = 2:obj.H
    ceqTEMP(L, :) = X(:, L)  - (param.A * X(:, L-1) + param.B * U(:, L-1));
end
ceq = reshape(ceqTEMP, obj.stateNum * obj.H, 1);
%�X���b�N�ϐ��̔񕉐���
%     for N = 1:obj.slackNum
%         S_temp(N) = arrayfun(@(L) -S(N,L) , 2:obj.H);
%     end
% cineq(:, 1:obj.H) = zeros(1,obj.H);
    cineq(:, 1:obj.H) = arrayfun(@(L) -S(1,L) , 1:obj.H);%�X���b�N�ϐ��̐���
    cineq(:, obj.H+1 :2*obj.H) = arrayfun(@(L) -S(2,L) , 1:obj.H);
    cineq(:, 2*obj.H+1:3*obj.H) = zeros(1,obj.H);
    cineq(:, 3*obj.H+1:4*obj.H) = zeros(1,obj.H);
% %     cineq(:, 2*(obj.H-1)+1:3*(obj.H-1)) = arrayfun(@(L) -S(3,L) , 2:obj.H);
% %     cineq(:, 3*(obj.H-1)+1:4*(obj.H-1)) = arrayfun(@(L) -S(4,L) , 2:obj.H);
%����𖞂����Ă����0�ȉ��ɂȂ�悤�ɐ݌v
%     %�O�@�̂ɑ΂��鐧��@���[�N���b�h�����@D_lim����Ɖ���
    cineq(:,4*obj.H+1:5*obj.H) = [arrayfun(@(L) norm([X(1,L),X(5,L)] - [param.front(1,L),param.front(2,L)]) - param.D_lim(1)  , 2:obj.H),0];
    cineq(:,5*obj.H+1:6*obj.H) = [arrayfun(@(L) -norm([X(1,L),X(5,L)] - [param.front(1,L),param.front(2,L)]) + param.D_lim(2)  , 2:obj.H),0];
    %���@�̂ɑ΂��鐧��
    cineq(:, 6*obj.H+1:7*obj.H) = [arrayfun(@(L) norm([X(1,L),X(5,L)] - [param.behind(1,L),param.behind(2,L)]) - param.D_lim(1)  , 2:obj.H),0];
    cineq(:, 7*obj.H+1:8*obj.H) = [arrayfun(@(L) -norm([X(1,L),X(5,L)] - [param.behind(1,L),param.behind(2,L)]) + param.D_lim(2)  , 2:obj.H),0];
    %�X���[���[�g�@�@�̂̏�Ԃ̕ω��ʂ̐���
    cineq(:, 8*obj.H+1:9*obj.H) = [arrayfun(@(L) abs(X(1,L)- X(1,L-1))-param.Slew-S(1,L)  , 2:obj.H),0];
    cineq(:, 9*obj.H+1:10*obj.H) = [arrayfun(@(L) abs(X(5,L)- X(5,L-1))-param.Slew-S(1,L)  , 2:obj.H),0];
    %�P�[�u���ƕǁ@�@�̊Ԃ��Ȃ������Ƌ�ԓ_�Ƃ̋����𐧌�����D�ǖʂƋ߂Â��Ă��悢���߂Â������Ȃ��悤�Ƀn�[�h����ƃ\�t�g�����K�p
%     cineq(:, 10*obj.H+1:11*obj.H) = zeros(1,obj.H);
%     cineq(:, 11*obj.H+1:12*obj.H) = zeros(1,obj.H);
    cineq(:, 10*obj.H+1:11*obj.H) = [arrayfun(@(L) abs(det([[X(1,L),X(5,L)]-[param.front(1,L),param.front(2,L)];[param.Sectionconect(L,1),param.Sectionconect(L,2)]-[param.front(1,L),param.front(2,L)]]))/norm([X(1,L),X(5,L)]-[param.front(1,L),param.front(2,L)]) -param.r_limit(2),2:obj.H),0];
    cineq(:, 11*obj.H+1:12*obj.H) = [arrayfun(@(L) abs(det([[X(1,L),X(5,L)]-[param.front(1,L),param.front(2,L)];[param.Sectionconect(L,1),param.Sectionconect(L,2)]-[param.front(1,L),param.front(2,L)]]))/norm([X(1,L),X(5,L)]-[param.front(1,L),param.front(2,L)]) -param.r_limit(1) - S(2,L),2:obj.H),0];
    %���@�̂ƕǁ@�ʘH���̐���@�n�[�h����̂݁@�o�H�Ǐ]���s�����߃\�t�g����s�v
    cineq(:, 12*obj.H+1:13*obj.H) = [arrayfun(@(L) -X(5,L)+param.wall_width_y(L,1)  , 2:obj.H),0];
    cineq(:, 13*obj.H+1:14*obj.H) = [arrayfun(@(L) X(5,L)-param.wall_width_y(L,2)  , 2:obj.H),0];
    cineq(:, 14*obj.H+1:15*obj.H) = [arrayfun(@(L) -X(1,L)+param.wall_width_x(L,1)  , 2:obj.H),0];
    cineq(:, 15*obj.H+1:16*obj.H) = [arrayfun(@(L) X(1,L)-param.wall_width_x(L,2)  , 2:obj.H),0];

dceq   = jacobian(ceq  , vec).'; % .' performs transpose
dcineq = jacobian(cineq, vec).'; % .' performs transpose
%% Evaluation function
% ���f���\������̕]���l���v�Z����v���O����    
%�O����@�̂Ƃ̋�����ݒ�
% [Cdis] = arrayfun(@(L) Linedistance(X(1,L),X(5,L),param.sectionpoint,param.Section_change(2)),1:obj.H,'UniformOutput',true);
FCdis = param.FLD - param.Cdis;%��@�O�̋@�̂Ƃ̌o�H�㋗��
BCdis = param.Cdis- param.BLD;%���@�̂Ƃ̌o�H��̋���
MiddleDisF =  (FCdis - BCdis).^2;

%reference
%�Q�ƋO���Ǝ��@�̂̋���
% Line_Y = arrayfun(@(L) pchip(param.P_chips(1,:),param.P_chips(2,:),X(1,L)),1:obj.H,'UniformOutput',true);
tildeT = sqrt((X(5,:) - param.Line_Y).^2);%Input

%���͂ƎQ�Ɠ��͂̍�(�ڕW0)
tildeU = U;

%���@�̂̑��x
v = [X(2,:);X(6,:)];

%-- �@�̊ԋ����y�юQ�ƋO���Ƃ̕΍�����ѓ��͂̃X�e�[�W�R�X�g���v�Z
stageMidF =  arrayfun(@(L) MiddleDisF(:,L)' * param.Qm * MiddleDisF(:,L),1:Horizon);
stageTrajectry = arrayfun(@(L) tildeT(:,L)' * param.Qt * tildeT(:,L),1:Horizon);
stageInput = arrayfun(@(L) tildeU(:, L)' * param.R * tildeU(:, L), 1:Horizon);
stageSlack_s = arrayfun(@(L) S(1,L)' * param.W_s * S(1,L),1:Horizon);%�X���[���[�g�̃X���b�N�ϐ�
stageSlack_r = arrayfun(@(L) S(2,L)' * param.W_r * S(2,L),2:obj.H);%�ŏI�܂Ł@�P�[�u���ƕ�
stagevelocity = arrayfun(@(L) v(:,L)' * param.V * v(:,L),1:Horizon);

%-- ��Ԃ̏I�[�R�X�g���v�Z
terminalMidF = MiddleDisF(:,end)' * param.Qmf * MiddleDisF(:,end);
terminalTrajectry = tildeT(:,end)' * param.Qtf * tildeT(:,end);
terminalvelocity = v(:,end)' * param.V * v(:,end);

%-- �]���l�v�Z
eval = sum(stageMidF + stageTrajectry + stageInput + stageSlack_s + stageSlack_r + stagevelocity) + terminalTrajectry + terminalvelocity +  terminalMidF;
deval = simplify(jacobian(eval,  vec));
heval = simplify(jacobian(deval, vec));
%% Making m-file
% You may need to use currdir = pwd
currdir  = [pwd, filesep];  
%%
vars     = {x ,param.V,param.Qm,param.Qmf,param.Qt,param.Qtf,param.R,param.W_s,param.W_r,param.Cdis,param.FLD,param.BLD,param.Line_Y};
outputs  = {'eval', 'deval'};
filename = [currdir, 'autoEval.m'];
matlabFunction(eval, deval, 'file', filename, 'vars', vars, 'outputs', outputs);
% movefile('autoEval.m', 'src\gradient');
%%
% vars     = {x, param.Qt, param.Qtf, param.Qd_f, param.Qd_b, param.Qdf_f, param.Qdf_b, param.W_s, param.W_r, param.W_wx, param.W_wy, param.R, param.front, param.behind, param.D,param.LY};
% outputs  = {'heval'};
% filename = [currdir, 'autoHess.m'];
% matlabFunction(heval, 'file', filename, 'vars', vars, 'outputs', outputs);
% movefile('autoHess.m', 'src\gradient');
%%
% vars     = {x, param.X0, param.A, param.B, param.Slew, param.D_lim, param.front, param.behind, param.Sectionconect, param.wall_width_x, param.wall_width_y, param.r_limit};
% outputs  = {'cineq', 'ceq', 'dcineq', 'dceq'};
% filename = [currdir, 'autoCons.m'];
% matlabFunction(cineq, ceq, dcineq, dceq, 'file', filename, 'vars', vars, 'outputs', outputs);
%  movefile('autoCons.m', 'src\gradient');
 
