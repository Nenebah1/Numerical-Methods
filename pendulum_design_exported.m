classdef pendulum_design_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure        matlab.ui.Figure
        SAVEFILEButton  matlab.ui.control.Button
        LOADFILEButton  matlab.ui.control.Button
        LEDLamp         matlab.ui.control.Lamp
        LEDLampLabel    matlab.ui.control.Label
        RESETButton     matlab.ui.control.Button
        UITable         matlab.ui.control.Table
        STARTButton     matlab.ui.control.Button
        UIAxes          matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: RESETButton
        function RESETButtonPushed(app, event)
            % Global variable for the arduino object
            global ar;
            %Global variable for the green LED when we are getting good
            %data
            global led_green;
            % Global variable for the red LED when we get bad data
            global led_red;
            %Initialize LED green to off
            ar.writeDigitalPin(led_green,0);
            %Initialize LED red to off
            ar.writeDigitalPin(led_red,0);
            %Initialize GUI lamp to off
            app.LEDLamp.Color = 'white';
            %Initialize the plot
            plot(app.UIAxes,0,0)
            %Initialize table to empty table
            app.UITable.Data = {};
        end

        % Button pushed function: STARTButton
        function STARTButtonPushed(app, event)
            clc
            %Port of arduino on my laptop
            port = 'COM5';
            %Board used for experiment
            board = 'Uno';
            %Trigger pin of sensor
            trigger_pin= 'D7';
            %Echo pin of sesnsor
            echo_pin = 'D6';
            global led_green;
            global led_red;
            %Pin for Green LED
            led_green = 'D8';
            %Pin for Red LED
            led_red = 'D9';
            global ar;
            % Number of samples
            time_to_run = 2^7;
            %Initialize arduino object
            ar = arduino(port,board,'Libraries','Ultrasonic')
            %Creating ultra sonic object
            ultra_sonic = ultrasonic(ar, trigger_pin,echo_pin)
            %Creating a vector to keep track of measured distances
            array_distance= zeros(1,time_to_run);
            %Initialize Green LED to Off
            ar.writeDigitalPin(led_green,0);
            %Initialize Red LED to off
            ar.writeDigitalPin(led_red,0);
            %Beginning of timer
            tic
            for k=1:time_to_run
                array_distance(k) = readDistance(ultra_sonic);
                %sdeviation = std(array_distance);
                %average = mean(array_distance);
                if (isinf(array_distance(k)) || isnan(array_distance(k)))
                    ar.writeDigitalPin(led_red,1);
                    app.LEDLamp.Color = 'red';
                    ar.writeDigitalPin(led_green,0);
                else
                    ar.writeDigitalPin(led_green,1);
                    ar.writeDigitalPin(led_red,0);
                    app.LEDLamp.Color = 'green';
                end
            end
            %end of timer
            clock_time  =toc
            % Adding to a vector based on number of samples
            t = linspace(0,clock_time,time_to_run);
            % Saving the distance and timer to a table,
            % by converting row vector to column vector. 
            data = table(array_distance.', t.');
            app.UITable.Data = data;
            % Plotting Distance vs time
            plot(app.UIAxes,t, array_distance)
        end

        % Button pushed function: SAVEFILEButton
        function SAVEFILEButtonPushed(app, event)
            % Saving table data to current directory to a file called
            % mytable.m
            data = app.UITable.Data;
            save('mytable.mat','data');
        end

        % Button pushed function: LOADFILEButton
        function LOADFILEButtonPushed(app, event)
            %Loading a table called mytable.m from current directory
            load('mytable.mat');
            app.UITable.Data = data;
            x= table2array(data(:,2));
            y=table2array(data(:,1));
            plot(app.UIAxes, x,y);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Distance vs Time')
            xlabel(app.UIAxes, 'Time')
            ylabel(app.UIAxes, 'Distance')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Tag = 'plot_data';
            app.UIAxes.Position = [14 102 383 331];

            % Create STARTButton
            app.STARTButton = uibutton(app.UIFigure, 'push');
            app.STARTButton.ButtonPushedFcn = createCallbackFcn(app, @STARTButtonPushed, true);
            app.STARTButton.Tag = 'start_button';
            app.STARTButton.Position = [27 18 124 61];
            app.STARTButton.Text = 'START';

            % Create UITable
            app.UITable = uitable(app.UIFigure);
            app.UITable.ColumnName = {'Distance'; 'Time'};
            app.UITable.RowName = {};
            app.UITable.Tag = 'table_data';
            app.UITable.Position = [410 138 202 276];

            % Create RESETButton
            app.RESETButton = uibutton(app.UIFigure, 'push');
            app.RESETButton.ButtonPushedFcn = createCallbackFcn(app, @RESETButtonPushed, true);
            app.RESETButton.Tag = 'reset_button';
            app.RESETButton.Position = [196 18 124 61];
            app.RESETButton.Text = 'RESET';

            % Create LEDLampLabel
            app.LEDLampLabel = uilabel(app.UIFigure);
            app.LEDLampLabel.HorizontalAlignment = 'right';
            app.LEDLampLabel.Position = [338 37 29 22];
            app.LEDLampLabel.Text = 'LED';

            % Create LEDLamp
            app.LEDLamp = uilamp(app.UIFigure);
            app.LEDLamp.Tag = 'led_light';
            app.LEDLamp.Position = [382 20 56 56];
            app.LEDLamp.Color = [1 1 1];

            % Create LOADFILEButton
            app.LOADFILEButton = uibutton(app.UIFigure, 'push');
            app.LOADFILEButton.ButtonPushedFcn = createCallbackFcn(app, @LOADFILEButtonPushed, true);
            app.LOADFILEButton.Tag = 'load_file_button';
            app.LOADFILEButton.Position = [476 18 99 50];
            app.LOADFILEButton.Text = 'LOAD FILE';

            % Create SAVEFILEButton
            app.SAVEFILEButton = uibutton(app.UIFigure, 'push');
            app.SAVEFILEButton.ButtonPushedFcn = createCallbackFcn(app, @SAVEFILEButtonPushed, true);
            app.SAVEFILEButton.Tag = 'save_file_button';
            app.SAVEFILEButton.Position = [476 78 99 50];
            app.SAVEFILEButton.Text = 'SAVE FILE';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = pendulum_design_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end