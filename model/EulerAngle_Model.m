classdef EulerAngle_Model < MODEL_CLASS
    % list = ["p","q","v","w"]      q : euler angle (roll, pitch, yaw angles)
    % input_channel = ["v","w"]
    methods
        function obj = EulerAngle_Model(args)
            obj= obj@MODEL_CLASS("EulerAngle_Model",args);
            %obj.id = self.id
            % 
            %   �ڍא����������ɋL�q
        end
        
    end
end
