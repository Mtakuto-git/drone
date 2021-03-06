function Controller  = Controller_FT(dt)
%% controller class demo (1) : construct
% controller property πController classΜCX^XzρΖ΅Δθ`
Controller_param.P=getParameter();
% % Controller_param.F1=lqrd([0 1;0 0],[0;1],diag([10,1]),[1],dt);                                % z 
% Controller_param.F2=lqrd([0 1 0 0;0 0 1 0;0 0 0 1; 0 0 0 0],[0;0;0;1],diag([1000,10,10,1]),[1],dt); % xdiag([100,10,10,1])
% Controller_param.F3=lqrd([0 1 0 0;0 0 1 0;0 0 0 1; 0 0 0 0],[0;0;0;1],diag([1000,10,10,1]),[1],dt); % ydiag([100,10,10,1])
% % Controller_param.F4=lqrd([0 1;0 0],[0;1],diag([100,1]),[1],dt);                       % [p 
Controller_param.F1=lqrd([0 1;0 0],[0;1],diag([10,1]),[1],dt);                                % z 
Controller_param.F2=lqrd([0 1 0 0;0 0 1 0;0 0 0 1; 0 0 0 0],[0;0;0;1],diag([1000,10,10,1]),[0.8],dt); % xdiag([100,10,10,1])
Controller_param.F3=lqrd([0 1 0 0;0 0 1 0;0 0 0 1; 0 0 0 0],[0;0;0;1],diag([1000,10,10,1]),[0.8],dt); % ydiag([100,10,10,1])
Controller_param.F4=lqrd([0 1;0 0],[0;1],diag([100,1]),[1],dt);                       % [p 
% Ιzu
Eig=[-3.2,-2,-2.5,-2.1];
% Controller_param.F1=lqrd([0 1;0 0],[0;1],diag([10,1]),[1],dt);                                % z 
% % Controller_param.F2=place(diag([1,1,1],1),[0;0;0;1],Eig);
% % Controller_param.F3=place(diag([1,1,1],1),[0;0;0;1],Eig);
% Controller_param.F4=lqrd([0 1;0 0],[0;1],diag([100,1]),[1],dt);                       % [p 


Controller_param.dt = dt;
 eig(diag([1,1,1],1)-[0;0;0;1]*Controller_param.F2)
Controller.type="FTController_quadcopter";
Controller.name="ftcontroller";
Controller.param=Controller_param;

%assignin('base',"Controller_param",Controller_param);

end
