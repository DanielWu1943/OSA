function [b_opt, z_opt] = branch_and_bound(num_edges, B, t_tr, r_i, o_i)
    % 输入：
    %   num_edges: 边缘服务器数量
    %   B: 任务的总批量大小
    %   t_tr: 各边缘服务器的训练时间向量 [1 x num_edges]
    %   r: 各边缘服务器的传输速率向量 [1 x num_edges]
    %   o: 每个任务的样本位数
    %
    % 输出：
    %   b_opt: 每个边缘服务器的最佳 mini-batch 分配 [1 x num_edges]
    %   z_opt: 最小化的最大完成时间

    % 决策变量数量：b_{i,k} 和 z
    num_variables = num_edges + 1;  % 包括 b_{i,k} 和 z

    % 目标函数：最小化 z
    f = zeros(1, num_variables);
    f(end) = 1;  % 最小化 z

    % 不等式约束 (A * x <= b)
    A = zeros(num_edges, num_variables);
    b = zeros(num_edges, 1);
    t_tr = repmat(t_tr, 1, ceil(num_edges / length(t_tr)));
    t_tr = t_tr(1:num_edges);  % 截断到 num_edges 长度
    
    % 提前计算频繁用到的值
    coeff_tr = t_tr / B;                % 每个边缘服务器的训练时间系数
    coeff_comm = (o_i ./ r_i) * 1000;   % 每个边缘服务器的通信时间系数

    for k = 1:num_edges
        % 约束：b_k / B * t_tr(k) + b_k * o / r(k) <= z
        A(k, k) = coeff_tr(k) +  coeff_comm(k);  % (o_i / r_i(k))单位是秒，需要 * 1000
        A(k, end) = -1;  % 系数对应 z
    end

    % 等式约束 (Aeq * x = beq)
    Aeq = [ones(1, num_edges), 0];
    beq = B;  % 等于总批量大小 B

    % 变量范围：b_k >= 0, z >= 0
    lb = zeros(num_variables, 1);
    ub = inf(num_variables, 1);

    % 整数约束：b_k 必须是整数
    intcon = 1:num_edges + 1;

    % 调用整数线性规划求解
    options = optimoptions('intlinprog', 'Display', 'off', 'CutGeneration', 'basic');
    %options = optimoptions('intlinprog', 'Display', 'none');
    [x, ~, exitflag] = intlinprog(f, intcon, A, b, Aeq, beq, lb, ub, options);

    if exitflag ~= 1
        error('线性规划问题未能求解');
    end

    % 提取结果
    b_opt = x(1:num_edges);  % mini-batch 分配
    z_opt = x(end);          % 最小化的最大完成时间
    z_opt = max(z_opt, 1);
end

