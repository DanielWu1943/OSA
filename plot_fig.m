clc;
clear;
%% 12小时的图
figure;
hold on; % 保持绘图，多个图形在同一坐标轴

% 加载两个.mat文件中的数据
ours = load('Ours_results_gamma_0.95_edges_6.mat'); % 假设file1包含变量 t1 和 profit1
ASRS = load('baseline_ASRS_results_gamma_0.95_edges_6.mat'); % 假设file2包含变量 t2 和 profit2
OSRS = load('baseline_OSRS_results_gamma_0.95_edges_6.mat'); % 假设file2包含变量 t2 和 profit2
OSFS = load('baseline_OSFS_results_gamma_0.95_edges_6.mat'); % 假设file2包含变量 t2 和 profit2

% 获取时间 t 和利润 profit 数据
ours_t = ours.times / (1000 * 3600); % 将时间从ms转换为小时
ours = ours.profits;

ASRS_t = ASRS.times / (1000 * 3600);
ASRS = ASRS.profits;

OSRS_t = OSRS.times / (1000 * 3600);
OSRS = OSRS.profits;

OSFS_t = OSFS.times / (1000 * 3600);
OSFS = OSFS.profits;

% 绘制第一个数据集
plot(ours_t, ours, 'r--', 'LineWidth', 2, 'DisplayName', 'Ours');

% 绘制第二个数据集
plot(ASRS_t, ASRS, 'b--', 'LineWidth', 2, 'DisplayName', 'ASRS');

plot(OSRS_t, OSRS, 'g--', 'LineWidth', 2, 'DisplayName', 'OSRS');

plot(OSFS_t, OSFS, 'm--', 'LineWidth', 2, 'DisplayName', 'OSFS');

% 添加图形标题和标签
xlabel('T (h)', 'FontSize', 14);
ylabel('Profit', 'FontSize', 14);
% 添加图例并启用 LaTeX 解释器
legend('show', 'Interpreter', 'latex', 'FontSize', 14, 'Location', 'northwest');

% 设置x轴刻度为每小时
xticks(0:max(ours_t + 1)); % 设置x轴刻度为0到最大时间的整数小时
xtickformat('%.0f'); % 保证x轴刻度显示为整数

% 设置x轴和y轴刻度字体大小
set(gca, 'FontSize', 14);

% 显示网格
grid on;

hold off; % 释放绘图

% 保存为 PNG 文件
saveas(gcf, 'fig_p_t.pdf');

fprintf('图片1（profit vs time）绘制完成\n');


%% figure of K
%{
figure;

% 定义存放.mat文件的目录
folder_path = './plot_data_K'; % 替换为你的.mat文件所在文件夹路径
files = dir(fullfile(folder_path, '*.mat')); % 获取文件夹中所有.mat文件

% 初始化存储数据
Ks = [6, 12, 18]; % 假设 K 的取值是已知的 6、12 和 18
algorithms = {'Ours', 'ASRS', 'OSRS', 'OSFS'}; % 定义算法名称
profits_data = zeros(length(Ks), length(algorithms)); % 存储 profits 值

% 遍历每个文件
for i = 1:length(files)
    % 获取文件的完整路径
    file_path = fullfile(folder_path, files(i).name);
    
    % 加载.mat文件
    data = load(file_path);
    
    % 提取 K 值和算法名称
    file_name = files(i).name;
    match = regexp(file_name, '_(\d+)_edges_\d+\.mat', 'tokens'); % 假设文件名中包含 K 的值
    if isempty(match)
        fprintf('文件名未包含有效的 K 值信息: %s\n', file_name);
        continue;
    end
    K_value = str2double(match{1}{1}); % 提取 K 值
    algorithm_idx = find(contains(algorithms, extractBefore(file_name, '_results'))); % 提取算法索引
    
    % 检查数据有效性
    if ~isfield(data, 'profits') || isempty(algorithm_idx)
        fprintf('文件 %s 数据无效，跳过处理。\n', file_name);
        continue;
    end
    
    % 获取 profits 的最后一个值
    last_profit = data.profits(end);
    
    % 存储到对应的位置
    K_idx = find(Ks == K_value);
    profits_data(K_idx, algorithm_idx) = last_profit;
    fprintf('K=%d, Algorithm=%s, Profits=%.4f\n', K_value, algorithms{algorithm_idx}, last_profit);
end

% 检查数据是否已成功填充
if ~any(profits_data(:))
    error('未加载任何有效的 profits 数据！');
end

% 绘制柱状图
bar_width = 0.8; % 柱子宽度
bar_handles = bar(profits_data, bar_width, 'grouped'); % 绘制分组柱状图

% 设置颜色
colors = lines(length(algorithms)); % 自动生成颜色
for i = 1:length(algorithms)
    bar_handles(i).FaceColor = colors(i, :);
end

% 设置 X 轴和图例
set(gca, 'XTickLabel', arrayfun(@(x) sprintf('K=%d', x), Ks, 'UniformOutput', false), ...
         'XTick', 1:length(Ks));
xlabel('K Value');
ylabel('Profit');
title('Bar Chart of Profits for Different Algorithms and K Values');
legend(algorithms, 'Location', 'NorthWest');

% 保存为 PDF 文件
saveas(gcf, 'fig_K.pdf');
%}



