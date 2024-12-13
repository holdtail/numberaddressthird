function image_processing_platform()
    % 创建主界面
    fig = uifigure('Name', '图像处理平台', 'Position', [100, 100, 1200, 800]);

    % 状态指示灯（左上角）
    statusLamp = uilamp(fig, 'Position', [10, 750, 20, 20], 'Color', 'red');
    entropyLabel = uilabel(fig, 'Text', '熵值: --', 'Position', [400, 740, 200, 30]);

    % 创建菜单栏
    menu = uimenu(fig, 'Text', '文件');
    uimenu(menu, 'Text', '打开', 'MenuSelectedFcn', @(src, event) openImage());
    uimenu(menu, 'Text', '保存', 'MenuSelectedFcn', @(src, event) saveImage());

    % 创建选项菜单
    optionsMenu = uimenu(fig, 'Text', '选项');
    uimenu(optionsMenu, 'Text', '重做', 'MenuSelectedFcn', @(src, event) resetImage());

    % 图像显示区（原图像、处理后的图像、RGB折线图并排）
    ax1 = axes(fig, 'Position', [0.05, 0.55, 0.25, 0.35]); % 原图像
    title(ax1, '原图像');

    ax2 = axes(fig, 'Position', [0.4, 0.55, 0.25, 0.35]); % 处理后的图像
    title(ax2, '处理后的图像');

    ax3 = axes(fig, 'Position', [0.75, 0.55, 0.25, 0.35]); % RGB折线图
    title(ax3, 'RGB频度');

  % 图像操作按钮区
btnPanel = uipanel(fig, 'Title', '图像处理操作', 'Position', [0.05, 0.05, 0.9, 0.4]);

% RGB调整控制面板
uilabel(btnPanel, 'Text', '红色通道', 'Position', [10, 280, 80, 25]);%10, 280, 80, 25
redSlider = uislider(btnPanel, 'Position', [100, 280, 200, 3], 'Limits', [0, 2], 'Value', 1);%100, 280, 200, 3
redSlider.ValueChangedFcn = @(src, event) adjustRGB();

uilabel(btnPanel, 'Text', '绿色通道', 'Position', [10, 230, 80, 25]);
greenSlider = uislider(btnPanel, 'Position', [100, 230, 200, 3], 'Limits', [0, 2], 'Value', 1);
greenSlider.ValueChangedFcn = @(src, event) adjustRGB();

uilabel(btnPanel, 'Text', '蓝色通道', 'Position', [10, 180, 80, 25]);
blueSlider = uislider(btnPanel, 'Position', [100, 180, 200, 3], 'Limits', [0, 2], 'Value', 1);
blueSlider.ValueChangedFcn = @(src, event) adjustRGB();

uilabel(btnPanel, 'Text', '旋转角度', 'Position', [10, 120, 80, 25]);
rotateAngleEdit = uieditfield(btnPanel, 'numeric', 'Position', [100, 120, 80, 25], 'Value', 0);
rotateAngleEdit.ValueChangedFcn = @(src, event) rotateImage();

% 调用 drawnow 强制更新图形
drawnow;

