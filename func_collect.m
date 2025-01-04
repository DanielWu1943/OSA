function func_set = func_collect
    func_set.update_task_pool = @update_task_pool;
    func_set.print_log = @print_log;
    func_set.compute_channel_rates = @compute_channel_rates;
end


%% 更新任务池
function task_pool = update_task_pool(t, task_data, task_pool)
    for i = 1:height(task_data.TaskID)
        if t >= task_data.ReleaseTime(i) && ~ismember(i, task_pool)
            task_pool = [task_pool; i];  % 将任务加入到task_pool中
        end
    end
    % 移除训练完成的任务
    % 移除超时任务
    valid_tasks = t < (task_data.ReleaseTime(task_pool) + task_data.Deadline(task_pool)) ...
                  & task_data.Trained_Epochs(task_pool) < task_data.Total_Epochs(task_pool);
    task_pool = task_pool(valid_tasks);  % 筛选出有效任务
    % 找到task_pool中最大的TaskID
    if isempty(task_pool)
        task_pool = [];
    end
end

%% log打印
function print_log(task_data)
    fprintf('当前每个任务的 Trained_Epoch 值为：\n');
    for i = 1:height(task_data.TaskID)
        fprintf('任务 %d: %d epochs\n', i, task_data.Trained_Epochs(i));
    end
end

%% 计算信道速率函数
function r = compute_channel_rates(num_tasks, num_edges, model_type, W, p, sigma)
    h = generate_channel(num_tasks, num_edges, model_type);
    r = compute_transmission_latency(h, num_tasks, num_edges, W, p, sigma);
end

function h = generate_channel(num_tasks, num_servers, model_type, K_factor)
    % 输入：
    % num_tasks     - 任务数量 I
    % num_servers   - 边缘服务器数量 K
    % model_type    - 信道模型类型（'rayleigh' 或 'rician'）
    % K_factor      - Rician 衰落模型中的 K 因子（如果使用 Rician 模型）
    %
    % 输出：
    % h             - 信道状态矩阵（I × K），每个元素表示信道增益 h_{i,k}
    
    % 根据信道模型类型生成信道增益
    switch model_type
        case 'rayleigh'
            % Rayleigh 衰落模型：复高斯随机变量
            h = (randn(num_tasks, num_servers) + 1i * randn(num_tasks, num_servers)) / sqrt(2);
        
        case 'rician'
            % Rician 衰落模型：LoS + Rayleigh 部分
            % 生成 Rayleigh 衰落部分
            rayleigh_part = (randn(num_tasks, num_servers) + 1i * randn(num_tasks, num_servers)) / sqrt(2);
            
            % 生成 LoS 部分
            LoS_part = sqrt(K_factor / (K_factor + 1)) * ones(num_tasks, num_servers);
            
            % 总信道增益（LoS 部分 + Rayleigh 衰落部分）
            h = LoS_part + rayleigh_part;
        
        otherwise
            error('Invalid model type. Use "rayleigh" or "rician".');
    end
    
    % 计算信道增益的幅度（如果需要的话）
    h = abs(h);  % 获取信道增益的幅度
end

function r = compute_transmission_latency(h, num_tasks, num_edges, W, p, sigma)
    % h: 信道增益矩阵，大小为 num_tasks x num_edges
    % num_tasks: 任务数量
    % num_edges: 边缘服务器数量
    % W: 边缘服务器的带宽，大小为 num_edges
    % p: 任务的传输功率，大小为 num_tasks
    % sigma: 噪声功率
    
    % 初始化传输速率矩阵 r，大小为 num_tasks x num_edges
    r = zeros(num_tasks, num_edges);
    sigma = W .* (10^(sigma / 10) / 1000);
    for i = 1:num_tasks
        for k = 1:num_edges
            % 根据公式计算 r_{i,k}
            r(i, k) = W(k) * log2(1 + (h(i, k) * p) / sigma(k));
        end
    end
end

%% 
