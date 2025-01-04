function d_i_t = calculate_profit_density(task_idx, task_data, task_data_pt, historical_training_time, gamma, t, t_e_i_t)
    % 获取任务的相关参数
    tau_i = task_data.Deadline(task_idx);  % 任务的截止时间
    r_i = task_data.ReleaseTime(task_idx); % 任务的发布时刻
    w_i_j = task_data_pt(task_idx).Profit;  % 任务每个epoch的利润
    e_i = task_data.Trained_Epochs(task_idx);     % 已完成训练周期数
    E_i = task_data.Total_Epochs(task_idx);       % 总训练周期数
    
    % 任务的历史平均训练时间
    avg_training_time_i = historical_training_time;  

    % 计算潜在总训练周期数 N_i(t)
    N_i_t = floor((tau_i + r_i - t) / avg_training_time_i);  % 截止时刻 - 现在的时间 = 剩余时间

    % 初始化潜在利润 p^j_{i,t}（从 epoch j 到 N_i(t)）
    p_i_t = 0;
    if gamma == 0
        p_i_t = p_i_t + w_i_j(e_i);
    elseif gamma == 1
        for j = e_i:min(N_i_t, E_i)
            p_i_t = p_i_t + (gamma * w_i_j(j));  % 折扣利润计算
        end
    else
        for j = e_i:min(N_i_t, E_i)
            p_i_t = p_i_t + (gamma^(j - e_i + 1) * w_i_j(j));  % 折扣利润计算
        end
    end
    % 利用传递的 t_e_i_t 计算利润密度
    d_i_t = p_i_t / t_e_i_t;
end

