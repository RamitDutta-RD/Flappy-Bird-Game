function flappyBird

% HOW THE GAME WORKS
% the birds stays in the same position in terms of x axis
% the tubes keep moving towards the right
% the user gets a point just the moment at which the
% bird passes the right edge of the tubes
% after every 6 points you score the level gets upgraded
% which means an increase in both bird and tube speed
% the code upgrades the highest score when required
% different combinations of floors and backgrounds are generated randomly


% KEY EFFECTS
% 'uparrow','w' and 'space' starts the game
% 'space','w' and 'uparrow' lifts the bird upward
% 'escape' finishes the game


%% System Variables:
GameVer = '';          % The first full playable game

%% Constant Definitions:
GAME.MAX_FRAME_SKIP = [];
SoundOverFlag=0;
FloorFlag=0;
GAME.RESOLUTION = [];       % Game Resolution, default at [256 144]
GAME.WINDOW_SCALE = 2;      % The actual size of the window divided by resolution
GAME.FLOOR_TOP_Y = [];      % The y position of upper crust of the floor.
GAME.N_UPDATES_PER_SEC = [];
GAME.FRAME_DURATION = [];
GAME.GRAVITY = 0.1356;

TUBE.MIN_HEIGHT = [];       % The minimum height of a tube
TUBE.RANGE_HEIGHT = [];     % The range of the height of a tube
TUBE.SUM_HEIGHT = [];       % The summed height of the upper and low tube
TUBE.H_SPACE = [];           % Horizontal spacing between two tubs
TUBE.V_SPACE = [];           % Vertical spacing between two tubs
TUBE.WIDTH   = [];            % The 'actual' width of the detection box/ the visible tube
f=0;
GAMEPLAY.RIGHT_X_FIRST_TUBE = [];  % Xcoord of the left edge of the 1st tube
Level=1;
curTime=0;

%% Handles
MainFigureHdl = [];
MainAxesHdl = [];
MainCanvasHdl = [];
BirdSpriteHdl = [];
TubeSpriteHdl = [];
BeginInfoHdl = [];
FloorSpriteHdl = [];
ScoreInfoHdl = [];
GameOverHdl = [];
FloorAxesHdl = [];
LevelInfoHdl=[];

%% Game Parameters
MainFigureInitPos = [];
MainFigureSize = [];
MainAxesInitPos = []; % The initial position of the axes IN the figure
MainAxesSize = [];

InGameParams.CurrentBkg = 1;
InGameParams.CurrentBird = 1;

Flags.IsGameStarted = true;     
Flags.IsFirstTubeAdded = false; % Has the first tube been added to TubeLayer
Flags.ResetFloorTexture = true; % Result the pointer for the floor texture
Flags.PreGame = true;
Flags.NextTubeReady = true;
Flags.LevelChng=false;
CloseReq = false;

FlyKeyNames = {'space', 'return', 'uparrow', 'w'}; % the keys to be used
FlyKeyStatus = false; 
FlyKeyValid = true(size(FlyKeyNames)); % valid unless void 

%% Canvases:
MainCanvas = [];

TubeLayer.Alpha = [];
TubeLayer.CData = [];


%% RESOURCES:
Sprites = []; %handle for the .mat file

%% Positions:
Bird.COLLIDE_MASK = [];
Bird.INIT_SCREEN_POS = [45 100];           
Bird.WorldX = [];
Bird.ScreenPos = [45 100];
Bird.Angle = 0;
Bird.XGRID = [];
Bird.YGRID = [];
Bird.CurFrame = 1;
Bird.SpeedY = 0;
Bird.LastHeight = 0;

SinYRange = 44;% models oscillation amplitude
SinYPos = [];
SinY = [];

Score = 0;

Tubes.FrontP = 1;              % 1-6
Tubes.ScreenX = [300 380 460 540 620 700]-3; % The middle of each tube
Tubes.VOffset = ceil(rand(1,6)*105); % height of the bottom portion of each tube(random)

Best = 0;

%% -- Game Logic --

initVariables();
initWindow();


% Show flash screen at the start
CurrentFrameNo = double(0);

