classdef HLController_ATMEC < CONTROLLER_CLASS
    % クアッドコプター用階層型線形化を使った入力算出にモデル誤差補償器を導入
    properties
        self
        result
        param
        Q
        A2 = [0 1;0 0];
        B2 = [0;1];
        A4 =diag([1 1 1],1);
        B4 = [0;0;0;1];
        A2d
        B2d
        A4d
        B4d
        time % 稼働時間関連の格納
        dv1p %1時刻前の補償入力
        vp%１時刻前の仮想入力
        % RLSアルゴリズム
        G%相関関数
        g
        gamma %相関関数係数
        lambda%忘却係数
        alpha %ローパスフィルタ強度
        %評価関数計算
        h % =M*(xi_n(i) - xi_a(i))
        % eta = M*v(i)-F(xi_a(i) - M*xi_a(i))
        eta1 % =M*v(i)
        eta2  % =M*xi_a(i)

    end
    
    methods
        function obj = HLController_ATMEC(self,param,~)
            obj.self = self;
            obj.param = param;
            obj.Q = STATE_CLASS(struct('state_list',["q"],'num_list',[4]));
            %MEC
            obj.dv1p = 0;
            obj.result.K = param.K;
            %階層型線形化
            obj.A2 = param.A2;
            obj.B2 = param.B2;
            obj.A4 = param.A4;
            obj.B4 = param.B4;
            obj.A2d = param.A2d;
            obj.B2d = param.B2d;
            obj.A4d = param.A4d;
            obj.B4d = param.B4d;
            %AT-MEC
            %各変数初期化
            obj.vp= [0 0 0];
            obj.result.Khat = param.K;
            obj.h.z1 = [0;0];
            obj.h.z2 = [0;0;0;0];
            obj.h.z3 = [0;0;0;0];
            obj.eta1.z1 = [0;0];
            obj.eta1.z2 = [0;0;0;0];
            obj.eta1.z3 = [0;0;0;0];
            obj.eta2.z1 = [0;0];
            obj.eta2.z2 = [0;0;0;0];
            obj.eta2.z3 = [0;0;0;0];
            obj.alpha = param.alpha;
            obj.gamma = param.gamma;
            obj.lambda = param.lambda;
            obj.G.z1=param.gamma.z*eye(2);
            obj.G.z2=param.gamma.x*eye(4);
            obj.G.z3=param.gamma.y*eye(4);
            obj.g.z1=[0;0];
            obj.g.z2=[0;0;0;0];
            obj.g.z3=[0;0;0;0];
            
            obj.time.dataCount =0; %稼働時間計算用プログラム実行回数
            obj.time.RLS_begin = param.RLS_begin; %補償ゲインの更新を始める時間
            obj.time.FRIT_begin = param.FRIT_begin;%補償ゲインの推定を始める時間
        end
        
        function result = do(obj,param,varargin) 
            % param (optional) : 構造体：物理パラメータP，ゲインF1-F4 
            % varargin : nominal input
            
            model = obj.self.model;
            ref = obj.self.reference.result;
           plant = obj.self.estimator;%estimatorの値をシステムの出力とみなす

            if isprop(ref.state,'xd')
                xd = ref.state.xd; % 20次元の目標値に対応するよう
            else
                xd = ref.state.get();
            end
            Param= obj.param;
            P = Param.P;
            F1 = Param.F1;
            F2 = Param.F2;
            F3 = Param.F3;
            F4 = Param.F4;
            xd=[xd;zeros(20-size(xd,1),1)];% 足りない分は０で埋める．
            %x=cell2mat(arrayfun(@(t) state.(t)',string(state.list),'UniformOutput',false))';
            %x = state.get();%状態ベクトルとして取得
% 
            Rb0 = RodriguesQuaternion(Eul2Quat([0;0;xd(4)]));
            xn = [R2q(Rb0'*model.state.getq("rotmat"));Rb0'*model.state.p;Rb0'*model.state.v;model.state.w]; % [q, p, v, w]に並べ替え
            x = [R2q(Rb0'*plant.result.state.getq("rotmat"));Rb0'*plant.result.state.p;Rb0'*plant.result.state.v;plant.result.state.w]; % [q, p, v, w]に並べ替え
            xd(1:3)=Rb0'*xd(1:3);
            xd(4) = 0;
            xd(5:7)=Rb0'*xd(5:7);
            xd(9:11)=Rb0'*xd(9:11);
            xd(13:15)=Rb0'*xd(13:15);
            xd(17:19)=Rb0'*xd(17:19);
            
            if isfield(Param,'dt')
                dt = Param.dt;
                vfn = Vfd(dt,xn,xd',P,F1);
                vf = Vfd(dt,x,xd',P,F1);
            else
                vfn = Vf(xn,xd',P,F1);%v1
                vf = Vf(x,xd',P,F1);%v1
            end
            
%% MEC
            Kz = obj.result.K(1:2);
            Kx = obj.result.K(3:6);
            Ky = obj.result.K(7:10);
           %nominalを線形化
%             obj.xn=obj.state.get();
            z1n = Z1(xn,xd',P);
            z2n = Z2(xn,xd',vfn,P);
            z3n = Z3(xn,xd',vfn,P);
            z4n = Z4(xn,xd',vfn,P);

            yn = [z1n;z2n;z3n;z4n];
            
            %plantを線形化
            z1 = Z1(x,xd',P);
            z2 = Z2(x,xd',vf,P);
            z3 = Z3(x,xd',vf,P);
            z4 = Z4(x,xd',vf,P);
            y = [z1;z2;z3;z4];

            dy = yn - y; %理想状態との誤差を算出
            
            dv1 =  Kz*dy(1:2);%補償入力
            dv1d = (dv1 - obj.dv1p)/dt;
            
            vf = vf + [dv1 dv1d 0 0];
            
            vs = Vs(x,xd',vf,P,F2,F3,F4);%v2-4
            dv2 = Kx* dy(3:6);
            dv3 = Ky* dy(7:10);
            dv4 = 0;
            vs = vs + [dv2 dv3 dv4];
            
           tmp = Uf(x,xd',vf,P) + Us(x,xd',vf,vs',P);   %Uf,Us:実入力変換
           obj.result.input = [tmp(1);
                                        tmp(2);
                                        tmp(3);
                                        tmp(4)];
            
%             obj.result.input = Uf(x,xd',vf,P) + Us(x,xd',vf,vs',P); 
             
%% AT-MEC
            Kz_hat = obj.result.Khat(1:2);
            Kx_hat = obj.result.Khat(3:6);
            Ky_hat = obj.result.Khat(7:10);
            
            obj.time.dataCount=obj.time.dataCount+1;
% FRIT
            %FRIT_beginで指定した時間までFRIT,RLSを実行しない
            if(obj.time.dataCount*dt<obj.time.FRIT_begin)
                eta.z1 = obj.eta1.z1(1) - F1*(z1 - obj.eta2.z1);
                epsilon.z1 = Kz*obj.h.z1 - eta.z1;
                eta.z2 = obj.eta1.z2(1) - F2*(z2 - obj.eta2.z2);
                epsilon.z2 = Kx*obj.h.z2 - eta.z2;
                eta.z3 = obj.eta1.z3(1) - F3*(z3 - obj.eta2.z3);
                epsilon.z3 = Ky*obj.h.z3 - eta.z3;
            end
            if(obj.time.dataCount*dt>=obj.time.FRIT_begin)
            % １時刻後の状態を離散化した状態方程式から計算
                %z1
                obj.h.z1 = IdealModel(obj.A2d,obj.B2d,obj.h.z1,z1n-z1,F1);
                udu.z1 = [vf(1);(vf(1)-obj.vp(1))/dt];
                obj.eta1.z1 = IdealModel(obj.A2d,obj.B2d,obj.eta1.z1,udu.z1,F1);
                obj.eta2.z1 = IdealModel(obj.A2d,obj.B2d,obj.eta2.z1,z1,F1);
                eta.z1 = obj.eta1.z1(1) - F1*(z1 - obj.eta2.z1);
                epsilon.z1 = Kz*obj.h.z1 - eta.z1;
                %z2
                obj.h.z2 = IdealModel(obj.A4d,obj.B4d,obj.h.z2,z2n-z2,F2);
                udu.z2 = [vs(1);(vs(1)-obj.vp(2))/dt;0;0];
                obj.eta1.z2 = IdealModel(obj.A4d,obj.B4d,obj.eta2.z2,udu.z2,F2);
                obj.eta2.z2 = IdealModel(obj.A4d,obj.B4d,obj.eta2.z2,z2,F2);
                eta.z2 = obj.eta1.z2(1) - F2*(z2 - obj.eta2.z2);
                epsilon.z2 = Kx*obj.h.z2 - eta.z2;
                %z3
                obj.h.z3 = IdealModel(obj.A4d,obj.B4d,obj.h.z3,z3n-z3,F3);
                udu.z3 = [vs(2);(vs(2)-obj.vp(3))/dt;0;0];
                obj.eta1.z3 = IdealModel(obj.A4d,obj.B4d,obj.eta2.z3,udu.z3,F3);
                obj.eta2.z3 = IdealModel(obj.A4d,obj.B4d,obj.eta2.z3,z3,F3);
                eta.z3 = obj.eta1.z3(1) - F3*(z3 - obj.eta2.z3);
                epsilon.z3 = Ky*obj.h.z3 - eta.z3;
% RLS
                %z1
                hGh = obj.h.z1'*obj.G.z1*obj.h.z1;
                obj.g.z1 = (obj.G.z1 * obj.h.z1)/(obj.lambda.z+hGh);
                obj.G.z1 = (obj.G.z1 - obj.g.z1*(obj.h.z1'*obj.G.z1))/obj.lambda.z;
                Kz_hat = Kz_hat+obj.g.z1'*(eta.z1-Kz_hat*obj.h.z1);
                %z2
                hGh = obj.h.z2'*obj.G.z2*obj.h.z2;
                obj.g.z2 = (obj.G.z2 * obj.h.z2)/(obj.lambda.x+hGh);
                obj.G.z2 = (obj.G.z2 - obj.g.z2*(obj.h.z2'*obj.G.z2))/obj.lambda.x;
                Kx_hat = Kx_hat+obj.g.z2'*(eta.z2-Kx_hat*obj.h.z2);
                %z3
                hGh = obj.h.z3'*obj.G.z3*obj.h.z3;
                obj.g.z3 = (obj.G.z3 * obj.h.z3)/(obj.lambda.y+hGh);
                obj.G.z3 = (obj.G.z3 - obj.g.z3*(obj.h.z3'*obj.G.z3))/obj.lambda.y;
                Ky_hat = Ky_hat+obj.g.z3'*(eta.z3-Ky_hat*obj.h.z3);

                %ゲイン更新 コメントアウトで初期補償ゲインのまま=通常のMECと同じ
                obj.result.Khat = [Kz_hat Kx_hat Ky_hat];

                if(obj.time.dataCount*dt>=obj.time.RLS_begin)
%                     alpha = obj.alpha_z; % 12/03 ローパスフィルタを時間で変動させたいな
                    Kz = (1-obj.alpha.z)*Kz+obj.alpha.z*Kz_hat;
                    Kx = (1-obj.alpha.x)*Kx+obj.alpha.x*Kx_hat;
                    Ky = (1-obj.alpha.y)*Ky+obj.alpha.y*Ky_hat;
                    obj.result.K = [Kz Kx Ky];
                end
            end
%% 計算後作業
            %previous 更新
            obj.dv1p =dv1; %dv1p更新
            obj.vp = [vf(1) vs(1) vs(2)];
            
            %% 動作チェック用
            %評価関数
            obj.result.h=obj.h;
            obj.result.eta = eta;
            obj.result.eta1 = obj.eta1;
            obj.result.eta2 = obj.eta2;
            
            obj.result.eps.z = epsilon.z1;
            obj.result.eps.x = epsilon.z2;
            obj.result.eps.y = epsilon.z3;
            %実行した直後であればepssumを初期化 もっといい書き方ないか?
            if (obj.time.dataCount ==1) 
                obj.result.epssum.z = 0;
                obj.result.epssum.x = 0;
                obj.result.epssum.y = 0;
            end 
            obj.result.epssum.z = obj.result.epssum.z*obj.lambda.z+obj.result.eps.z^2;
            obj.result.epssum.x = obj.result.epssum.x*obj.lambda.x+obj.result.eps.x^2;
            obj.result.epssum.y = obj.result.epssum.y*obj.lambda.y+obj.result.eps.y^2;
            %仮想状態
            obj.result.z_out = y;
            obj.result.zn_out = yn;
            %仮想入力
            obj.result.v_out = [vf vs];
            
            %%
            obj.self.input = obj.result.input;
            result = obj.result;
        end
        
        function show(obj)
            obj.result
        end
        
        function result = IdealModel(A,B,state,ref,F)
            %AT-MEC 補償ゲインチューニングのFRITアルゴリズムの入力変換関数
            %   理想モデルMを含む計算
            u = F * (ref - state);
            state = A * state + B * u;
            result = state;
        end

    end
end