%% figure of gamma
figure;
hold on; % 保持绘图，多个图形在同一坐标轴

% 加载两个.mat文件中的数据
gamma_00 = load('./plot_gamma/Ours_results_gamma_0.00_edges_6_1000.mat');
gamma_05 = load('./plot_gamma/Ours_results_gamma_0.50_edges_6_1000.mat');
gamma_70 = load('./plot_gamma/Ours_results_gamma_0.70_edges_6_1000.mat');
gamma_75 = load('./plot_gamma/Ours_results_gamma_0.75_edges_6_1000.mat');
gamma_80 = load('./plot_gamma/Ours_results_gamma_0.80_edges_6_1000.mat');
gamma_09 = load('./plot_gamma/Ours_results_gamma_0.90_edges_6_1000.mat');
gamma_95 = load('./plot_gamma/Ours_results_gamma_0.95_edges_6_1000.mat');
gamma_99 = load('./plot_gamma/Ours_results_gamma_0.99_edges_6_1000.mat');
gamma_10 = load('./plot_gamma/Ours_results_gamma_1.00_edges_6_1000.mat');
% 获取时间 t 和利润 profit 数据
gamma_00_t = gamma_00.times / (1000 * 3600); % 将时间从ms转换为小时
gamma_00 = gamma_00.profits;

gamma_05_t = gamma_05.times / (1000 * 3600); % 将时间从ms转换为小时
gamma_05 = gamma_05.profits;

gamma_70_t = gamma_70.times / (1000 * 3600);
gamma_70 = gamma_70.profits;

gamma_75_t = gamma_75.times / (1000 * 3600);
gamma_75 = gamma_75.profits;

gamma_80_t = gamma_80.times / (1000 * 3600);
gamma_80 = gamma_80.profits;

gamma_09_t = gamma_09.times / (1000 * 3600);
gamma_09 = gamma_09.profits;

gamma_95_t = gamma_95.times / (1000 * 3600);
gamma_95 = gamma_95.profits;

gamma_99_t = gamma_99.times / (1000 * 3600);
gamma_99 = gamma_99.profits;

gamma_10_t = gamma_10.times / (1000 * 3600);
gamma_10 = gamma_10.profits;

% 绘制第一个数据集（浅蓝色）
plot(gamma_00_t, gamma_00, '--', 'LineWidth', 2, 'Color', [0.2 0.4 0.8], 'DisplayName', '$\gamma = 0.00$');

plot(gamma_05_t, gamma_05, '--', 'LineWidth', 2, 'Color', [0.1 0.5 0.9], 'DisplayName', '$\gamma = 0.50$');

% 绘制第二个数据集（橙色系）
plot(gamma_70_t, gamma_70, '--', 'LineWidth', 2, 'Color', [0.9 0.4 0.1], 'DisplayName', '$\gamma = 0.70$');

plot(gamma_75_t, gamma_75, '--', 'LineWidth', 2, 'Color', [0.9 0.5 0.3], 'DisplayName', '$\gamma = 0.75$');

plot(gamma_80_t, gamma_80, '--', 'LineWidth', 2, 'Color', [1.0 0.6 0.2], 'DisplayName', '$\gamma = 0.80$');

% 绘制第三个数据集（绿色系）
plot(gamma_09_t, gamma_09, '--', 'LineWidth', 2, 'Color', [0.2 0.7 0.2], 'DisplayName', '$\gamma = 0.90$');

% 绘制第四个数据集（紫色系）
plot(gamma_95_t, gamma_95, '--', 'LineWidth', 2, 'Color', [0.6 0.2 0.7], 'DisplayName', '$\gamma = 0.95$');