fade_time = cumsum([1 3 1]); % each individual number gives the time interval of each period
                            % cumsum is used to get the sum of time from t=0
% im2=imread('logo3.png');
pause(0.5);

% models the logo appearence
logo_stl = text(72, 30, 'Team Avengers', 'FontName', 'Cambria','FontSize', 25, 'FontWeight', 'Normal','Color',[1 1 1], 'HorizontalAlignment', 'center','VerticalAlignment','top');
logo_and = text(72, 60, 'presenting', 'FontSize', 15,'FontWeight', 'Bold','FontAngle', 'Italic', 'Color',[1 1 1], 'HorizontalAlignment', 'center','VerticalAlignment','middle');
logo_ilovematlabcn = image([0 144], [70 180], Sprites.logo, 'AlphaData',0);
stageStartTime = tic;

while 1
    loops = 0;
    curTime = toc(stageStartTime);
    while (curTime >= ((CurrentFrameNo) * GAME.FRAME_DURATION) && loops < GAME.MAX_FRAME_SKIP)
        
        if curTime < fade_time(1)
            set(logo_stl, 'Color',1 - [1 1 1].*max(min(curTime/fade_time(1), 1),0));
            set(logo_ilovematlabcn , 'AlphaData', max(min(curTime/fade_time(1), 1),0));
            set(logo_and, 'Color',1 - [1 1 1].*max(min(curTime/fade_time(1), 1),0));
        elseif curTime < fade_time(2)
            set(logo_stl, 'Color',[0 0 0]);
            set(logo_ilovematlabcn, 'AlphaData', 1);
            set(logo_and, 'Color', [0 0 0]);
        else
            set(logo_stl, 'Color',[1 1 1].*max(min((curTime-fade_time(2))/(fade_time(3) - fade_time(2)), 1),0));
            set(logo_ilovematlabcn, 'AlphaData',1-max(min((curTime-fade_time(2))/(fade_time(3) - fade_time(2)), 1),0));
            set(logo_and, 'Color', [1 1 1].*max(min((curTime-fade_time(2))/(fade_time(3) - fade_time(2)), 1),0));
        end
        CurrentFrameNo = CurrentFrameNo + 1;
        loops = loops + 1;
        frame_updated = true;
    end
    if frame_updated
        drawnow;
    end
    if curTime > fade_time
        break;
    end
end

% delets the logo and captions after fade time
delete(logo_stl);
delete(logo_ilovematlabcn);
delete(logo_and);
pause(1);

