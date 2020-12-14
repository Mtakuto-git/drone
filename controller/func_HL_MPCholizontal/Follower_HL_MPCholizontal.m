classdef Follower_HL_MPCholizontal < CONTROLLER_CLASS
    % �N�A�b�h�R�v�^�[�p�K�w�^���`�����g�������͎Z�o
    properties
        options
        param
        model
        result
        self
        Section_change
        previous_variables
        slack
        P_chips
        wall_width_y
        wall_width_x
        S_limit
        Sectionconect
    end
    
    methods
        
        function obj = Follower_HL_MPCholizontal(self,param)
            obj.self = self;
            
            %---MPC�p�����[�^�ݒ�---%
            obj.param.H  = param.H;                % ���f���\������̃z���C�]�� 
            obj.param.dt = param.dt;              % ���f���\������̍��ݎ���
            obj.param.N  = param.N;
            
            obj.param.P = param.P;
            obj.param.F1 = param.F1;%z
            obj.param.F2 = param.F2;%x
            obj.param.F3 = param.F3;%y
            obj.param.F4 = param.F4;%yaw

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
            obj.slack=zeros(2,obj.param.Num);
            %�d��%
            %Follower drone weight paramerter
            obj.param.V =  diag([10.;10.]);%���x
            obj.param.Qm = 10;%�@�̊ԋ���Ql 10
            obj.param.Qmf = 10;%�@�̊ԋ����̏I�[�R�X�gQlf  10
            obj.param.Qt = 40;%�o�H�Ƃ̋���Qr
            obj.param.Qtf = 50;%�o�H�Ƃ̋����̏I�[�R�X�gQrf 50
            obj.param.R  = diag([1.;1.]);    % ���f���\������̓��͂ɑ΂���X�e�[�W�R�X�g�d��
            obj.param.Num= obj.param.H + 1;
            obj.param.W_s = 40;%�X���b�N�ϐ��̏d��
            obj.param.W_r = 20;
            %�X���[���[�g���ۂ���̐ݒ�
            obj.param.Slew = 0.1;
            %���񋗗�
            obj.param.D_lim = [3,0.1];%[3,0.5]
            %�P�[�u���ɑ΂��鐧��
            obj.param.r_limit = [0.3,0.6];%[soft,hard]
            
%             obj.previous_variables = ones(obj.param.input_size + obj.param.state_size,obj.param.Num);
            obj.previous_variables = param.arranged_pos(1:2,obj.self.id);
            obj.previous_variables = repmat([obj.previous_variables(1);zeros(3,1);obj.previous_variables(2);zeros(5,1)],1,obj.param.Num);
            
            
            obj.model = self.model;
            obj.param.A = sysd.A;
            obj.param.B = sysd.B;
            


            obj.param.P_chips = param.P_chips;
            
            %�o�H��
            obj.param.wall_width_y = param.wall_width_y;
            obj.param.wall_width_x = param.wall_width_x;
            
            
%             %�Z�N�V�����|�C���g
            obj.param.sectionpoint = param.sectionpoint;
            obj.param.sectionnumber = param.Sectionnumber;
            obj.param.Section_change = param.Section_change;
            [obj.S_limit,~] = size(obj.param.sectionpoint);
            obj.param.Sectionconect=param.Sectionconect;
            obj.param.wall_width_xx = param.wall_width_xx;
            obj.param.wall_width_yy = param.wall_width_yy;
            
            obj.param.Cdis = param.Cdis;
            obj.param.Line_Y = param.Line_Y;
            

            if isfield(param,'agent');obj.param.agent=param.agent;end
        end
        function u = do(obj,~,~)
                        % param{1} : ���肵��state�\����
            % param{2} : �Q�Ə�Ԃ̍\����
            % param{3} : �\���́F�����p�����[�^P�C�Q�C��F1-F4 
            modelstate = obj.self.estimator.result.state;
            
            modelstate.q=(eul2quat(modelstate.q','XYZ'))';%�I�C���[����N�H�[�^�j�I���ւ̕ϊ�

            
%             x = modelstate.get; % [q, p, v, w]�ɕ��בւ�
            x = [modelstate.q;modelstate.p;modelstate.v;modelstate.w];
            xd = obj.self.reference.result.state.get();
            xd=[xd;zeros(20-size(xd,1),1)];% ����Ȃ����͂O�Ŗ��߂�D
            %x=cell2mat(arrayfun(@(t) state.(t)',string(state.list),'UniformOutput',false))';
            %x = state.get();%��ԃx�N�g���Ƃ��Ď擾
            %���z���́C���z�o�͎Z�o
            if isfield(obj.param,'dt')
                dt = obj.param.dt;
                vf = Vfd(dt,x,xd',obj.param.P,obj.param.F1);
            else
                vf = Vf(x,xd',obj.param.P,obj.param.F1);
            end
            vs = Vs(x,xd',vf,obj.param.P,obj.param.F2,obj.param.F3,obj.param.F4);
            v4 = vs(3);
            %����Ԃ����z��Ԃɕϊ�
            xd1 = zeros(20,1);
            h2 = Z2(x,xd1',vf,obj.param.P);   %x�����̉��z���
            h3 = Z3(x,xd1',vf,obj.param.P);   %y����
            %h2��h3����Ԃɂ���MPC
            
            % �Z�N�V�����`�F���W�X�V
            [obj.param.Section_change] = Sectionnumbersetting(obj.param.sectionnumber,obj.S_limit);

 %%%%%%%%%%%%%%%%%%%%param�ɑS�@�̂�agent�����đΉ�%%%%%%%%%%%%%%%%%%%%%      
%             frontUAVnum = string(obj.self.id-1);% ��@�O�̋@�̔ԍ�(string�^)
%             strSC = strcat('agent(',frontUAVnum,').controller.mpc_f.param.Section_change');% ���̕����ƌ���
%             obj.param.S_front = evalin('base',strSC);% ���C���̃��[�N�X�y�[�X������������Ă���
            if isfield(obj.param,'agent')
                obj.param.S_front=obj.param.agent(obj.self.id-1).controller.mpc_f.param.Section_change;
            else
                obj.param.S_front=obj.param.Section_change;
            end
            obj.param.S_front(obj.param.S_front>obj.S_limit) = obj.S_limit;% S_limit���傫���Ȃ�Ȃ��悤��
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
            
%���@��
            %�敪�������̐���ύX
            prev_sp = obj.param.sectionpoint(obj.param.Section_change(1),:);%previous section
            now_sp =obj.param.sectionpoint(obj.param.Section_change(2),:);%now section
            next_sp = obj.param.sectionpoint(obj.param.Section_change(3),:);%next section
            n_next_sp =obj.param.sectionpoint(obj.param.Section_change(4),:);%nextnext section
            prev_r = abs(det([[prev_sp(1),prev_sp(2)]-[now_sp(1),now_sp(2)];[x(5),x(6)]-[now_sp(1),now_sp(2)]]))/norm([prev_sp(1),prev_sp(2)]-[now_sp(1),now_sp(2)]);
            next_r =abs(det([[next_sp(1),next_sp(2)]-[n_next_sp(1),n_next_sp(2)];[x(5),x(6)]-[n_next_sp(1),n_next_sp(2)]]))/norm([next_sp(1),next_sp(2)]-[n_next_sp(1),n_next_sp(2)]);
            [~,PcSection] = min([prev_r;next_r]);
            
            
            

%             xx = [obj.param.sectionpoint(1,1),obj.param.sectionpoint(2,1)-0.1,obj.param.sectionpoint(3,1)];
%             yy = [obj.param.sectionpoint(1,2),obj.param.sectionpoint(2,2),obj.param.sectionpoint(3,2)];
%             obj.param.P_chips = [xx;yy];

            
            Pchipvariables =Line_Setting(obj.param.sectionnumber,obj.param.sectionpoint,PcSection,obj.S_limit);
            obj.param.P_chips = Pchipvariables;

            
            %���[�v�̒��ŕϓ�����p�����[�^��ݒ�
            %evalin�͏d���̂Ń��[�v���ł͎g��Ȃ�


%           main��typical_Sensor_RangePos���I���ɂ���obj.self.sensor.result�̒���neighbor�����������Ă���D1��ڂ��O�̋@�̂ŁC���ڂ����̋@��
            obj.param.front = [repmat([obj.self.sensor.result.neighbor(1,obj.self.id-1);obj.self.sensor.result.neighbor(2,obj.self.id-1)],1,obj.param.Num)];%�O�@�̂̍��W
            obj.param.behind = repmat([obj.self.sensor.result.neighbor(1,obj.self.id);obj.self.sensor.result.neighbor(2,obj.self.id)],1,obj.param.Num);

            
            
            obj.param.X0 = [h2;h3];
            obj.param.Xd = xd;
%             obj.param.sectionpoint(end,:) = obj.self.sensor.result.rigid(1).p(1:2);% �擪�@�̂̈ʒu���W�����������Ă���
            
            
            
                       
            %�O��@�̂Ƃ̋����X�V
%             FstrSN = strcat('agent(',frontUAVnum,').controller.mpc_f.param.sectionnumber');
%             obj.param.frontSN = evalin('base',FstrSN);
            
%             behindUAVnum = string(obj.self.id+1);% ��@��̋@�̔ԍ�(string�^)
%             BstrSN = strcat('agent(',behindUAVnum,').controller');
%             Bcontroller = evalin('base',BstrSN);
            % �ŏI�@�̂ł̃G���[���
            if isfield(obj.param,'agent')            %�O�@�̂̃Z�N�V�����i���o�[
                obj.param.frontSN = obj.param.agent(obj.self.id-1).controller.mpc_f.param.sectionnumber;
            else
                obj.param.frontSN =1;
            end
            if isfield(obj.param,'agent')            %���@��
                if obj.self.id+1 ~= obj.param.N
                    obj.param.behindSN = obj.param.agent(obj.self.id+1).controller.mpc_f.param.sectionnumber;
                else
                obj.param.behindSN = 1;
                end
            else
                obj.param.behindSN = 1;
            end

            obj.param.FLD = cell2mat(arrayfun(@(L) Linedistance(obj.param.front(1,L),obj.param.front(2,L),obj.param.sectionpoint,obj.param.frontSN),1:obj.param.Num,'UniformOutput',false));
            obj.param.BLD = Linedistance(obj.self.sensor.result.neighbor(1,obj.self.id),obj.self.sensor.result.neighbor(2,obj.self.id),obj.param.sectionpoint,obj.param.behindSN);



            
%========================MEX������===================================%    

        if isfield(obj.param,'agent')
            tmp=obj.param.agent;
            obj.param.agent=0;
            MPCparam = obj.param;
            obj.param.agent=tmp;
        else
            obj.param.agent=0;
            MPCparam = obj.param;
        end
            MPCprevious_variables = obj.previous_variables;
            MPCslack = obj.slack;
%             var = F_HL_MPCfunc(MPCparam,MPCprevious_variables,MPCslack);
            var=F_HL_MPCfunc_mex(MPCparam,MPCprevious_variables,MPCslack);%MEX��

%==================================================================%
            obj.previous_variables = var(1:10,:);            
            v23 = var(obj.param.state_size + 1:obj.param.total_size, 1); % �œK���v�Z�ł̌��ݎ����̓��͂𐧌�ΏۂɈ������͂Ƃ��č̗p
            v2 = v23(1);%x�����̉��z�o��
            v3 = v23(2);%y����
           
            %�]���l����������ۑ�
%             tmp_fval(N) = fval;
%             disp(fval);
            %�v�Z�̎w�W���ꎞ�ۑ�
%             tmp_exitflag(N) = exitflag;
            
            
            vxy=[v2,v3];%x������y�����̉��z����
            vs=[vxy,v4];

%           ��ԕύX    2�̏ꍇ���̃Z�N�V��������ԋ߂��D�R�ɂȂ����Ƃ��̂ݎ��Z�N�V�����ɕύX��2�ɖ߂�
            FSectionPlus = SectionNumchange(x(5:7),obj.param.sectionpoint,obj.param.Section_change);

            obj.param.sectionnumber = obj.param.sectionnumber + FSectionPlus - 2;
            if obj.param.sectionnumber < 1
                obj.param.sectionnumber = 1;
            end
            

    %-----------------------------------------------------------------%
            obj.result.input = Uf(x,xd',vf,obj.param.P) + Us(x,xd',vf,vs',obj.param.P);
            obj.result.var = var;
            


            u = obj.result;
%             obj.self.input = obj.result.input;%�������ɕύX2020/10/22
            
        end
        function show(obj)
            obj.result
        end
       
    end
end

