% generate_dataset.m - 数据集生成脚本 


%{
每个样本的大小（TF16）：
CIFAR-10/100：6 KB
ImageNet：300 KB
MNIST：1.5 KB

收集21种任务


%}


%%
% 设置随机种子以确保结果可复现
clc;
clear all;
rng(42);
% 文件夹路径
folder_path = './dataset';  % 替换为你自己的文件夹路径

% 获取文件夹中的所有 MAT 文件
mat_files = dir(fullfile(folder_path, '*.mat'));

% 设置任务数量
num_tasks = 1000;
% 生成任务属性

%% 读取数据集生成数据
E_i = randi([100, 800], 1, num_tasks); % 随机生成 epoch 数量，范围 50 到 100
r_i = randi([1, 43200 * 1000], 1, num_tasks); % 随机生成任务生成时间，范围43200 * 1000 ms
e_i = ones(1, num_tasks); % 生成每个样本的已训练epoch数，初始为0
tau_i = []; % 随机生成截止时间，范围 100 到 500 s

B_i = [];
o_i = [];
t_tr = cell(1, num_tasks);
w_i = cell(1, num_tasks);

for i = 1:num_tasks
    % 随机选择一个 MAT 文件
    random_index = randi(length(mat_files));  % 生成一个随机索引
    random_file = mat_files(random_index).name;  % 获取随机选择的文件名
    disp(random_file)
    % 加载选中的 MAT 文件
    loaded_data = load(fullfile(folder_path, random_file));
    
    % 获取结构体的字段名
    struct_fields = fieldnames(loaded_data);  % 获取结构体的字段名
    Epoch = loaded_data.(struct_fields{1}).Epoch;
    if E_i(i) > length(Epoch)
        E_i(i) = length(Epoch);
    end
    %disp(struct_fields)
    % 使用正则表达式提取文件名中的 Batch size 数值（假设格式为 model_dataset_Batch size）
    batch_size_str = regexp(random_file, 'B(\d+)', 'tokens');  % 匹配文件名中的数字
    %disp(batch_size_str)
    if ~isempty(batch_size_str)
        B_i = [B_i, str2double(batch_size_str{1}{1})];  % 将提取到的字符串转换为数值
    else
        error('No Batch size found in file name');
    end
    %disp(B_i)
        % 根据文件名设置数据集并调整 o_i
    if contains(random_file, 'MNIST')
        dataset = 'MNIST';
        o_i = [o_i, 6272];  % 对于 MNIST数据集一个样本大小是28 * 28 * 8 = 6272 bits
    elseif contains(random_file, 'cifar100')
        dataset = 'cifar100';
        o_i = [o_i, 32*32*3*8];  % 对于 cifar100，设置 o_i 为 32x32x3x8 = 24576 bits
    else
        dataset = 'imagenet';
        o_i = [o_i, 224*224*3*8];  % 对于 cifar100，设置 o_i 为 224*224*3*8 bits
    end
    disp(['Data set: ', dataset]);
    
    training_time_PC1 = loaded_data.(struct_fields{1}).training_time_PC1;  % 获取training_time
    training_time_PC2 = loaded_data.(struct_fields{1}).training_time_PC2;  % 获取training_time
    % 随机选择 a 和 b 的一个值
    Accuracy = loaded_data.(struct_fields{1}).Accuracy;
    t_tr{i} = [training_time_PC1(1:min(E_i(i), length(Accuracy))), training_time_PC2(1:min(E_i(i), length(Accuracy)))];
    w_i{i} = Accuracy(1:min(E_i(i), length(Accuracy)));
    tau_i = [tau_i; round(mean(mean(t_tr{i}))) * 1.2 * E_i(i)];
end
tau_i = tau_i';
% 将任务按 r_i（生成时间）从小到大排序
[~, sort_idx] = sort(r_i); % 按 r_i 排序获取索引
B_i = B_i(sort_idx);
E_i = E_i(sort_idx);
e_i = e_i(sort_idx);
tau_i = tau_i(sort_idx);
r_i = r_i(sort_idx);
o_i = o_i(sort_idx);
w_i = w_i(sort_idx);  % 排序后的利润矩阵
t_tr = t_tr(sort_idx);

% 保存为 .mat 文件
task_data = struct('TaskID', (1:num_tasks)', ...
                   'BatchSize', B_i', ...
                   'Total_Epochs', E_i', ...
                   'Trained_Epochs', e_i', ...
                   'Deadline', tau_i', ...
                   'ReleaseTime', r_i', ...
                   'SampleBits', o_i');

task_data_pt = struct('Profit', w_i', ...
                   'Train_Time', t_tr');

save('tasks_dataset.mat', 'task_data');  % 保存为 MAT 文件
save('tasks_dataset_pt.mat', 'task_data_pt');  % 保存为 MAT 文件
fprintf('任务数据已保存到文件：tasks_dataset.mat\n');