%% Main Game
while 1
    initGame();
    CurrentFrameNo = double(0);
    collide = false;
    fall_to_bottom = false;
    gameover = false;
    stageStartTime = tic;
    c = stageStartTime;
    FPS_lastTime = toc(stageStartTime);
    while 1
        loops = 0;
        curTime = toc(stageStartTime);
        while (curTime >= ((CurrentFrameNo) * GAME.FRAME_DURATION) && loops < GAME.MAX_FRAME_SKIP)
            
            if FlyKeyStatus  % If left key is pressed
                if ~gameover
                    Bird.SpeedY = -2.5; % as the ygrid is upside downn the negative value actually 
                                        % gives an upward lift to the bird
                    FlyKeyStatus = false;
                    Bird.LastHeight = Bird.ScreenPos(2);
                    if Flags.PreGame
                        Flags.PreGame = false;
                        set(BeginInfoHdl, 'Visible','off');
                        set(ScoreInfoBackHdl, 'Visible','off');
                        set(ScoreInfoForeHdl, 'Visible','on');
                    end
                else
                    if Bird.SpeedY < 0
                        Bird.SpeedY = 0;
                    end
                end
            end
            if Flags.PreGame
                processCPUBird;
            else
                processBird;
                
                if ~gameover
                    scrollTubes(1);
                end
            end
            addScore;
            
            Bird.CurFrame = 3 - floor(double(mod(CurrentFrameNo, 9))/3);
            
            %% Cycling the Palette
            % Update the cycle variables
            collide = isCollide();
            if collide
                gameover = true;
            end
            
            CurrentFrameNo = CurrentFrameNo+1; %if we dont increment it the while loop is over fairly quickly
            % and frames get updated frequently which quickens up the game
            
            loops = loops + 1; %works as a backup for the first condition
            frame_updated = true;
            
            % If the Bird has fallen to the ground
            if Bird.ScreenPos(2) >= 200-5;
                Bird.ScreenPos(2) = 200-5; % holds the bird in the screen in case of fall down
                gameover = true;
                if SoundOverFlag==0
                    sound(Sprites.sound_over,Sprites.frequency_over);
                    SoundOverFlag=1;
                end
                if abs(Bird.Angle - pi/2) < 1e-3
                    fall_to_bottom = true;
                    FlyKeyStatus = false;
                end
            end
        end
        
        %% Redraw the frame if the world has been processed
        if frame_updated
            %         drawToMainCanvas();
            set(MainCanvasHdl, 'CData', MainCanvas(1:200,:,:));
            
            if fall_to_bottom
                Bird.CurFrame = 2; %tuning
            end
            
            refreshBird();
            refreshTubes(); % brings the tubes forward along x axis
            if (~gameover)
                refreshFloor(CurrentFrameNo);
            end
            curScoreString = sprintf('%d',(Score));
            set(ScoreInfoForeHdl, 'String', curScoreString);
            set(ScoreInfoBackHdl, 'String', curScoreString);
            drawnow;
            frame_updated = false;
            c = toc(stageStartTime);
        end
        
        if fall_to_bottom
            if Score > Best
                Best = Score;        
                for i_save = 1:4     % Try saving four times if error occurs
                    try
                        save sprites2.mat Best -append
                        break;
                    catch
                        continue;
                    end
                end     % If the error still persist even after four saves, then
                if i_save == 4
                    disp('FLAPPY_Bird: Can''t save high score');
                end
            end
            
            score_report = {sprintf('Score: %d', Score), sprintf('Best: %d', Best)};
            set(ScoreInfoHdl, 'Visible','on', 'String', score_report);
            set(GameOverHdl, 'Visible','on');
            save sprites2.mat Best -append
            
            if FlyKeyStatus
                FlyKeyStatus = false;
                break;
            end
        end
        
        if CloseReq
            delete(MainFigureHdl); % deletes the figure at pressing 'escape' 
            clear all;
            return;
        end
    end
end

    function initVariables()
        Sprites = load('sprites2.mat');
        GAME.MAX_FRAME_SKIP = 5;
        GAME.RESOLUTION = [256 144];
        GAME.WINDOW_RES = [256 144];
        GAME.FLOOR_HEIGHT = 56;
        GAME.FLOOR_TOP_Y = GAME.RESOLUTION(1) - GAME.FLOOR_HEIGHT + 1;
        GAME.N_UPDATE_PERSEC = 60;
        GAME.FRAME_DURATION = 1/GAME.N_UPDATE_PERSEC;
        
        TUBE.H_SPACE = 80 ;           % Horizontal spacing between two tubs
        TUBE.V_SPACE = 48;           % Vertical spacing between two tubs
        TUBE.WIDTH   = 24;            % The 'actual' width of the detection box
        TUBE.MIN_HEIGHT = 36;
        TUBE.SUM_HEIGHT = GAME.RESOLUTION(1)-TUBE.V_SPACE-...
            GAME.FLOOR_HEIGHT;
        TUBE.RANGE_HEIGHT = TUBE.SUM_HEIGHT -TUBE.MIN_HEIGHT*2;
        
        TUBE.PASS_POINT = [1 44];
        
        SoundOverFlag=0;
        GAMEPLAY.RIGHT_X_FIRST_TUBE = 300;  % Xcoord of the right edge of the 1st tube
        
        %% Handles
        MainFigureHdl = [];
        MainAxesHdl = [];
        
        %% Game Parameters
        MainFigureInitPos = [500 100];%position of the 
        MainFigureSize = GAME.WINDOW_RES([2 1]).*2;
        MainAxesInitPos = [0 0];  % The initial position of the axes IN the figure
        MainAxesSize = [144 200]; % axes of the game
        FloorAxesSize = [144 56];
        
        %% Canvases:
        MainCanvas = uint8(zeros([GAME.RESOLUTION 3]));
        
        Bird_size = Sprites.Bird.Size;
        [Bird.XGRID, Bird.YGRID] = meshgrid([-ceil(Bird_size(2)/2):floor(Bird_size(2)/2)], ...
            [ceil(Bird_size(1)/2):-1:-floor(Bird_size(1)/2)]); %gives the complete range that the bird expanses
        Bird.COLLIDE_MASK = false(12,12);
        [tempx tempy] = meshgrid(linspace(-1,1,12));
        Bird.COLLIDE_MASK = (tempx.^2 + tempy.^2) <= 1;
        
        
        Bird.OSCIL_RANGE = [128 4]; % [YPos, Amplitude]
        
        SinY = Bird.OSCIL_RANGE(1) + sin(linspace(0, 2*pi, SinYRange))* Bird.OSCIL_RANGE(2);% models the oscillation of bird
        SinYPos = 1;
        Best = Sprites.Best;    % Best Score
    end

