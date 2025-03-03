function Run()
global S

RestDuration = S.guiRestDuration;
switch S.guiACQmode
    case 'Acquisition'
        minutes_to_seconds = 60;
        RestDuration = RestDuration * minutes_to_seconds;
    case {'Debug', 'FastDebug'}
        RestDuration = 2;
end


%% create other recorders

S.recBehaviour = UTILS.RECORDER.Cell({'onset' 'actor' 'event' 'operator_selection' 'operator_item' 'operator_index' 'participant_selection' 'participant_item' 'participant_index'}, 1000);


%% set keybinds

S.cfgKeybinds = TASK.cfgKeyboard(); % cross task keybinds

S.cfgKeyOff   = 0.500; % seconds : time to wait after keypresse, to avoid "multiple presses"

S.cfgKeybinds.OperatorPrev = KbName(   'UpArrow');
S.cfgKeybinds.OperatorNext = KbName( 'DownArrow');
S.cfgKeybinds.OperatorOk   = KbName('RightArrow');

switch S.guiKeybind
    case 'fORP (MRI)'
        S.cfgKeybinds.ParticipantPrev = KbName('b');
        S.cfgKeybinds.ParticipantNext = KbName('y');
        S.cfgKeybinds.ParticipantOk   = KbName('g');
    case 'Keyboard'
        S.cfgKeybinds.ParticipantPrev = KbName('i');
        S.cfgKeybinds.ParticipantNext = KbName('k');
        S.cfgKeybinds.ParticipantOk   = KbName('l');
    otherwise
        error('unknown S.guiKeybind : %s', S.guiKeybind)
end

S.recKeylogger = UTILS.RECORDER.Keylogger(S.cfgKeybinds);
S.recKeylogger.Start();

%% set Parallel port

if S.guiParport
    S.ParallelPort.duration = 0.003; % seconds
    S.ParallelPort.messages.Menu           = 1;
    S.ParallelPort.messages.Rest           = 2;
    S.ParallelPort.messages.RestPostCrisis = 3;
    S.ParallelPort.messages.Crisis         = 4;
    S.ParallelPort.messages.Inhibition     = 5;
    S.ParallelPort.messages.Immitation     = 6;
    S.ParallelPort.messages.START          = 10;
    S.ParallelPort.messages.END            = 11;
end


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
MenuOperator.SetItems(["Repos" "ReposPostCrise" "Crise" "Inhibition" "Immitation"])
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

fprintf('Keybinds config : \n')
disp([keynames(:), keyvalues(:)])

MenuOperator.Draw();
MenuParticipant.Draw();
Window.Flip();
WaitSecs(S.cfgKeyOff);

if S.guiParport
    msg = S.ParallelPort.messages.START;
    WriteParPort(msg);
    WaitSecs(S.ParallelPort.duration);
    WriteParPort(0);
end

until_time = 0;
is_rest_condition = false;
is_patient_working = false;
is_post_working = false;

