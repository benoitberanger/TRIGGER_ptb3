function Run()
global S


%% create other recorders

S.recBehaviour = UTILS.RECORDER.Cell({'onset' 'actor' 'event' 'operator_selection' 'operator_item' 'operator_index' 'participant_selection' 'participant_item' 'participant_index'}, 1000);


%% set keybinds

S.cfgKeybinds = TASK.cfgKeyboard(); % cross task keybinds

S.cfgKeyOff   = 0.200; % seconds : time to wait after keypresse, to avoid "multiple presses"

S.cfgKeybinds.OperatorLeft  = KbName('j');
S.cfgKeybinds.OperatorOk    = KbName('k');
S.cfgKeybinds.OperatorRight = KbName('l');

switch S.guiKeybind
    case 'fORP (MRI)'
        S.cfgKeybinds.ParticipantLeft  = KbName('b');
        S.cfgKeybinds.ParticipantOk    = KbName('y');
        S.cfgKeybinds.ParticipantRight = KbName('g');
    case 'Keyboard'
        S.cfgKeybinds.ParticipantLeft  = KbName('LeftArrow');
        S.cfgKeybinds.ParticipantOk    = KbName('DownArrow');
        S.cfgKeybinds.ParticipantRight = KbName('RightArrow');
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
S.Window.bg_color       = [030 030 030];
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

MenuOperator                     = PTB_OBJECT.VIDEO.Menu();
MenuOperator.window              = Window;
MenuOperator.text_side           = 'L';
MenuOperator.SetItems(["Repos" "Crise" "Inhibition" "Immitation"])
MenuOperator.text_size_ratio     = 0.10;
MenuOperator.text_font           = 'Arial';
MenuOperator.text_color_base     = [100 100 100];
MenuOperator.text_color_focus    = [200 200 200];
MenuOperator.text_color_selected = [100 255 100];
MenuOperator.PrepareRendering()

MenuParticipant                     = PTB_OBJECT.VIDEO.Menu();
MenuParticipant.window              = Window;
MenuParticipant.text_side           = 'R';
MenuParticipant.SetItems(["Start" "Stop" "Rate" "Sortie"])
MenuParticipant.text_size_ratio     = MenuOperator.text_size_ratio;
MenuParticipant.text_font           = MenuOperator.text_font;
MenuParticipant.text_color_base     = MenuOperator.text_color_base;
MenuParticipant.text_color_focus    = MenuOperator.text_color_focus;
MenuParticipant.text_color_selected = MenuOperator.text_color_selected;
MenuParticipant.PrepareRendering();


%% run the events

% initialize / pre-allocate some vars
flip = false;

FixationCross.Draw();
Window.Flip();

keynames  = fieldnames(S.cfgKeybinds);
keyvalues = KbName(struct2array(S.cfgKeybinds));
fprintf('Keybinds config : \n')
disp([keynames(:), keyvalues(:)])

S.STARTtime = PTB_ENGINE.START(S.cfgKeybinds.Start, S.cfgKeybinds.Abort);
S.recBehaviour.AddLine({0, 'Code', 'START', MenuOperator.is_selected, char(MenuOperator.value), MenuOperator.i, MenuParticipant.is_selected, char(MenuParticipant.value), MenuParticipant.i})

MenuOperator.Draw();
MenuParticipant.Draw();
Window.Flip();
WaitSecs(S.cfgKeyOff);

while 1

    [keyIsDown, ~, keyCode] = KbCheck();
    if keyIsDown
        EXIT = keyCode(S.cfgKeybinds.Abort);
        if EXIT, break, end


        if     keyCode(S.cfgKeybinds.OperatorLeft )
            flip  = true;
            actor = 'Operator';
            event = 'Left';
            MenuOperator.Prev();
        elseif keyCode(S.cfgKeybinds.OperatorRight)
            flip  = true;
            actor = 'Operator';
            event = 'Right';
            MenuOperator.Next();
        elseif keyCode(S.cfgKeybinds.OperatorOk   )
            flip  = true;
            event = 'Ok';
            actor = 'Operator';
            MenuOperator.Validate();
        elseif keyCode(S.cfgKeybinds.ParticipantLeft )
            flip  = true;
            actor = 'Participant';
            event = 'Left';
            MenuParticipant.Prev();
        elseif keyCode(S.cfgKeybinds.ParticipantRight)
            flip  = true;
            actor = 'Participant';
            event = 'Right';
            MenuParticipant.Next();
        elseif keyCode(S.cfgKeybinds.ParticipantOk   )
            flip  = true;
            actor = 'Participant';
            event = 'Ok';
            MenuParticipant.Validate();
        end

        if flip
            flip = false;
            MenuOperator.Draw()
            MenuParticipant.Draw();
            flip_onset = Window.Flip();

            if MenuOperator.is_selected
                operator_select = 'SELECTED';
            else
                operator_select = 'FOCUS';
            end
            if MenuParticipant.is_selected
                participant_select = 'SELECTED';
            else
                participant_select = 'FOCUS';
            end

            fprintf('% 8.3fs - %11s %5s  -  %8s  %11s  %d  -  %8s  %11s  %d  \n', ...
                flip_onset-S.STARTtime, actor, event, operator_select, char(MenuOperator.value), MenuOperator.i, participant_select, char(MenuParticipant.value), MenuParticipant.i)

            S.recBehaviour.AddLine({flip_onset-S.STARTtime, actor, event, MenuOperator.is_selected, char(MenuOperator.value), MenuOperator.i, MenuParticipant.is_selected, char(MenuParticipant.value), MenuParticipant.i})

            WaitSecs(S.cfgKeyOff);
        end

    end

end % while

S.ENDtime = GetSecs();
S.recBehaviour.AddLine({S.ENDtime-S.STARTtime, 'Code', 'END', MenuOperator.is_selected, char(MenuOperator.value), MenuOperator.i, MenuParticipant.is_selected, char(MenuParticipant.value), MenuParticipant.i})

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