%% --- Graphics Section ---
    function initWindow()
        
        % initWindow - initialize the main window, axes and image objects
        MainFigureHdl = figure('Name', ['Flappy Bird ' GameVer], ...
            'NumberTitle' ,'off', ...
            'Units', 'pixels', ...
            'Position', [MainFigureInitPos, MainFigureSize], ...
            'MenuBar', 'none', ... % disallows displaying the menubar at the top
            'Renderer', 'OpenGL',... 
            'Color',[0 0 0], ...% makes the bkg white
            'Resize','off', ... % doesn't allow the user to make the window larger
            'KeyPressFcn', @stl_KeyPressFcn, ...
            'WindowKeyPressFcn', @stl_KeyDown,...
            'WindowKeyReleaseFcn', @stl_KeyUp,...
            'CloseRequestFcn', @stl_CloseReqFcn);
        
        FloorAxesHdl = axes('Parent', MainFigureHdl, ...
            'Units', 'normalized',...
            'Position', [MainAxesInitPos, (1-MainAxesInitPos) .* [1 56/256]], ...
            'color', [1 1 1], ...
            'XLim', [0 MainAxesSize(1)]-0.5, ...
            'YLim', [0 56]-0.5, ...
            'YDir', 'reverse', ...
            'NextPlot', 'add', ...
            'Visible', 'on',...
            'XTick',[], 'YTick', []);
        
        MainAxesHdl = axes('Parent', MainFigureHdl, ...
            'Units', 'normalized',...
            'Position', [MainAxesInitPos + [0 (1-MainAxesInitPos(2).*2)*56/256], (1-MainAxesInitPos.*2).*[1 200/256]], ...
            'color', [1 1 1], ...
            'XLim', [0 MainAxesSize(1)]-0.5, ...% limits the axis size
            'YLim', [0 MainAxesSize(2)]-0.5, ...
            'YDir', 'reverse', ... % y-axis starts from the top
            'NextPlot', 'add', ... % plors the new frames in the same axes
            'Visible', 'on', ...
            'XTick',[], ... % does not show numbers along axes
            'YTick',[]);
        
        
        MainCanvasHdl = image([0 MainAxesSize(1)-1], [0 MainAxesSize(2)-1], [],...
            'Parent', MainAxesHdl,...
            'Visible', 'on');% background image
        
        TubeSpriteHdl = zeros(1,6);
        for i = 1:6
            TubeSpriteHdl(i) = image([0 26-1], [0 304-1], [],...
                'Parent', MainAxesHdl,...
                'Visible', 'on'); %tubes
        end
       
        BirdSpriteHdl = surface(Bird.XGRID-100,Bird.YGRID-100, ...% creates an object taking these as x and y co-ordinates
            zeros(size(Bird.XGRID)), Sprites.Bird.CDataNan(:,:,:,1), ...%specifies the color
            'CDataMapping', 'direct',... %cdata mapping method
            'EdgeColor','none', ... % makes the edges of the bird invisible
            'Visible','on', ...
            'Parent', MainAxesHdl); %bird from the .mat file
        
        FloorSpriteHdl = image([0], [0],[],...
            'Parent', FloorAxesHdl, ...
            'Visible', 'on '); %floor
        
        BeginInfoHdl = text(72, 100, 'Tap SPACE to begin', ...
            'FontName', 'Helvetica', 'FontSize', 20, 'HorizontalAlignment', 'center','Color',[.25 .25 .25], 'Visible','off');
        
        ScoreInfoBackHdl = text(72, 50, '0', ...
            'FontName', 'Helvetica', 'FontSize', 30, 'HorizontalAlignment', 'center','Color',[0,0,0], 'Visible','off');
        
        ScoreInfoForeHdl = text(70.5, 48.5, '0', ...
            'FontName', 'Helvetica', 'FontSize', 30, 'HorizontalAlignment', 'center', 'Color',[1 1 1], 'Visible','off');
        
        GameOverHdl = text(72, 70, 'GAME OVER', ...
            'FontName', 'Arial', 'FontSize', 20, 'HorizontalAlignment', 'center','Color',[1 0 0], 'Visible','off');        
        
        ScoreInfoHdl = text(72, 110, 'Best', ...
            'FontName', 'Helvetica', 'FontSize', 20, 'FontWeight', 'Bold', 'HorizontalAlignment', 'center','Color',[0 0 0], 'Visible', 'off');
        
        LevelInfoHdl=text(72, 120, 'Level', ...
            'FontName', 'Helvetica', 'FontSize', 15, 'FontWeight', 'Bold', 'HorizontalAlignment', 'center','Color','blue', 'Visible', 'off');
    end

    function initGame()
        % The scroll layer for the tubes
        TubeLayer.Alpha = false([GAME.RESOLUTION.*[1 2] 6]);% makes the background transparent to start with
        TubeLayer.CData = uint8(zeros([GAME.RESOLUTION.*[1 2] 6]));
        SoundOverFlag=0;
        Bird.Angle = 0;
        Score = 0;
        
        Flags.ResetFloorTexture = true;
        SinYPos = 1;
        Flags.PreGame = true;
        
        drawToMainCanvas();
        set(MainCanvasHdl, 'CData', MainCanvas);
        set(BeginInfoHdl, 'Visible','on');
        set(ScoreInfoHdl, 'Visible','off');
        set(ScoreInfoBackHdl, 'Visible','off');
        set(ScoreInfoForeHdl, 'Visible','off');
        set(GameOverHdl, 'Visible','off');
        set(LevelInfoHdl,'Visible','off');
        
        % randomizing the two floors
        if rand<.5
            set(FloorSpriteHdl, 'CData',Sprites.Floor.CData);
            FloorFlag=0;
        else
            set(FloorSpriteHdl, 'CData',Sprites.Floor2);
            FloorFlag=1;
        end
        
        Tubes.FrontP = 1;              % 1 to 6
        Tubes.ScreenX = [300 380 460 540 620 700]-2; % The middle of each tube
        Tubes.VOffset = ceil(rand(1,6)*105); %randomizes height of tubes
        refreshTubes;
        
        for i = 1:6
            set(TubeSpriteHdl(i),'CData',Sprites.TubGap.CData,...
                'AlphaData',Sprites.TubGap.Alpha);
            redrawTube(i);
        end
    end