while 1

    [keyIsDown, secs, keyCode] = KbCheck();
    if keyIsDown
        EXIT = keyCode(S.cfgKeybinds.Abort);
        if EXIT, break, end


        if     keyCode(S.cfgKeybinds.OperatorPrev )
            flip  = true;
            actor = "Operator";
            event = "Prev";
            MenuOperator.Prev();
            MenuParticipant.RemoveSelect();
        elseif keyCode(S.cfgKeybinds.OperatorNext)
            flip  = true;
            actor = "Operator";
            event = "Next";
            MenuOperator.Next();
            MenuParticipant.RemoveSelect();
        elseif keyCode(S.cfgKeybinds.OperatorOk   )
            flip  = true;
            event = "Ok";
            actor = "Operator";
            MenuOperator.Validate();
            MenuParticipant.RemoveSelect();
        elseif keyCode(S.cfgKeybinds.ParticipantPrev )
            flip  = true;
            actor = 'Participant';
            event = "Prev";
            MenuParticipant.Prev();
        elseif keyCode(S.cfgKeybinds.ParticipantNext)
            flip  = true;
            actor = 'Participant';
            event = "Next";
            MenuParticipant.Next();
        elseif keyCode(S.cfgKeybinds.ParticipantOk   )
            flip  = true;
            actor = 'Participant';
            event = "Ok";
            MenuParticipant.Validate();
        end

        if flip
            flip = false;

            if is_rest_condition
                is_rest_condition = false;
                MenuOperator.RemoveSelect();
                MenuParticipant.RemoveSelect();
            end

            if is_patient_working
                if actor == "Participant"
                    is_post_working = true;
                end
                is_patient_working = false;
                MenuParticipant.RemoveSelect();
                MenuParticipant.JumpTo("Stop");
                MenuParticipant.Forbid("Start");
                tmp_actor = 'Code';
                tmp_event = 'WorkingFixationCrossOFF';
                fprintf('% 8.3fs - %11s %25s  -  %8s  %14s  %d  -  %8s  %11s  %d  \n', ...
                    flip_onset-S.STARTtime, tmp_actor, tmp_event, operator_select, char(MenuOperator.value), MenuOperator.i, participant_select, char(MenuParticipant.value), MenuParticipant.i)
                S.recBehaviour.AddLine({flip_onset-S.STARTtime, tmp_actor, tmp_event, MenuOperator.is_selected, char(MenuOperator.value), MenuOperator.i, MenuParticipant.is_selected, char(MenuParticipant.value), MenuParticipant.i})
                if S.guiParport
                    msg = S.ParallelPort.messages.Menu;
                    WriteParPort(msg);
                    WaitSecs(S.ParallelPort.duration);
                    WriteParPort(0);
                end
            end

            if actor == "Operator"
                is_patient_working = false;
                is_post_working = false;
                MenuParticipant.AllowAll();
            end

            if (MenuOperator.value == "Repos" || MenuOperator.value == "ReposPostCrise") && MenuOperator.is_selected
                FixationCross.Draw();
                until_time = secs + RestDuration;
                is_rest_condition = true;
                if S.guiParport
                    if     MenuOperator.value == "Repos"          , msg = S.ParallelPort.messages.Rest;
                    elseif MenuOperator.value == "ReposPostCrise" , msg = S.ParallelPort.messages.RestPostCrisis;
                    else, error('wrong parallel port message')
                    end
                    WriteParPort(msg);
                    WaitSecs(S.ParallelPort.duration);
                    WriteParPort(0);
                end
            elseif any(MenuOperator.value == ["Crise", "Inhibition", "Immitation"]) && MenuOperator.is_selected && MenuParticipant.value == "Start" && MenuParticipant.is_selected
                FixationCross.Draw();
                is_patient_working = true;
                if S.guiParport
                    if     MenuOperator.value == "Crise"      , msg = S.ParallelPort.messages.Crisis;
                    elseif MenuOperator.value == "Inhibition" , msg = S.ParallelPort.messages.Inhibition;
                    elseif MenuOperator.value == "Immitation" , msg = S.ParallelPort.messages.Immitation;
                    else, error('wrong parallel port message')
                    end
                    WriteParPort(msg);
                    WaitSecs(S.ParallelPort.duration);
                    WriteParPort(0);
                end
            elseif is_post_working
                MenuParticipant.Draw();
            else
                MenuOperator.Draw()
                MenuParticipant.Draw();
            end

            if MenuOperator.is_selected
                operator_select = 'SELECTED';
            else
                operator_select = 'FOCUS';
            end

            if MenuParticipant.is_selected
                participant_select = 'SELECTED';
                if is_post_working
                    MenuParticipant.AllowAll();
                    is_post_working = false;
                    MenuOperator.Draw();
                end
            else
                participant_select = 'FOCUS';
            end

            flip_onset = Window.Flip();

            fprintf('% 8.3fs - %11s %25s  -  %8s  %14s  %d  -  %8s  %11s  %d  \n', ...
                flip_onset-S.STARTtime, actor, event, operator_select, char(MenuOperator.value), MenuOperator.i, participant_select, char(MenuParticipant.value), MenuParticipant.i)

            S.recBehaviour.AddLine({flip_onset-S.STARTtime, actor, event, MenuOperator.is_selected, char(MenuOperator.value), MenuOperator.i, MenuParticipant.is_selected, char(MenuParticipant.value), MenuParticipant.i})

            if is_rest_condition || is_patient_working
                actor = 'Code';
                if is_rest_condition
                    event = 'RestFixationCrossON';
                elseif is_patient_working
                    event = 'WorkingFixationCrossON';
                end

                fprintf('% 8.3fs - %11s %25s  -  %8s  %14s  %d  -  %8s  %11s  %d  \n', ...
                    flip_onset-S.STARTtime, actor, event, operator_select, char(MenuOperator.value), MenuOperator.i, participant_select, char(MenuParticipant.value), MenuParticipant.i)
                S.recBehaviour.AddLine({flip_onset-S.STARTtime, actor, event, MenuOperator.is_selected, char(MenuOperator.value), MenuOperator.i, MenuParticipant.is_selected, char(MenuParticipant.value), MenuParticipant.i})
            end

            WaitSecs(S.cfgKeyOff);
        end % flip

    end % keypress

    if is_rest_condition && secs >= until_time
        is_rest_condition = false;
        operator_select = 'FOCUS';
        MenuOperator.RemoveSelect();
        MenuOperator.Draw()
        MenuParticipant.Draw();
        flip_onset = Window.Flip();
        actor = 'Code';
        event = 'RestFixationCrossOFF';
        fprintf('% 8.3fs - %11s %25s  -  %8s  %14s  %d  -  %8s  %11s  %d  \n', ...
            flip_onset-S.STARTtime, actor, event, operator_select, char(MenuOperator.value), MenuOperator.i, participant_select, char(MenuParticipant.value), MenuParticipant.i)
        S.recBehaviour.AddLine({flip_onset-S.STARTtime, actor, event, MenuOperator.is_selected, char(MenuOperator.value), MenuOperator.i, MenuParticipant.is_selected, char(MenuParticipant.value), MenuParticipant.i})
        if S.guiParport
            msg = S.ParallelPort.messages.Menu;
            WriteParPort(msg);
            WaitSecs(S.ParallelPort.duration);
            WriteParPort(0);
        end
    end

end % while

if S.guiParport
    msg = S.ParallelPort.messages.END;
    WriteParPort(msg);
    WaitSecs(S.ParallelPort.duration);
    WriteParPort(0);
end

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