plot(gamma_99_t, gamma_99, '--', 'LineWidth', 2, 'Color', [0.4 0.3 0.7], 'DisplayName', '$\gamma = 0.99$');

plot(gamma_10_t, gamma_10, '--', 'LineWidth', 2, 'Color', [0.3 0.3 0.5], 'DisplayName', '$\gamma = 1.00$');

% 添加图形标题和标签
xlabel('T (h)', 'FontSize', 14);
ylabel('Profit', 'FontSize', 14);
% 添加图例并启用 LaTeX 解释器
legend('show', 'Interpreter', 'latex', 'FontSize', 12, 'Location', 'northwest');

% 设置x轴刻度为每小时
xticks(0:max(gamma_05_t + 1)); % 设置x轴刻度为0到最大时间的整数小时
xtickformat('%.0f'); % 保证x轴刻度显示为整数

% 设置x轴和y轴刻度字体大小
set(gca, 'FontSize', 14);

% 添加图例
legend('show');

% 显示网格
grid on;

hold off; % 释放绘图

% 保存为 PNG 文件
saveas(gcf, 'fig_gamma.pdf');

fprintf('图片3（gamma）绘制完成\n');



%% figure of task release rate ---- epoch

% 数据定义
task_release_rate = [1000, 2000, 3000, 4000, 5000]; % Task release rate

ours_profit = [5699, 5840, 6028, 4941, 4503];
ASRS_profit = [1873, 2031, 2706, 1799, 1888];
OSFS_profit = [2547, 2438, 3234, 2243, 2527];
OSRS_profit = [3201, 3301, 3976, 3080, 3175];

% 将数据组合成矩阵
profits_matrix = [ours_profit; ASRS_profit; OSFS_profit; OSRS_profit];

% 创建柱状图
figure;
bar(task_release_rate, profits_matrix', 'grouped');

% 设置柱状图颜色
colormap([0.2 0.6 1; 1 0.6 0.2; 0.2 0.8 0.4; 0.6 0.4 0.8]); % 自定义颜色

% 添加图形标题和标签
xlabel('Task Release Rate', 'FontSize', 14);
ylabel('Epoch', 'FontSize', 14);

% 设置图例
legend({'Ours', 'ASRS', 'OSFS', 'OSRS'}, 'FontSize', 12, 'Location', 'northwest');

% 设置 x 轴刻度
xticks(task_release_rate);
xtickformat('%.0f'); % 确保 x 轴显示为整数

% 设置轴和网格样式
set(gca, 'FontSize', 14);
grid on;

% 保存为 PDF 文件
saveas(gcf, 'fig_taskrelease_epoch.pdf');

fprintf('柱状图已成功绘制并保存为 fig_taskrelease_epoch.pdf\n');



%% figure of task release rate ---- profit

% 数据定义
task_release_rate = [1000, 2000, 3000, 4000, 5000]; % Task release rate
ours_profit = [204.9855, 302.8993, 325.2408, 365.8273, 366.9059];
ASRS_profit = [112.2475, 120.0360, 135.1590, 141.2604, 153.2729];
OSFS_profit = [29.3513, 43.3184, 62.1919, 66.8461, 75.5862];
OSRS_profit = [148.3985, 200.5776, 232.1197, 249.6164, 264.1275];

% 将数据组合成矩阵
profits_matrix = [ours_profit; ASRS_profit; OSFS_profit; OSRS_profit];

% 创建柱状图
figure;
bar(task_release_rate, profits_matrix', 'grouped');

% 设置柱状图颜色
colormap([0.2 0.6 1; 1 0.6 0.2; 0.2 0.8 0.4; 0.6 0.4 0.8]); % 自定义颜色

% 添加图形标题和标签
xlabel('Task Release Rate', 'FontSize', 14);
ylabel('Profit', 'FontSize', 14);

% 设置图例
legend({'Ours', 'ASRS', 'OSFS', 'OSRS'}, 'FontSize', 12);

% 设置 x 轴刻度
xticks(task_release_rate);
xtickformat('%.0f'); % 确保 x 轴显示为整数

% 设置轴和网格样式
set(gca, 'FontSize', 14);
grid on;

% 保存为 PDF 文件
saveas(gcf, 'fig_taskrelease.pdf');

fprintf('柱状图已成功绘制并保存为 fig_taskrelease.pdf\n');

