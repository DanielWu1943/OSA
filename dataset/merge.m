clc;
clear all;

% 获取当前文件夹路径
folder_path = pwd;  % 或者指定你的文件夹路径

% 获取所有的 .txt 文件
txt_files = dir(fullfile(folder_path, '*.txt'));

% 获取所有文件的名称
file_names = {txt_files.name};

% 打印获取的文件列表
disp('Found the following TXT files:');
disp(file_names);

% 遍历每一对文件
for i = 1:2:length(file_names)
    % 获取当前组的PC1和PC2文件
    file1 = file_names{i};    % _PC1.txt
    file2 = file_names{i+1};  % _PC2.txt
    
    % 打印正在处理的文件名
    disp(['Processing files: ', file1, ' and ', file2]);
    
    % 确保每组文件都配对
    if contains(file1, 'PC1') && contains(file2, 'PC2')
        try
            % 读取两个文件
            data1 = readtable(file1, 'Delimiter', '\t');  % 读取第一个文件
            data2 = readtable(file2, 'Delimiter', '\t');  % 读取第二个文件
            
            % 打印读取数据的列名和维度
            disp(['Columns in ', file1, ':']);
            disp(data1.Properties.VariableNames);
            disp(['Columns in ', file2, ':']);
            disp(data2.Properties.VariableNames);

            % 提取 Step, Accuracy, Time_s 列
            step = data1.Step;
            accuracy = data1.Accuracy;
            accuracy = [accuracy(1); diff(accuracy)];
            time_s1 = data1.Time;  % 第一个文件的 Time_s
            time_s2 = data2.Time;  % 第二个文件的 Time_s
            
            % 打印提取的数据的大小
            disp(['Data size for ', file1, ': ', num2str(size(data1))]);
            disp(['Data size for ', file2, ': ', num2str(size(data2))]);

            % 创建结构体并保存数据
            struct_name = erase(file1, '.txt');  % 使用文件名去除.txt后缀作为结构体名
            DATA = struct();
            DATA.Epoch = step;
            DATA.Accuracy = accuracy;
            %保存成ms然后取整
            DATA.training_time_PC1 = round(time_s1 * 1000);
            DATA.training_time_PC2 = round(time_s2 * 1000);

            % 获取文件名的基础部分（去掉 _PC1 和 _PC2 后缀）
            base_name = erase(file1, '_PC1.txt');  % 去掉 _PC1 后缀
            base_name = erase(base_name, '_PC2.txt');  % 去掉 _PC2 后缀，确保一致性
            
            % 生成保存的 MAT 文件名
            mat_file_name = fullfile(folder_path, [base_name, '.mat']);  % 保存为 .mat 文件
            
            % 保存为 MAT 文件
            save(mat_file_name, 'DATA');
            disp(['Saved: ', mat_file_name]);

        catch ME
            % 如果出现错误，打印错误信息
            disp(['Error processing files: ', file1, ' and ', file2]);
            disp(ME.message);
        end
    else
        disp(['Skipping pair: ', file1, ' and ', file2, ' (Not matching PC1 and PC2)']);
    end
end

