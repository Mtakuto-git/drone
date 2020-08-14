function dxg = G(in1,in2)
%G
%    DXG = G(IN1,IN2)

%    This function was generated by the Symbolic Math Toolbox version 8.4.
%    13-Mar-2020 15:40:58

jx = in2(:,3);
jy = in2(:,4);
jz = in2(:,5);
km1 = in2(:,7);
km2 = in2(:,8);
km3 = in2(:,9);
km4 = in2(:,10);
l = in2(:,2);
m = in2(:,1);
q0 = in1(1,:);
q1 = in1(2,:);
q2 = in1(3,:);
q3 = in1(4,:);
t2 = q0.^2;
t3 = q1.^2;
t4 = q2.^2;
t5 = q3.^2;
t6 = q0.*q1.*2.0;
t7 = q0.*q2.*2.0;
t8 = q1.*q3.*2.0;
t9 = q2.*q3.*2.0;
t10 = 1.0./jx;
t11 = 1.0./jy;
t12 = 1.0./jz;
t13 = 1.0./m;
t15 = sqrt(2.0);
t14 = -t9;
t16 = -t3;
t17 = -t4;
t18 = t7+t8;
t21 = (l.*t10.*t15)./2.0;
t22 = (l.*t11.*t15)./2.0;
t19 = t6+t14;
t20 = t13.*t18;
t24 = -t21;
t25 = -t22;
t27 = t2+t5+t16+t17;
t23 = t13.*t19;
t28 = t13.*t27;
t26 = -t23;
dxg = reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,t20,t26,t28,t24,t22,km1.*t12,0.0,0.0,0.0,0.0,0.0,0.0,0.0,t20,t26,t28,t24,t25,-km2.*t12,0.0,0.0,0.0,0.0,0.0,0.0,0.0,t20,t26,t28,t21,t22,-km3.*t12,0.0,0.0,0.0,0.0,0.0,0.0,0.0,t20,t26,t28,t21,t25,km4.*t12],[13,4]);