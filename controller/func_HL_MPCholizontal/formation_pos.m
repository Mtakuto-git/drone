function arranged_pos = formation_pos(base_pos,N,gap,z)
    % arranged_position(base_pos,N,gap,z)
    % base_pos �����gap �Ԋu�Ő��񂵂������l�𐶐�
    % ������z�ň��
    for i=1:N
        arranged_pos(i,:)=[base_pos(1)+gap*(N-1)-gap*(i-1),base_pos(2)] ;
    end
    arranged_pos= [arranged_pos';z*ones(1,size(arranged_pos,1))];
end

