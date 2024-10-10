function Run()
global S


%% create other recorders

S.recBehaviour = UTILS.RECORDER.Cell({'onset' 'event' 'selection' 'item' 'index'}, 1000);


%% set keybinds

S.cfgKeybinds = TASK.cfgKeyboard(); % cross task keybinds

S.cfgKeyOff   = 0.200; % seconds : time to wait after keypresse, to avoid "multiple presses"

switch S.guiKeybind
    case 'fORP (MRI)'
        S.cfgKeybinds.Left  = KbName('b');
        S.cfgKeybinds.Ok    = KbName('y');
        S.cfgKeybinds.Right = KbName('g');
    case 'Keyboard'
        S.cfgKeybinds.Left  = KbName('LeftArrow');
        S.cfgKeybinds.Ok    = KbName('DownArrow');
        S.cfgKeybinds.Right = KbName('RightArrow');
    otherwise
        error('unknown S.guiKeybind : %s', S.guiKeybind)
end

S.recKeylogger = UTILS.RECORDER.Keylogger(S.cfgKeybinds);
S.recKeylogger.Start();


%% set parameters for rendering objects

S.cfgFixationCross = TASK.cfgFixationCross();

S.cfgText.SizeInstruction = 0.10;              % TextSize = round(ScreenY_px * Size)
S.cfgText.SizeStim        = 0.20;              % TextSize = round(ScreenY_px * Size)
S.cfgText.Color           = [127 127 127 255]; % [R G B a], from 0 to 255
S.cfgText.Center          = [0.5 0.5];         % Position_px = [ScreenX_px ScreenY_px] .* Position


%% start PTB engine

% get object
Window = PTB_ENGINE.VIDEO.Window();
S.Window = Window; % also save it in the global structure for diagnostic

% task specific paramters
S.Window.bg_color       = [050 050 050];
S.Window.movie_filepath = [S.OutFilepath '.mov'];

% set parameters from the GUI
S.Window.screen_id      = S.guiScreenID; % mandatory
S.Window.is_transparent = S.guiTransparent;
S.Window.is_windowed    = S.guiWindowed;
S.Window.is_recorded    = S.guiRecordMovie;

S.Window.Open();


%% prepare rendering object

FixationCross          = PTB_OBJECT.VIDEO.FixationCross();
FixationCross.window   = Window;
FixationCross.dim      = S.cfgFixationCross.Size;
FixationCross.width    = S.cfgFixationCross.Width;
FixationCross.color    = S.cfgFixationCross.Color;
FixationCross.center_x = S.cfgFixationCross.Position(1);
FixationCross.center_y = S.cfgFixationCross.Position(2);
FixationCross.GenerateCoords();

TextInstruction        = PTB_OBJECT.VIDEO.CenteredText();
TextInstruction.window = Window;
TextInstruction.color  = S.cfgFixationCross.Color;
TextInstruction.size   = 0.10;

TextStim      = TextInstruction.CopyObject();
TextStim.size = 0.20;


Menu          = PTB_OBJECT.VIDEO.Menu();
Menu.window   = Window;
Menu.SetItems(["A" "BB" "CCC"])
Menu.text_size_ratio = 0.20;
Menu.text_font = 'Arial';
Menu.text_color_base     = [100 100 100];
Menu.text_color_focus    = [200 200 200];
Menu.text_color_selected = [100 255 100];
Menu.PrepareRendering()


%% run the events

% initialize / pre-allocate some vars
flip = false;

FixationCross.Draw();
Window.Flip();
S.STARTtime = PTB_ENGINE.START(S.cfgKeybinds.Start, S.cfgKeybinds.Abort);
S.recBehaviour.AddLine({0, 'START', Menu.is_selected, char(Menu.value), Menu.i})

Menu.Draw();
Window.Flip();
WaitSecs(S.cfgKeyOff);

while 1

    [keyIsDown, ~, keyCode] = KbCheck();
    if keyIsDown
        EXIT = keyCode(S.cfgKeybinds.Abort);
        if EXIT, break, end


        if     keyCode(S.cfgKeybinds.Left )
            flip = true;
            event = 'Left';
            Menu.Prev();
        elseif keyCode(S.cfgKeybinds.Right)
            flip = true;
            event = 'Right';
            Menu.Next();
        elseif keyCode(S.cfgKeybinds.Ok   )
            flip = true;
            event = 'Ok';
            Menu.Validate();
        end

        if flip
            flip = false;
            Menu.Draw()
            flip_onset = Window.Flip();

            if Menu.is_selected
                sel = 'SELECTED';
            else
                sel = 'FOCUS';
            end
            fprintf('% 8.3fs  %5s  -  %8s  %5s  %d  \n', ...
                flip_onset-S.STARTtime, event, sel, char(Menu.value), Menu.i)

            S.recBehaviour.AddLine({flip_onset-S.STARTtime, event, Menu.is_selected, char(Menu.value), Menu.i})

            WaitSecs(S.cfgKeyOff);
        end

    end

end % while


S.ENDtime = GetSecs();
S.recBehaviour.AddLine({S.ENDtime-S.STARTtime, 'END', Menu.is_selected, char(Menu.value), Menu.i})


PTB_ENGINE.END();


%% End of task routine

S.Window.Close();

S.recKeylogger.GetQueue();
S.recKeylogger.Stop();
S.recKeylogger.kb2data();
switch S.guiACQmode
    case 'Acquisition'
    case {'Debug', 'FastDebug'}
        TR = CONFIG.TR();
        n_volume = ceil((S.ENDtime-S.STARTtime)/TR);
        S.recKeylogger.GenerateMRITrigger(TR, n_volume, S.STARTtime)
end
S.recKeylogger.ScaleTime(S.STARTtime);
S.recBehaviour.ClearEmptyLines();
assignin('base', 'S', S)

% switch S.guiACQmode
%     case 'Acquisition'
%     case {'Debug', 'FastDebug'}
% end
disp(S.recBehaviour.data2table())


end % fcn
