classdef Menu < PTB_OBJECT.VIDEO.Base

    properties(GetAccess = public, SetAccess = public)
        % User accessible paramters :
        text_side           (1,1) char
        text_size_ratio     (1,1) double
        text_font           (:,1) char
        text_color_base     (1,3) uint8
        text_color_focus    (1,3) uint8
        text_color_selected (1,3) uint8
    end % props

    properties(GetAccess = public, SetAccess = protected)
        % Internal parameters :
        text_size           (1,1) double
        items               (:,1) string
        n                   (1,1) double
        i                   (1,1) double = 1
        value               (1,1) string
        is_selected         (1,1) logical = false
        text_xy             (:,2) double
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
        function PrepareRendering( self )
            self.text_size = self.text_size_ratio * self.window.size_y;
            Screen('TextSize', self.window.ptr, self.text_size);
            Screen('TextFont', self.window.ptr, self.text_font);

            available = 0.8 * self.window.size_y;
            offset    = (self.window.size_y - available)/2;

            section = available / self.n;
            cy = offset + section/2 + (0:self.n-1)*section;

            for idx = 1 : length(self.items)
                normBoundsRect = Screen('TextBounds', self.window.ptr, char(self.items(idx)));
                [rw,rh] = RectSize(normBoundsRect);
                switch upper(self.text_side)
                    case 'L'
                        LR_offset = self.window.size_x * 0.25;
                    case 'R'
                        LR_offset = self.window.size_x * 0.75;
                end
                self.text_xy(idx,:) = [LR_offset, cy(idx)] -  [rw,rh]/2;
            end
        end % fcn

        %------------------------------------------------------------------
        function Next( self )
            self.i = self.i + 1;
            if self.i > self.n
                self.i = 1;
            end
            self.value = self.items(self.i);
            self.is_selected = false;
        end % fcn

        %------------------------------------------------------------------
        function Prev( self )
            self.i = self.i - 1;
            if self.i < 1
                self.i = self.n;
            end
            self.value = self.items(self.i);
            self.is_selected = false;
        end % fcn

        %------------------------------------------------------------------
        function Validate( self )
            self.is_selected = ~self.is_selected;
        end % fcn
        
        %------------------------------------------------------------------
        function RemoveSelect( self )
            self.is_selected = false;
        end % fcn

        %------------------------------------------------------------------
        function Draw( self )
            for idx = 1 : self.n
                Screen('DrawText', self.window.ptr, char(self.items(idx)), self.text_xy(idx,1), self.text_xy(idx,2), self.text_color_base);
            end

            if self.is_selected
                color = self.text_color_selected;
            else
                color = self.text_color_focus;
            end
            Screen('DrawText', self.window.ptr, char(self.value), self.text_xy(self.i,1), self.text_xy(self.i,2), color);
        end % fcn

    end % meths


end % class
