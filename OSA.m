% main.m - 仿真框架

% 清除环境
clear;
clc;

%% 定义输入参数解析器
params = inputParser;
rng(42);
%{
参数说明：
W: 1 Ghz
T: 800 s
衰落模型：rayleigh
噪声功率：-174dbm/hz  % 标准的 AWGN 噪声功率谱密度（dBm/Hz）
发送功率：0.1w

感觉得把T改成ms级别，这才好21600 * 1000 ms
43200 * 1000如果只有5000个任务的话太少了，平均10000 ms 一个任务

%}
%-------------------------------参数设置-------------------------------
addParameter(params, 'num_edges', 6, @(x) isnumeric(x) && x > 0);  % 边缘服务器数量
addParameter(params, 'gamma', 0.8, @(x) isnumeric(x) && x > 0);  % 衰减系数
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

%{
有些参数的索引是要用task_id的，例如B、E等从task_data里面取的，他们的大小就是task_data * x
其他参数则是随着task_num变化的，所以索引要用i，例如

%}


%% 调度算法主函数
function schedule_tasks(task_data, task_data_pt, T, num_edges, model_type, W, sigma, gamma, B, o, p)
    
%% ----------------------画图参数设置----------------------
    profits = [];  % 用于保存每个时间点的profit
    times = [];    % 用于保存每个时间点的t
    func = func_collect;%函数库实例化

%% 启动
    % 初始化任务池和历史平均训练时间
    task_pool = [];
    total_task_num = height(task_data.TaskID);
    historical_training_time = zeros(1, total_task_num);  % 历史平均训练时间
    profit_gain = 0;
    % 调度仿真
    t = 1;
    K = T / 1000;
    while t <= T
        %fprintf('Time %d:\n', t);
        
        % 判断任务是否满足 t > r_i，满足条件的加入 task_pool
        task_pool = func.update_task_pool(t, task_data, task_pool);
        
        % 如果task_pool为空，跳过后续的计算直到下一个任务发布
        if isempty(task_pool)
            future_release_times = task_data.ReleaseTime(task_data.ReleaseTime > t);
            if ~isempty(future_release_times)
                t = future_release_times(1);  % 更新t
            end
            continue;
        end
        num_tasks = length(task_pool);

        % 计算速率r
        r = func.compute_channel_rates(num_tasks, num_edges, model_type, W, p, sigma);
        %fprintf('传输速率计算完成\n');
        
        % 为每个任务计算最优分配和利润密度
        d_i_t_list = zeros(1, num_tasks);  % 存储每个任务的效用密度
        t_opt_list = zeros(1, num_tasks);  % 存储每个任务的训练时间
        % 初始化利润密度列表
        % 为每个任务计算最优分配并计算利润密度
        for i = 1:num_tasks
            task_idx = task_pool(i);  % 获取当前任务的索引
            t_tr = task_data_pt(task_idx).Train_Time;
            training_epoch = task_data.Trained_Epochs(task_idx);
            
            % 计算最优分配
            [~, t_opt] = branch_and_bound(num_edges, B(task_idx), t_tr(training_epoch,:), r(i, :), o(task_idx));
            t_opt_list(i) = t_opt;
            if task_data.Trained_Epochs(task_idx) == 1
                historical_training_time(task_idx) = t_opt_list(i);
            end
            % 利用 t_opt 计算利润密度
            d_i_t_list(i) = calculate_profit_density(task_idx, task_data, task_data_pt, historical_training_time(task_idx), gamma, t, t_opt);
        end
        


        % 选择利润密度最大的任务
        [~, selected_idx] = max(d_i_t_list);
        selected_task = task_pool(selected_idx);  % 获取任务编号
        %fprintf('任务 %d 的效用密度最大\n', selected_task);

        % 更新数据
        % 历史平均训练时间
        epochs_trained = task_data.Trained_Epochs(selected_task);
        historical_training_time(selected_task) = (historical_training_time(selected_task) * epochs_trained + t_opt_list(selected_idx)) / (1 + epochs_trained);
        % epoch
        task_data.Trained_Epochs(selected_task) = epochs_trained + 1;

        profit_array = task_data_pt(selected_task).Profit;  % 将字符串转换为数值数组
        profit_value = profit_array(epochs_trained + 1);  % 获取对应的值

        profit_gain = profit_gain + profit_value;

        %fprintf('任务%d的已训练epoch+1， 目前训练了：%d\n', selected_task, task_data.Trained_Epochs(selected_task));
        
        profits = [profits, profit_gain];
        times = [times, t];
        
        %fprintf('\n');
        t = round(t + t_opt_list(selected_idx));%更新时间
        % 每经过一定次数的任务更新一次进度条
        if t > K
            fprintf('\r仿真进度：(%.2f%%)', (K / T) * 100);
            K = K + T / 1000;
        end
    end
    
    fprintf('仿真结束，时间%d内获得的总profit为%.4f\n', T, profit_gain);
    %% 保存结果到.mat文件
    file_name = sprintf('Ours_results_gamma_%.2f_edges_%d_1000.mat', gamma, num_edges);
    save(file_name, 'times', 'profits');
    %func.print_log(task_data);
end






