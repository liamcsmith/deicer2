classdef wedge_shot

    properties
        light_gate_scope
        force_sensor_scope
        camera_monitor_scope
        pdv_scope
        top_camera
        side_camera
        side_png
        top_png
    end
    
    methods
        function obj = wedge_shot(shot_folder_path)
            arguments
                shot_folder_path = ''
            end

            if ~isempty(shot_folder_path)

                subfolders = dir(shot_folder_path);
                subfolders = subfolders([subfolders(:).isdir]);
                assert(numel(subfolders)>2)
                
                for i=3:numel(subfolders)
                    folder = subfolders(i);
                    fullpath = fullfile(folder.folder,folder.name);
                    switch subfolders(i).name
                        case 'camscope'
                            obj.camera_monitor_scope = oscilloscope(fullpath);
                        case 'fscope'
                            obj.force_sensor_scope = oscilloscope(fullpath);
                        case 'lgscope'
                            obj.light_gate_scope = oscilloscope(fullpath);
                        case 'pdvscope'
                            obj.pdv_scope = oscilloscope(fullpath);
                        case 'top_raw'
                            obj.top_camera = photron(fullpath);
                        case 'side_raw'
                            obj.side_camera = photron(fullpath);
                        case 'side_png'
                            obj.side_png = imageDatastore(fullpath);
                        case 'top_png'
                            obj.top_png = imageDatastore(fullpath);
                    end
                end
            
                obj.verify
            else 
                folder_path = uigetdir('Select a location to spawn a shot directory');
                folder_name = regexprep(string(datetime),["-"," ",":"],'_');
                obj.build_folders(folder_path,folder_name);
            end
        end
        function verify(obj)
            % Show the top camera
            fig = figure();
            ax  = axes("Parent",fig);
            obj.top_camera.verify(ax);
            close(fig)
            clearvars fig ax
            
            % Show the side camera
            fig = figure();
            ax  = axes("Parent",fig);
            obj.side_camera.verify(ax);
            close(fig)
            clearvars fig ax

            % Plot out all the scope traces
            fig = tiledlayout(4,4);
%             obj.light_gate_scope.ch1.PlotTrace(     nexttile(fig,01));
%             obj.light_gate_scope.ch2.PlotTrace(     nexttile(fig,02));
%             obj.light_gate_scope.ch3.PlotTrace(     nexttile(fig,03));
%             obj.light_gate_scope.ch4.PlotTrace(     nexttile(fig,04));
            obj.force_sensor_scope.ch1.PlotTrace(   nexttile(fig,05));
            obj.force_sensor_scope.ch2.PlotTrace(   nexttile(fig,06));
            obj.force_sensor_scope.ch3.PlotTrace(   nexttile(fig,07));
            obj.force_sensor_scope.ch4.PlotTrace(   nexttile(fig,08));
            obj.camera_monitor_scope.ch1.PlotTrace( nexttile(fig,09));
            obj.camera_monitor_scope.ch2.PlotTrace( nexttile(fig,10));
            obj.camera_monitor_scope.ch3.PlotTrace( nexttile(fig,11));
            obj.camera_monitor_scope.ch4.PlotTrace( nexttile(fig,12));
%             obj.pdv_scope.ch1.PlotTrace(            nexttile(fig,13));
%             obj.pdv_scope.ch2.PlotTrace(            nexttile(fig,14));
%             obj.pdv_scope.ch3.PlotTrace(            nexttile(fig,15));
%             obj.pdv_scope.ch4.PlotTrace(            nexttile(fig,16));

            % Labeling the axes
            labels = ["LightGate C1", "LightGate C2", "LightGate C3", "LightGate C4", ...
                      "ForceSens C1", "ForceSens C2", "ForceSens C3", "ForceSens C4", ...
                      "CameraMon C1", "CameraMon C2", "CameraMon C3", "CameraMon C4", ...
                      "PDVTrcScp C1", "PDVTrcScp C2", "PDVTrcScp C3", "PDVTrcScp C4"];
            arrayfun(@(x) title(nexttile(fig,x), labels(x)),1:numel(labels))
        end
    end
    methods (Static)
        function build_folders(folder_path, new_folder_name)
            arguments
                folder_path         {mustBeFolder}
                new_folder_name     {mustBeText}
            end
            % Go to the desired folder location
            oldfolder = cd(folder_path);
            % Make the shot folder & jump into it
            mkdir(new_folder_name)
            cd(new_folder_name)
            % Make folders for all the diagnostics
            mkdir('camscope')
            mkdir('fscope')
            mkdir('lgscope')
            mkdir('pdvscope')
            mkdir('top_raw')
            mkdir('side_raw')
            mkdir('top_png')
            mkdir('side_png')

            cd(oldfolder)
        end
    end
end