% 调试输出
disp(btnPanel.Position);
disp(redSlider.Position);
disp(greenSlider.Position);
disp(blueSlider.Position);
disp(rotateAngleEdit.Position);

    % 初始化图像变量
    img = [];
    processedImg = [];

    % 打开图像函数
    function openImage()
        [file, path] = uigetfile({'*.jpg;*.png;*.bmp', '所有图像文件'}, '选择图像');
        if file
            img = imread(fullfile(path, file));
            % 显示原图像
            imshow(img, 'Parent', ax1);
            
            % 手动计算图像的熵值
            grayImg = rgb2grayCustom(img); % 转换为灰度图像
            entropyValue = calculateEntropy(grayImg); % 计算熵值
            entropyLabel.Text = ['熵值: ', num2str(entropyValue)];
            
            % 计算并显示RGB通道的灰度频度图
            plotRGBHistogram(img);
            
            % 更新状态指示灯为绿色表示成功加载
            statusLamp.Color = 'green';
        end
    end

    % 手动实现RGB到灰度图像的转换
    function grayImg = rgb2grayCustom(img)
        % 获取图像的尺寸
        [height, width, ~] = size(img);
        
        % 初始化灰度图像
        grayImg = zeros(height, width);
        
        % 遍历每个像素进行加权平均
        for i = 1:height
            for j = 1:width
                R = img(i, j, 1);
                G = img(i, j, 2);
                B = img(i, j, 3);
                % 使用加权公式进行转换
                grayImg(i, j) = 0.2989 * R + 0.5870 * G + 0.1140 * B;
            end
        end
        
        % 转换为uint8格式
        grayImg = uint8(grayImg);
    end

    % 手动计算图像的熵值
    function entropyValue = calculateEntropy(grayImg)
        % 计算灰度图像的直方图
        [counts, ~] = imhist(grayImg);
        
        % 归一化直方图，得到每个灰度级的概率
        totalPixels = numel(grayImg);
        probabilities = counts / totalPixels;
        
        % 移除概率为零的项
        probabilities = probabilities(probabilities > 0);
        
        % 使用香农熵公式计算熵值
        entropyValue = -sum(probabilities .* log2(probabilities));
    end

    % 绘制RGB通道的灰度频度图
    function plotRGBHistogram(image)
        % 分离RGB通道
        redChannel = image(:,:,1);
        greenChannel = image(:,:,2);
        blueChannel = image(:,:,3);
        
        % 计算每个通道的直方图
        [countsR, binsR] = imhist(redChannel);
        [countsG, binsG] = imhist(greenChannel);
        [countsB, binsB] = imhist(blueChannel);
        
        % 绘制折线图
        hold(ax3, 'off');
        plot(ax3, binsR, countsR, 'r', 'LineWidth', 2); hold(ax3, 'on');
        plot(ax3, binsG, countsG, 'g', 'LineWidth', 2);
        plot(ax3, binsB, countsB, 'b', 'LineWidth', 2);
        xlabel(ax3, '灰度级');
        ylabel(ax3, '像素数');
        legend(ax3, '红色通道', '绿色通道', '蓝色通道');
        hold(ax3, 'off');
    end

    % 保存图像函数
    function saveImage()
        if isempty(processedImg)
            msgbox('请先处理图像', '错误', 'error');
            return;
        end
        [file, path] = uiputfile({'*.jpg;*.png;*.bmp', '图像文件'}, '保存图像');
        if file
            imwrite(processedImg, fullfile(path, file));
            msgbox('图像已保存', '提示', 'help');
        end
    end

    % 重做函数
    function resetImage()
        if isempty(img)
            msgbox('没有加载图像', '错误', 'error');
            return;
        end
        % 恢复到原始图像
        processedImg = img;
        imshow(img, 'Parent', ax2);
        % 更新RGB三通道的灰度频度图
        plotRGBHistogram(img);
        statusLamp.Color = 'yellow'; % 状态指示灯设置为黄色，表示可以操作
    end

    % 调整RGB通道函数
    function adjustRGB()
        if isempty(img)
            return;
        end
        % 获取当前RGB通道的调整比例
        redFactor = redSlider.Value;
        greenFactor = greenSlider.Value;
        blueFactor = blueSlider.Value;
        
        % 调整RGB通道
        adjustedImg = img;
        adjustedImg(:,:,1) = uint8(double(img(:,:,1)) * redFactor);
        adjustedImg(:,:,2) = uint8(double(img(:,:,2)) * greenFactor);
        adjustedImg(:,:,3) = uint8(double(img(:,:,3)) * blueFactor);
        
        % 显示调整后的图像
        processedImg = adjustedImg;
        imshow(adjustedImg, 'Parent', ax2);
        plotRGBHistogram(adjustedImg);  % 更新RGB频度图
    end
 % 旋转图像函数
    function rotateImage()
        if isempty(img)
            return;
        end
        % 获取旋转角度
        angle = rotateAngleEdit.Value;
        
        % 使用imrotate函数旋转图像
        rotatedImg = imrotate(img, angle);
        
        % 显示旋转后的图像
        processedImg = rotatedImg;
        imshow(rotatedImg, 'Parent', ax2);
        plotRGBHistogram(rotatedImg);  % 更新RGB频度图
    end
end


