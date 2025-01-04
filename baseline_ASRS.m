%% baseline of average splitting and random scheduling

% 清除环境
clear;
clc;

%% 定义输入参数解析器
params = inputParser;
rng(42);

%-------------------------------参数设置-------------------------------
addParameter(params, 'num_edges', 6, @(x) isnumeric(x) && x > 0);  % 边缘服务器数量
addParameter(params, 'gamma', 0.95, @(x) isnumeric(x) && x > 0);  % 衰减系数
addParameter(params, 'T', 43200 * 1000, @(x) isnumeric(x) && x > 0);  % 时间周期数，1/4天 = 6 * 60 * 60 s
addParameter(params, 'model_type', 'rayleigh', @(x) ischar(x) || isstring(x));  % 衰落模型
addParameter(params, 'task_data_file', 'tasks_dataset.mat', @(x) ischar(x) || isstring(x));  % 数据文件路径
addParameter(params, 'task_data_file_pt', 'tasks_dataset_pt.mat', @(x) ischar(x) || isstring(x));  % 数据文件路径
% 解析输入参数
parse(params);

% 获取参数值
num_edges = params.Results.num_edges;
gamma = params.Results.gamma;
T = params.Results.T;
model_type = params.Results.model_type;
task_data_file = params.Results.task_data_file;  % 获取数据文件路径
task_data_file_pt = params.Results.task_data_file_pt;  % 获取数据文件路径
fprintf('参数读取完成\n');


W = repmat(1e9, 1, num_edges);   % 边缘服务器带宽，都固定为1Gbps
sigma = -174;  % 噪声功率，单位：W
p = 0.1;  % 任务传输功率，单位：W

% -------------------------------读取数据集-------------------------------
if ~isfile(task_data_file)
    error('任务数据文件不存在：%s', task_data_file);
end

% 加载 MAT 文件
loaded_data = load(task_data_file);
loaded_data_pt = load(task_data_file_pt);

% 假设数据存储在名为 `task_data` 的结构中
if isfield(loaded_data, 'task_data')
    task_data = loaded_data.task_data; % 提取结构体
    task_data_pt = loaded_data_pt.task_data_pt;
else
    error('MAT 文件中未找到变量 "task_data"');
end



% 从任务数据中提取任务的 B, o, deadline
Task_ID = task_data.TaskID;
B = task_data.BatchSize;  % 任务的batch大小
E = task_data.Total_Epochs;        % 任务总需训练周期数
e_i = task_data.Trained_Epochs;        % 任务的已训练周期数
tau = task_data.Deadline;    % 任务的截止时间
r_i = task_data.ReleaseTime;  % 任务的发布时刻
o = task_data.SampleBits;  % 任务的样本位数
% 初始化任务池
task_pool = [];  % 空矩阵，用于存储符合条件的任务

% 调用调度算法
schedule_tasks(task_data, task_data_pt, T, num_edges, model_type, W, sigma, gamma, B, o, p);




%% 调度算法主函数
function schedule_tasks(task_data, task_data_pt, T, num_edges, model_type, W, sigma, gamma, B, o, p)
    
%% ----------------------画图参数设置----------------------
    profits = [];  % 用于保存每个时间点的profit
    times = [];    % 用于保存每个时间点的t
    func = func_collect;%函数库实例化

%% 启动
    % 初始化任务池和历史平均训练时间
    task_pool = [];
    profit_gain = 0;
    % 调度仿真
    t = 1;
    K = T / 100;
    while t <= T
        %fprintf('Time %d:\n', t);
        
        % 判断任务是否满足 t > r_i，满足条件的加入 task_pool
        task_pool = func.update_task_pool(t, task_data, task_pool);
        
        % 如果task_pool为空，跳过后续的计算
        if isempty(task_pool)
            future_release_times = task_data.ReleaseTime(task_data.ReleaseTime > t);
            if ~isempty(future_release_times)
                t = future_release_times(1);  % 更新t
            end
            continue;
        end

        % 更新任务数量为task_pool中的任务数量
        num_tasks = length(task_pool);

        % 计算速率r
        r = func.compute_channel_rates(num_tasks, num_edges, model_type, W, p, sigma);
        
        %% 随机选择任务random scheduling
        selected_idx = randi(num_tasks);  % 随机选择一个未超时的任务索引
        selected_task = task_pool(selected_idx);  % 获取任务编号
        training_epoch = task_data.Trained_Epochs(selected_task);
        % 更新数据
        t_tr = task_data_pt(selected_task).Train_Time;
        t_opt = average_splitting(num_edges, B(selected_task), t_tr(training_epoch,:), r(selected_idx, :), o(selected_task));
        epochs_trained = task_data.Trained_Epochs(selected_task);
        % epoch
        task_data.Trained_Epochs(selected_task) = epochs_trained + 1;

        profit_gain = profit_gain + task_data_pt(selected_task).Profit(epochs_trained);

        %fprintf('任务%d的已训练epoch+1， 目前训练到：%d\n', selected_task, task_data.Trained_Epochs(selected_task));
        
        profits = [profits, profit_gain];
        times = [times, t];
        
        t = round(t + t_opt);%更新时间
        if t > K
            fprintf('\r仿真进度：(%.2f%%)', (K / T) * 100);
            K = K + T / 100;
        end

    end
    fprintf('仿真结束，时间%d内获得的总profit为%.4f\n', T, profit_gain);
    %% 保存结果到.mat文件
    file_name = sprintf('./plot_taskrelease/baseline_ASRS_results_gamma_%.2f_edges_%d_1000.mat', gamma, num_edges);
    save(file_name, 'times', 'profits');
    %func.print_log(task_data);
end



function t = average_splitting(num_edges, B, t_tr, r, o)
    average_b = floor(B / num_edges);  % 每个服务器分配的mini Batch，取整
    % 计算剩余的mini batch，以确保与总Batch
    remaining_batch = B - average_b * num_edges;
    
    % 调整最后一个服务器的带宽，确保总带宽为 B(selected_task)
    b_i = average_b + remaining_batch;
    d_i = [repmat(average_b, 1, num_edges-1), b_i];
    t = 0;
    for k = 1:num_edges
        k_ = mod(k-1, 2) + 1;
        t_ul = o *  d_i(k) / r(k) * 1000;
        t_mtr = t_tr(k_) * d_i(k) ./ B;
        t = max(t, t_ul + t_mtr);
    end
end
