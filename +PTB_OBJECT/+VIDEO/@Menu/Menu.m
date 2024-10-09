classdef Menu < PTB_OBJECT.VIDEO.Base

    properties(GetAccess = public, SetAccess = public)
        % User accessible paramters :
    end % props

    properties(GetAccess = public, SetAccess = protected)
        % Internal parameters :
        items (:,1) string
        n (1,1) double
        i (1,1) double = 1
        value (1,1) string
        is_valid (1,1) logical = false
    end % props

    methods(Access = public)

        %--- constructor --------------------------------------------------
        function self = Menu()
            % pass
        end % fcn

        %------------------------------------------------------------------
        function SetItems( self, input )
            self.items = input;
            self.n = length(self.items);
            self.value = self.items(self.i);
        end % fcn

        %------------------------------------------------------------------
        function Next( self )
            self.i = self.i + 1;
            if self.i > self.n
                self.i = 1;
            end
            self.value = self.items(self.i);
            self.is_valid = false;
        end % fcn

        %------------------------------------------------------------------
        function Prev( self )
            self.i = self.i - 1;
            if self.i < 1
                self.i = self.n;
            end
            self.value = self.items(self.i);
            self.is_valid = false;
        end % fcn

        %------------------------------------------------------------------
        function Validate( self )
            self.is_valid = ~self.is_valid;
        end % fcn

        %------------------------------------------------------------------
        function Draw( self )
        end % fcn

    end % meths


end % class
