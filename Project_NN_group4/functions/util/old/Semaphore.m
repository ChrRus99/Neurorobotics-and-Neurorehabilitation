classdef Semaphore < handle
% This class represents a semaphore, which can be used to handle the
% concurrent access to critical variables or critical areas of code by two
% or more processes that want to access to them.
%
% Author: Christian Francesco Russo



   properties
      value = 0
   end
   
   methods
      function obj = Semaphore(value)
         obj.value = value;
      end
      
      function release(obj)
         while obj.value <= 0
            % wait
         end
         
         obj.value = obj.value - 1;
      end
      
      function acquire(obj)
         obj.value = obj.value + 1;
      end
   end
end