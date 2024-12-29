function vehicle_license_plate_gui
    
    fig = uifigure('Name', 'Vehicle License Plate Detection', 'Position', [100, 100, 900, 600], ...
        'Color', [0.9, 0.9, 0.9]);
    
    
    grid = uigridlayout(fig, [3, 4]);
    grid.RowHeight = {'1x', '2x', '1x'};
    grid.ColumnWidth = {'1x', '1x', '1x', '1x'};

    
    lblTitle = uilabel(grid, 'Text', 'Vehicle License Plate Detection', 'FontSize', 20, ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    lblTitle.Layout.Row = 1;
    lblTitle.Layout.Column = [1, 4];
    
    
    btnSelect = uibutton(grid, 'Text', 'Select Image', 'FontSize', 14, 'BackgroundColor', [0.1, 0.5, 0.8], ...
        'FontWeight', 'bold', 'ButtonPushedFcn', @(btn, event) loadImageCallback());
    btnSelect.Layout.Row = 3;
    btnSelect.Layout.Column = 1;

    
    axOriginal = uiaxes(grid);
    axOriginal.Title.String = 'Original Image';
    axOriginal.Layout.Row = 2;
    axOriginal.Layout.Column = 1;

    axGray = uiaxes(grid);
    axGray.Title.String = 'Enhanced Grayscale Image';
    axGray.Layout.Row = 2;
    axGray.Layout.Column = 2;

    axEdges = uiaxes(grid);
    axEdges.Title.String = 'Edge Detection';
    axEdges.Layout.Row = 2;
    axEdges.Layout.Column = 3;

    axResult = uiaxes(grid);
    axResult.Title.String = 'Extracted License Plate';
    axResult.Layout.Row = 2;
    axResult.Layout.Column = 4;
    
    
    lblOutput = uilabel(grid, 'Text', 'Detected Plate: ---', 'FontSize', 14, ...
        'FontWeight', 'bold', 'BackgroundColor', [0.8, 0.9, 1.0], 'HorizontalAlignment', 'center');
    lblOutput.Layout.Row = 3;
    lblOutput.Layout.Column = [2, 4];

    
    function loadImageCallback()
        [filename, pathname] = uigetfile({'.jpg;.png;.jpeg', 'Image Files (.jpg, *.png, *.jpeg)'}, 'Select a Vehicle Image');
        if isequal(filename, 0)
            uialert(fig, 'No file selected. Please choose an image.', 'Warning');
            return;
        end
        imagePath = fullfile(pathname, filename);
        I = imread(imagePath);
        
        
        imshow(I, 'Parent', axOriginal);
        axOriginal.Title.String = 'Original Image';
        
        
        Igray = rgb2gray(I);
        Igray = imadjust(Igray);
        imshow(Igray, 'Parent', axGray);
        axGray.Title.String = 'Enhanced Grayscale Image';
        
       
        Igray = medfilt2(Igray, [3, 3]);
        edges = edge(Igray, 'Canny');
        imshow(edges, 'Parent', axEdges);
        axEdges.Title.String = 'Edge Detection (Canny)';
        
        
        se = strel('rectangle', [5, 17]);
        edgesClosed = imclose(edges, se);
        
        
        stats = regionprops(edgesClosed, 'BoundingBox', 'Area');
        thresholdArea = 200;
        plateDetected = false;
        
        for i = 1:length(stats)
            if stats(i).Area > thresholdArea
                
                bbox = stats(i).BoundingBox;
                ROI = imcrop(Igray, bbox);
                ROI = imresize(ROI, [100, 300]);
                ROI = imbinarize(ROI, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.4);
                ROI = imcomplement(ROI);
                
                % Display Extracted Plate Region
                imshow(ROI, 'Parent', axResult);
                axResult.Title.String = 'Extracted License Plate';
                
                % Perform OCR
                results = ocr(ROI, 'CharacterSet', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
                recognizedText = strtrim(results.Text);
                imgResult = imgProcess(recognizedText);
                % Display OCR Result
                if ~isempty(imgResult)
                    lblOutput.Text = ['Detected Plate: ', imgResult];
                    plateDetected = true;
                    break;
                end
            end
        end
        
        if ~plateDetected
            lblOutput.Text = 'No valid license plate detected.';
            axResult.Title.String = 'No Plate Found';
        end
    end
end