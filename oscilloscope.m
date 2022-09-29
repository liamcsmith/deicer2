classdef oscilloscope
    %OSCILLOSCOPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        folder_path
    end
    properties
        ch1
        ch2
        ch3
        ch4
    end
    methods
        function obj = oscilloscope(folder_path)
            arguments
                folder_path {mustBeFolder}
            end
            obj.folder_path = folder_path;

            files = dir(obj.folder_path);
            files = files(~[files(:).isdir]);
            files = arrayfun(@(x) fullfile(x.folder,x.name), ...
                             files, ...
                             'UniformOutput',false);
            files = string(files);
            scope_data = arrayfun(@(x) ScopeTrace('FilePath',x), ...
                                  files, ...
                                  "UniformOutput",false);
            for i = 1:numel(scope_data)
                switch scope_data{i}.Channel
                    case 'Ch1'
                        obj.ch1 = scope_data{i};
                    case 'Ch2'
                        obj.ch2 = scope_data{i};
                    case 'Ch3'
                        obj.ch3 = scope_data{i};
                    case 'Ch4'
                        obj.ch4 = scope_data{i};
                end
            end
        end
    end
end