%% Game Logic

    % refreshes the bird at each call
    function processBird()
        Bird.ScreenPos(2) = Bird.ScreenPos(2) + Bird.SpeedY*((Level-1)*0.1+1);
        Bird.SpeedY = Bird.SpeedY + GAME.GRAVITY;
        
        % if the bird is rising takes the larger angle
        if Bird.SpeedY < 0
            Bird.Angle = max(Bird.Angle - pi/10, -pi/10); % negative angle=upward movement
        else
            if Bird.ScreenPos(2) < Bird.LastHeight
                Bird.Angle = -pi/10; 
            else
                
                % if the bird is falling down we take the smaller angle
                Bird.Angle = min(Bird.Angle + pi/30, pi/2);% positive angle means falling
            end
        end
    end

    % Process the Bird when the game is not started
    function processCPUBird() 
        Bird.ScreenPos(2) = SinY(SinYPos); % models the oscillation
        SinYPos = mod(SinYPos, SinYRange)+1;
    end

    function drawToMainCanvas()
        % Draw the scrolls and sprites to the main canvas
        
        % Redraw the background randomly
        if(rand<.5) 
            MainCanvas = Sprites.Bkg2(:,:,:,InGameParams.CurrentBkg);
        else
            MainCanvas = Sprites.Bkg.CData(:,:,:,InGameParams.CurrentBkg);
        end
        TubeFirstCData = TubeLayer.CData(:, 1:GAME.RESOLUTION(2), :);
        TubeFirstAlpha = TubeLayer.Alpha(:, 1:GAME.RESOLUTION(2), :);
        
        MainCanvas(TubeFirstAlpha) = ...
            TubeFirstCData (TubeFirstAlpha);
    end

    function scrollTubes(offset)
        Tubes.ScreenX = Tubes.ScreenX - offset*((Level-1)*0.5+1); % takes tubes to the left
        
        if Flags.LevelChng
            value =-106;
            Flags.LevelChng=false;
        else 
            value=-26;
        end
        
        if Tubes.ScreenX(Tubes.FrontP) <=value % tubes have crossed the main canvas
            if value == -106
                Tubes.ScreenX(Tubes.FrontP) = Tubes.ScreenX(Tubes.FrontP)+80+80+80+ 214-value;
            else
               Tubes.ScreenX(Tubes.FrontP) = Tubes.ScreenX(Tubes.FrontP) +80+80+80+ 214+106;
            end
            Tubes.VOffset(Tubes.FrontP) = ceil(rand*105);
            redrawTube(Tubes.FrontP);
            
            Tubes.FrontP = mod((Tubes.FrontP),6)+1; % goes to one again when 6 has passed which allows
                                                    % not pilling up information

            Flags.NextTubeReady = true;
        end
    end

    function refreshTubes()
        for i = 1:6
            set(TubeSpriteHdl(i), 'XData', Tubes.ScreenX(i) + [0 26-1]); % the first element and last 
                                               % elements specify the positions of first and last cdata
        end
    end

    % models both the backgrounds
    function refreshFloor(frameNo)
        if FloorFlag==1
            
        offset = mod(frameNo, 15); %keeps it within 0 and 15 as the axis is fixed at one point
                                   % we require to go back to initial position
        end
        if FloorFlag==0
        offset = mod(frameNo, 24);
        end    
        set(FloorSpriteHdl, 'XData', -offset); % -ve means the cdata is plotted from right to left
    end

    function redrawTube(i)
        set(TubeSpriteHdl(i), 'YData', -(Tubes.VOffset(i)-1)); % writes the first cdata at voffset
            % and keeps going on ,-ve means the cdata is plotted from top to bottom
    end

