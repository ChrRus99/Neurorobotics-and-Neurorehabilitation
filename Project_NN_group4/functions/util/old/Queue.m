classdef Queue < handle
% This class represents a queue, in particular, it is the classical 
% implementation of a queue ADT usign a circular array.
%
% References: https://stackoverflow.com/questions/4142190/is-there-a-queue-in-matlab
%
% Author: Christian Francesco Russo



    properties (Access = private)
        buffer          % the vector containing the data
        index_start     % the start position of the queue
        index_end       % the end position of the queue
                        % the actually data is buffer(index_start : index_end-1)
        is_resizable    % true to have a dynamic-size queue, false to have a fixed-size queue
    end


    properties (Access = public)
        capacity        % the capacity of the queue
    end


    methods
        function obj = Queue(capacity)
            if nargin >= 1  % fixed-size queue
                if capacity <= 0
                    ME = MException(strcat("Invalid size for queue: ", int2str(size)));
                    throw(ME);
                end

                obj.is_resizable = false;
                obj.capacity = capacity + 1;
            else            % dynamic-size queue
                obj. is_resizable = false;
                obj.capacity = 10;
            end

            obj.buffer = zeros(obj.capacity, 1);
            obj.index_start = 1;
            obj.index_end = 1;
        end
    

        function s = size(obj)
            if obj.index_end >= obj.index_start
                s = obj.index_end - obj.index_start;
            else
                s = obj.index_end - obj.index_start + obj.capacity;
            end
        end


        function b = isEmpty(obj)
            b = ~logical(obj.size());
        end


        function b = isFull(obj)
            if ~obj.is_resizable
                if obj.size >= obj.capacity - 1
                    b = true;
                else
                    b = false;
                end
            else
                b = false;
    
            end
        end


        function s = empty(obj)
            s = obj.size();
            obj.index_start = 1;
            obj.index_end = 1;
        end
        

        function push(obj, elem)
            if obj.size >= obj.capacity - 1
                if obj.is_resizable
                    sz = obj.size();
    
                    if obj.index_end >= obj.index_start 
                        obj.buffer(1:sz) = obj.buffer(obj.index_start:obj.index_end-1);                    
                    else
                        obj.buffer(1:sz) = obj.buffer([obj.index_start:obj.capacity 1:obj.index_end-1]);
                    end
    
                    obj.buffer(sz+1:obj.capacity*2) = zeros(obj.capacity*2-sz, 1);
                    obj.capacity = numel(obj.buffer);
                    obj.index_start = 1;
                    obj.index_end = sz+1;
                else
                    warning('Queue:FULL_QUEUE', 'try to get data into a full queue');
                end
            end
            
            if ~obj.isFull()
                obj.buffer(obj.index_end) = elem;
                obj.index_end = mod(obj.index_end, obj.capacity) + 1;
            end
        end


        function elem = front(obj)
            if obj.index_end ~= obj.index_start
                elem = obj.buffer(obj.index_start);
            else
                elem = [];
                warning('Queue:NO_DATA', 'try to get data from an empty queue');
            end
        end
    

        function elem = back(obj)           
           if obj.index_end == obj.index_start
               elem = [];
               warning('Queue:NO_DATA', 'try to get data from an empty queue');
           else
               if obj.index_end == 1
                   elem = obj.buffer(obj.capacity);
               else
                   elem = obj.buffer(obj.index_end - 1);
               end
            end
    
        end


        function elem = pop(obj)
            if obj.index_end == obj.index_start
                error('Queue:NO_Data', 'Trying to pop an empty queue');
            else
                elem = obj.buffer(obj.index_start);
                obj.index_start = obj.index_start + 1;
                if obj.index_start > obj.capacity, obj.index_start = 1; end
            end             
        end
    

        function remove(obj)
            obj.index_start = 1;
            obj.index_end = 1;
        end
    

        function display(obj)
            if obj.size()
                if obj.index_start <= obj.index_end 
                    for i = obj.index_start : obj.index_end-1
                        disp([num2str(i - obj.index_start + 1) '-th element of the stack:']);
                        disp(obj.buffer{i});
                    end
                else
                    for i = obj.index_start : obj.capacity
                        disp([num2str(i - obj.index_start + 1) '-th element of the stack:']);
                        disp(obj.buffer{i});
                    end     
                    for i = 1 : obj.index_end-1
                        disp([num2str(i + obj.capacity - obj.index_start + 1) '-th element of the stack:']);
                        disp(obj.buffer{i});
                    end
                end
            else
                disp('The queue is empty');
            end
        end
    

        function c = content(obj)
            if obj.index_end >= obj.index_start
                c = obj.buffer(obj.index_start:obj.index_end-1);                    
            else
                c = obj.buffer([obj.index_start:obj.capacity 1:obj.index_end-1]);
            end
        end
    end
end