classdef Leader_HL_MPCholizontal < CONTROLLER_CLASS
    % �N�A�b�h�R�v�^�[�p�K�w�^���`�����g�������͎Z�o
    properties
        options
        param
        model
        result
        self
        previous_variables
        linearmodel
    end
    
    methods
        
        function obj = Leader_HL_MPCholizontal(self,param)
            obj.self = self;
            
            
            %---MPC�p�����[�^�ݒ�---%
            obj.param.H  = param.H;                % ���f���\������̃z���C�]�� 
%             obj.param.dt = param.dt;              % ���f���\������̍��ݎ���
            obj.param.dt = 0.2;              % ���f���\������̍��ݎ���
            
            obj.param.Slew=0.5;%0.5
            
%             �\���́F�����p�����[�^P�C�Q�C��F1-F4 
            obj.param.P = param.P;
            obj.param.F1 = param.F1;%z
            obj.param.F2 = param.F2;%x
            obj.param.F3 = param.F3;%y
            obj.param.F4 = param.F4;%yaw

            %�o�H��
            obj.param.wall_width_y = param.wall_width_y;
            obj.param.wall_width_x = param.wall_width_x;

            
            %% Model Setting
            %model state : virtual state 2nd layor h2 h3  MPC����ԕ�����
            A23 = diag([1,1,1],1);
            B23 = [0;0;0;1];
            C=ones(8,8);
            D=zeros(8,2);
            A=blkdiag(A23,A23);
            B=blkdiag(B23,B23);
            sys=ss(A,B,C,D);
            sysd = c2d(sys,obj.param.dt);
            
            
            
            obj.param.input_size = size(sysd.B,2);
            obj.param.state_size = size(sysd.A,2);
            obj.param.total_size = obj.param.input_size + obj.param.state_size;
            obj.param.Num = obj.param.H+1; %������Ԃƃz���C�]�����̍��v
            
            %�d��%
            obj.param.Q = diag(10*ones(1,obj.param.state_size));
            obj.param.R = diag(10*ones(1,obj.param.input_size));
            obj.param.Qf = diag(10*ones(1,obj.param.state_size));
            
%             obj.previous_variables = zeros(obj.param.input_size + obj.param.state_size,obj.param.Num);
            obj.previous_variables = param.arranged_pos(1:2,1);%main��arranged_pos������������Ă������̋@�̂̏����ʒu���z���C�]�������g��
            obj.previous_variables = repmat([obj.previous_variables(1);zeros(3,1);obj.previous_variables(2);zeros(5,1)],1,obj.param.Num);


            
            obj.param.Pdata=param.Pdata;
            
            obj.model = self.model;
            obj.linearmodel.A = sysd.A;
            obj.linearmodel.B = sysd.B;
            
% %             %�Z�N�V�����|�C���g
% %             run('SectionsSetting');
            obj.param.sectionpoint = param.sectionpoint;
            obj.param.sectionnumber = param.Sectionnumber;
            obj.param.P_limit=param.P_limit;%SectionsSetting�̂Ȃ���PointToLeader�̍s�����Z�N�V�����|�C���g�̐�
            obj.param.Section_change = param.Section_change;
        end
        function u = do(obj,~,~)
            
            if strcmp(obj.self.reference.point.flight_phase ,'f')

            modelstate = state_copy(obj.self.estimator.result.state);
            
            modelstate.q=(eul2quat(modelstate.q','XYZ'))';%�I�C���[����N�H�[�^�j�I���ւ̕ϊ�
            
            
%             x = modelstate.get; % [q, p, v, w]�ɕ��בւ�
            x = [modelstate.q;modelstate.p;modelstate.v;modelstate.w];
            xd = obj.self.reference.result.state.get();
            xd=[xd;zeros(20-size(xd,1),1)];% ����Ȃ����͂O�Ŗ��߂�D
            
            if isfield(obj.param,'dt')
                dt = obj.param.dt;
                vf = Vfd(dt,x,xd',obj.param.P,obj.param.F1);
            else
                vf = Vf(x,xd',obj.param.P,obj.param.F1);
            end
            vs = Vs(x,xd',vf,obj.param.P,obj.param.F2,obj.param.F3,obj.param.F4);
            v4 = vs(3);
            %����Ԃ����z��Ԃɕϊ�
            h2 = Z2(x,zeros(20,1)',vf,obj.param.P);   %x�����̉��z���
            h3 = Z3(x,zeros(20,1)',vf,obj.param.P);   %y����
            %h2��h3����Ԃɂ���MPC
            
            %���[�v�̒��ŕϓ�����p�����[�^��ݒ�
            obj.param.X0 = [h2;h3];
            obj.param.Xd = xd;
            
            [ref] = calcreference(h2,h3,obj.param.Num,obj.param.Pdata,obj.param.dt);
            obj.param.Xr = ref;

            
 %============================MEX������================================%    
 

            MPCparam.Q = obj.param.Q;
            MPCparam.Qf = obj.param.Qf;
            MPCparam.R = obj.param.R;
            MPCparam.Xr = obj.param.Xr;
            MPCparam.X0 = obj.param.X0;
            MPCparam.Slew = obj.param.Slew;
            linear_model = obj.linearmodel;
            MPCprevious_variables = obj.previous_variables;
%             funcresult = L_HL_MPCfunc(MPCparam,linear_model,MPCprevious_variables);%�ʏ��function
            funcresult=L_HL_MPCfunc_mex(MPCparam,linear_model,MPCprevious_variables);%MEX����
 %====================================================================%       
            obj.previous_variables = funcresult;

            v23 = obj.previous_variables(obj.param.state_size + 1:obj.param.total_size, 1); % �œK���v�Z�ł̌��ݎ����̓��͂𐧌�ΏۂɈ������͂Ƃ��č̗p
            v2 = v23(1);%x�����̉��z�o��
            v3 = v23(2);%y����
            vxy=[v2,v3];%x������y�����̉��z����
            vs=[vxy,v4];
            
            %��ԕύX�p
            [obj.param.Section_change] = Sectionnumbersetting(obj.param.sectionnumber,obj.param.P_limit+1);
            [LSectionPlus] = SectionNumchange(x(5:7),vertcat([0,0],obj.param.Pdata.Target),obj.param.Section_change);
            
            obj.param.sectionnumber = obj.param.sectionnumber + LSectionPlus - 2;
                if obj.param.sectionnumber < 1
                    obj.param.sectionnumber = 1;
                end

    %-----------------------------------------------------------------%
            obj.result.input = Uf(x,xd',vf,obj.param.P) + Us(x,xd',vf,vs',obj.param.P);
            obj.result.var = obj.previous_variables;

            %���[�_�[�@�̗p�̍X�V
            obj.param.Pdata.flag = obj.param.sectionnumber(1);

            u = obj.result;
            obj.self.input = obj.result.input;%�������ɕύX2020/10/22

            
            else
                            % param (optional) : �\���́F�����p�����[�^P�C�Q�C��F1-F4
            model = obj.self.estimator.result;
            ref = obj.self.reference.result;
            x = [model.state.getq('compact');model.state.p;model.state.v;model.state.w]; % [q, p, v, w]�ɕ��בւ�
            if isprop(ref.state,'xd')%~isempty(ref.state.xd)
                xd = ref.state.xd; % 20�����̖ڕW�l�ɑΉ�����悤
            else
                xd = ref.state.get();
            end
            Param= obj.param;
            P = Param.P;
            F1 = Param.F1;
            F2 = Param.F2;
            F3 = Param.F3;
            F4 = Param.F4;
            %     xd=Xd.p;
            %     if isfield(Xd,'v')
            %         xd=[xd;Xd.v];
            %         if isfield(Xd,'dv')
            %             xd=[xd;Xd.dv];
            %         end
            %     end
            xd=[xd;zeros(20-size(xd,1),1)];% ����Ȃ����͂O�Ŗ��߂�D
            
            Rb0 = RodriguesQuaternion(Eul2Quat([0;0;xd(4)]));
            x = [R2q(Rb0'*model.state.getq("rotmat"));Rb0'*model.state.p;Rb0'*model.state.v;model.state.w]; % [q, p, v, w]�ɕ��בւ�
            xd(1:3)=Rb0'*xd(1:3);
            xd(4) = 0;
            xd(5:7)=Rb0'*xd(5:7);
            xd(9:11)=Rb0'*xd(9:11);
            xd(13:15)=Rb0'*xd(13:15);
            xd(17:19)=Rb0'*xd(17:19);
            
            if isfield(Param,'dt')
                dt = Param.dt;
                vf = Vfd(dt,x,xd',P,F1);
            else
                vf = Vf(x,xd',P,F1);
            end
            vs = Vs(x,xd',vf,P,F2,F3,F4);
            tmp = Uf(x,xd',vf,P) + Us(x,xd',vf,vs',P);
            obj.result.input = [tmp(1);
                tmp(2);tmp(3);
                tmp(4)];
            obj.self.input = obj.result.input;
            u = obj.result;

            end
        end
        function show(obj)
            obj.result
        end
        
       
    end
end
 
