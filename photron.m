classdef photron < handle
    properties
        filepath
    end
    properties (Access=private)
        header
    end
    properties (Dependent,Access=private)
        header_path             {mustBeFile}
        memmap
        byteorder
    end
    properties(Dependent)
        fps                     {mustBeInteger}
        resolution              {validateattributes(resolution,"numeric","2d")}
        date                    {mustBeText}
        camera_type             {mustBeText}
        exposure_time           {mustBeText}
        total_frames            {mustBeInteger}
        original_total_frames   {mustBeInteger}
        image_width             {mustBeInteger}
        image_height            {mustBeInteger}
        effective_bit_depth     {mustBeInteger}
        effective_bit_side      {mustBeText}
        file_bit_depth          {mustBeInteger}
        format                  {mustBeText}
    end
    methods % Constructor
        function obj = photron(filepath)
            arguments 
                filepath {mustBeText}
            end
            if isfolder(filepath)
                filepath = dir(filepath);
                filepath = filepath(cellfun(@(x) contains(x,'.mraw'), {filepath(:).name}));
                filepath = fullfile(filepath.folder,filepath.name);
            end
            obj.filepath = filepath;
            obj.get_header;
        end
    end
    methods % Dependent properties 
        % Header parsing
        function header_path = get.header_path(obj)
            header_path = regexprep(obj.filepath,".mraw",".cihx");
        end
        function get_header(obj)
            % Open the file 
            headr = splitlines(fileread(obj.header_path));

            % Truncate the file
            headr = join(headr(find(cellfun(@(x) contains(x,"<cih>" ), headr)):...
                               find(cellfun(@(x) contains(x,"</cih>"), headr))));
            
            % Parse XML to heterogeneous node tree
            obj.header = parseString(matlab.io.xml.dom.Parser(),headr{:}).Children;
        end
        function fps = get.fps(obj)
            fps = str2double(obj.read_element(obj.header,["cih","recordInfo","recordRate"]));
        end
        function date = get.date(obj)
            date = obj.read_element(obj.header,["cih","fileInfo","date"]);
        end
        function camera_type = get.camera_type(obj)
            camera_type = obj.read_element(obj.header,["cih","deviceInfo","deviceName"]);
        end
        function exposure_time = get.exposure_time(obj)
            exposure_time = ['1/',obj.read_element(obj.header,["cih","recordInfo","shutterSpeed"])];
        end
        function total_frames = get.total_frames(obj)            
            total_frames = str2double(obj.read_element(obj.header,["cih","frameInfo","totalFrame"]));
        end
        function original_total_frames = get.original_total_frames(obj)
            original_total_frames = str2double(obj.read_element(obj.header,["cih","frameInfo","recordedFrame"]));
        end
        function image_width = get.image_width(obj)
            image_width = str2double(obj.read_element(obj.header,["cih","imageDataInfo","resolution","width"]));
        end
        function image_height= get.image_height(obj)
            image_height = str2double(obj.read_element(obj.header,["cih","imageDataInfo","resolution","height"]));
        end
        function format = get.format(obj)
            format = obj.read_element(obj.header,["cih","imageFileInfo","fileFormat"]);
        end
        function effective_bit_depth = get.effective_bit_depth(obj)
            effective_bit_depth = str2double(obj.read_element(obj.header,["cih","imageDataInfo","effectiveBit","depth"]));
        end
        function effective_bit_side = get.effective_bit_side(obj)
            effective_bit_side = obj.read_element(obj.header,["cih","imageDataInfo","effectiveBit","side"]);
        end
        function file_bit_depth = get.file_bit_depth(obj)
            file_bit_depth = str2double(obj.read_element(obj.header,["cih","imageDataInfo","colorInfo","bit"]));
        end
        function resolution = get.resolution(obj)
            resolution = [obj.image_height, obj.image_width];
        end
        function byteorder = get.byteorder(obj)
            switch obj.effective_bit_side
                case 'Lower'
                    byteorder = 'b'; % Big-endian
                otherwise
                    byteorder = 'l'; % Little-endian
            end
        end
    end
    methods % Class Methods
        % Image reading
        function frame     = read_frame(obj,frame)
            arguments
                obj
                frame {mustBeInteger}
            end
            assert(any(ismember(obj.file_bit_depth,[8,12,16])))
            switch obj.file_bit_depth
                case 8
                    frame = obj.memmap.Data(frame).image_data;
                case 16
                    frame = obj.memmap.Data(frame).image_data;
                case 12
                    bit_loc = prod(obj.resolution) * 12 * (frame - 1);
                    fid     = fopen(obj.filepath);
                    
                    fseek(fid, floor(bit_loc / 8), 'bof');
                    frame = fread(fid, ...
                                  flip(obj.resolution), ... % Shape of data
                                  'ubit12=>uint16', ...     % Cast ubit12 to uint16
                                  rem(bit_loc,8), ...       % Skip this many bits
                                  obj.byteorder);           % Use this byte order
                    fclose(fid);
            end
            
        end
        function frames    = read_frames(obj,frames)
            arguments
                obj
                frames {mustBeInteger}
            end
            switch obj.file_bit_depth
                case 8
                    the_memmap = obj.memmap;
                    frames = arrayfun(@(x) the_memmap.Data(x).image_data,frames(:),'UniformOutput',false);
                case 16
                    the_memmap = obj.memmap;
                    frames = arrayfun(@(x) the_memmap.Data(x).image_data,frames(:),'UniformOutput',false);
                case 12
                    bit_loc = prod(obj.resolution) * 12 * (frames - 1);
                    frames = cell(size(bit_loc));
                    fid     = fopen(obj.filepath);
                    for i = 1:numel(bit_loc)
                        fseek(fid, floor(bit_loc(i) / 8), 'bof');
                        frames{i} = fread(fid,flip(obj.resolution), ... % Shape of data
                                          'ubit12=>uint16', ...     % Cast ubit12 to uint16
                                          rem(bit_loc(i),8), ...       % Skip this many bits
                                          obj.byteorder);               % Use this byte order
                    end
                    fclose(fid);
            end 
        end
        function frames    = readall(obj)
            frames = obj.read_frames(1:obj.total_frames);
        end
        function imagedata = get.memmap(obj)
            arguments
                obj
            end
            switch obj.file_bit_depth
                case 8
                    dtype = 'uint8';
                case 16
                    dtype = 'uint16';
                otherwise
                    error('Bit Depth Error.')
            end
            imagedata = memmapfile(obj.filepath, ...
                                   'Format',{dtype,flip(obj.resolution),'image_data'}, ...
                                   'Repeat',obj.total_frames);
        end
        
        % Play video to prove it is ok
        function verify(obj,ax)
            arguments
                obj
                ax matlab.graphics.axis.Axes
            end
            frames = obj.readall;
            imshow(imadjust(frames{1}),'Parent',ax)
            drawnow
            pause(1)
            for i=1:2:numel(frames)
                imshow(imadjust(frames{i}),'Parent',ax)
                pause(0.005)
                drawnow
            end
        end
        end
    methods (Static) % XML Parser for header ingest
        function out = read_element(element, TagNames)
            arguments
                element  {mustBeA(element,"matlab.io.xml.dom.Node")}
                TagNames {mustBeText}
            end
            for TagName=TagNames
                for child=element
                    if isa(child,"matlab.io.xml.dom.Element")
                        if strcmp(child.TagName,TagName)
                            break
                        end
                    end
                end
                element = child.Children;
            end
            out = element.TextContent;
        end
    end
end