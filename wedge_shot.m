classdef wedge_shot

    properties
        light_gate_scope
        force_sensor_scope
        camera_monitor_scope
        pdv_scope
        top_camera
        side_camera
    end
    
    methods
        function obj = wedge_shot(shot_folder_path)
            arguments
                shot_folder_path {mustBeFolder} = '/Users/liamsmith/Desktop/ds_test_01'
            end
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
                end
            end
        end
    end
end