%% --- Math Functions for handling Collision / Rotation etc. ---
    function collide_flag = isCollide()
        collide_flag = 0;
        
        if Bird.ScreenPos(1) >= Tubes.ScreenX(Tubes.FrontP)-5 && ...
                Bird.ScreenPos(1) <= Tubes.ScreenX(Tubes.FrontP)+6+25 % checks whteher the bird 
                                                                      % is within the tubes
        else
            return;
        end
        
        GapY = [128 177] - (Tubes.VOffset(Tubes.FrontP)-1);    % The upper and lower bound of the GAP, 0-based
        
        if Bird.ScreenPos(2) < GapY(1)+4 || Bird.ScreenPos(2) > GapY(2)-4 % checks whether has collided or not
            collide_flag = 1;
        end
        return;
    end

    function addScore()
        if Tubes.ScreenX(Tubes.FrontP)+TUBE.WIDTH < 40 && Flags.NextTubeReady
            Flags.NextTubeReady = false;
            Score = Score + 1; % adds point when the right edge of tube passes the bird
            sound(Sprites.sound_point,Sprites.frequency_point); % the point sound
            if mod(Score,6)==0
                Flags.LevelChng=true;
                f=curTime;
            else
                Flags.LevelChng=false;
            end
        end
        Level=floor(Score/6)+1;
