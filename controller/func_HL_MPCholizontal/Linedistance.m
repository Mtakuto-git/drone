function [Dis] = Linedistance(x1,y1,Sectionpoint,Sectionnumber)
%LINE_CALCULATOR 
%2�_��^����ƁC����2�_�����Ԓ����ƁC2�_�Ԃ̋������Z�o���ĕԂ��D
calc_x = [Sectionpoint(1:Sectionnumber,1);x1];
calc_y = [Sectionpoint(1:Sectionnumber,2);y1];
Diss = arrayfun(@(N) realsqrt((calc_x(N,1)-calc_x(N+1,1))^2 + (calc_y(N,1)-calc_y(N+1,1))^2),1:Sectionnumber,'UniformOutput',true);
Dis = sum(Diss);
end