%         if mod(Score,6)==0
%            Flags.LevelChng=true;
%            f=curTime
%            s=0;
%         end
        if (mod(Score,6)==0 && ~gameover) || Score==0
            if Score==0 && ~gameover
                if curTime < 1.5 && curTime>.5
                    set(LevelInfoHdl,'String', sprintf('%s : %.0f', 'Level', Level),'visible','on', 'Color',1 - [1 1 1].*max(min(curTime/2.5, 1),0));
                elseif curTime < 2
                    set(LevelInfoHdl, 'String', sprintf('%s : %.0f', 'Level', Level),'visible','on','Color',[0 0 0]);
                elseif curTime<3.5
                    set(LevelInfoHdl, 'String', sprintf('%s : %.0f', 'Level', Level),'visible','on','Color',[1 1 1].*max(min((curTime-fade_time(2))/(fade_time(3) - fade_time(2)), 1),0));
                elseif curTime>3
                    set(LevelInfoHdl,'visible','off');
                end
                if gameover||curTime>3.5
                    set(LevelInfoHdl,'Visible','off');
                end    
            end
            if Score~=0 && ~gameover
                if curTime < f+.3/1.3/2
                    set(LevelInfoHdl,'String', sprintf('%s : %.0f', 'Level', Level),'visible','on', 'Color',1 - [1 1 1].*max(min(curTime/2.5/1.3, 1),0));
                elseif curTime < f+1/1.3/2
                    set(LevelInfoHdl, 'String', sprintf('%s : %.0f', 'Level', Level),'visible','on','Color',[0 0 0]);
          
                elseif curTime<f+1.7/1.3/2
                    set(LevelInfoHdl, 'String', sprintf('%s : %.0f', 'Level', Level),'visible','on','Color',[1 1 1].*max(min((curTime-fade_time(2))/(fade_time(3) - fade_time(2)), 1),0));
                elseif curTime>f+1.7/1.3/2
                    set(LevelInfoHdl,'visible','off');
                end
                if gameover||curTime>f+1.7/1.3/2
                    set(LevelInfoHdl,'Visible','off');
                end    
            end
%              set(LevelInfoHdl,'String', sprintf('%s : %.0f', 'Level', Level),'visible','on');
              Flags.LevelChng=false;
%              %f=(curTime)
        end
        if gameover||Flags.LevelChng
            set(LevelInfoHdl,'Visible','off');
        end
    end

    function refreshBird()
        % move Bird to pos [X Y],
        % and rotate the Bird surface by X degrees, anticlockwise = +
        
        cosa = cos(Bird.Angle);
        sina = sin(Bird.Angle);
        
        xrotgrid = cosa .* Bird.XGRID + sina .* Bird.YGRID; %rotates the intial positions of the cdatas
        yrotgrid = sina .* Bird.XGRID - cosa .* Bird.YGRID;
        
        xtransgrid = xrotgrid + Bird.ScreenPos(1)-0.5;% Now adds them or moves them by the current postions
        ytransgrid = yrotgrid + Bird.ScreenPos(2)-0.5;
        
        set(BirdSpriteHdl, 'XData', xtransgrid, ...
            'YData', ytransgrid, ...
            'CData', Sprites.Bird.CDataNan(:,:,:,Bird.CurFrame));% generates the bird from the cdata
    end


%% -- Callbacks --
    function stl_KeyUp(hObject, eventdata, handles)
        key = get(hObject,'CurrentKey');
        % Remark the released keys as valid
        FlyKeyValid = FlyKeyValid | strcmp(key, FlyKeyNames);
    end

    function stl_KeyDown(hObject, eventdata, handles)
        key = get(hObject,'CurrentKey');
        
        % Has to be both 'pressed' and 'valid';
        % Two key presses at the same time will be counted as 1 key press
        down_keys = strcmp(key, FlyKeyNames);
        FlyKeyStatus = any(FlyKeyValid & down_keys);
        FlyKeyValid = FlyKeyValid & (~down_keys);
    end

    function stl_KeyPressFcn(hObject, eventdata, handles)
        curKey = get(hObject, 'CurrentKey');
        switch true
            case strcmp(curKey, 'escape')
                CloseReq = true;
        end
    end

    function stl_CloseReqFcn(hObject, eventdata, handles)
        CloseReq = true;
    end
end