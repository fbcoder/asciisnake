'===========================================================================
'   ASCII SNAKE's ADVENTURES
'   [c]2010 fbcoder
'   
'   Snake game with ASCII graphics where snake has to collect keys to open
'   doors.
'
'===========================================================================

#include "string.bi"

'---------------------
'   Constants
'---------------------
Const MAX_SNAKELENGTH = 20
Const DEFAULT_SNAKELENGTH = 8
Const MAP_XSIZE = 80
Const MAP_YSIZE = 20
Const XOFFSET = 9
Const YOFFSET = 3

Const EMPTY = 0
Const WALL = 1
Const DOT = 2
Const DOORKEY = 3
Const DOOR = 4
Const GEM = 5
Const STRANGE_ARTIFACT = 6
Const SNAKEBODY = 7

Const SNAKE_ALIVE = 0
Const SNAKE_DEATH = 1
Const LEVEL_FINISHED = 2
Const LEVEL_EXIT = 3

Const TILEWIDTH = 1
Const TILEHEIGHT = 1

const DELAY = 0.05

Const NUM_OF_LEVELS = 2

Enum State
    GAME_INIT = 0
    GAME_RESTART = 1    
    GAME_NEXTLEVEL = 2
    GAME_EXIT = 3
    SNAKE_ALIVE
    sNAKE_DEATH
End Enum    

Enum Boolean
    FALSE = 0
    TRUE = not(false)
End Enum    

#Define null 0
#Define COLOR_SCREENBORDER 5

'=============================
'           Point2D
'=============================

Type Point2d
    Private:
        x as integer = 0
        y as integer = 0
    Public:    
        Declare Constructor ()
        Declare Constructor (x as integer, y as integer)
        Declare Sub changeX(xdif as integer)
        Declare Sub changeY(ydif as integer)
        Declare Function getX() as integer
        Declare Function getY() as integer
End Type

Constructor Point2d ()
End Constructor

Constructor Point2d (x as integer, y as integer)
    this.x = x
    this.y = y
End Constructor

Sub Point2d.changeX(xdif as integer)
    x+=xdif
End Sub

Sub Point2d.changeY(ydif as integer)
    y+=ydif
End Sub

Function Point2d.getX() as integer
    return x
End Function

Function Point2d.getY() as integer
    return y
End Function

'=====================
'      Helpers
'=====================

Declare Sub holdTillKeyPress(keycode As UByte = 0)
Declare Function screenToMap(p as point2d) as Point2d
Declare Sub printChar(p as point2d, char as ubyte, fgc as ubyte = 7, bgc as ubyte = 0)
Declare Sub animateExplosion(p as point2d)

'=====================
'
'=====================

Type SnakeInstruction
    screenPos as point2d
    mapPos as point2d
    direction as integer    
    Declare Constructor(screenPos as point2d, mapPos as point2d, direction as integer)
    nextInstruction as SnakeInstruction ptr = 0
    prevInstruction as SnakeInstruction ptr = 0
End Type    

Constructor SnakeInstruction (screenPos as point2d, mapPos as point2d, direction as integer)
    this.screenPos = screenPos
    this.mapPos = mapPos
    this.direction = direction
End Constructor

'===========================
'    MESSAGE DISPLAY 
'===========================

Type MessageDisplay
    private:        
        message as string
    public:
        Declare Constructor ()
        Declare Sub emptyMessageSpace()
        Declare Sub say(text as String, clr as byte = 2, continuationKey as integer = -1)    
End Type

Constructor MessageDisplay ()
    Locate 23,1:color 14,0: print "Telegram ";
                color COLOR_SCREENBORDER,0: print "}{"
End Constructor

Sub MessageDisplay.emptyMessageSpace()
    Locate 23,13: color 0,0: print string(80-13, " ")
End Sub

Sub MessageDisplay.say(text as string, clr as byte = 2, continuationKey as integer = -1)
    emptyMessageSpace()
    message = text
    Locate 23,13: Color clr,0: print message
    select case continuationKey
        Case -1: return
        Case 0: holdTillKeyPress()
        Case else: holdTillKeyPress(continuationKey)
    End select
End Sub

'===========================
'    GAME STATUS DISPLAY
'===========================
Type InfoField
    private:
        keys as integer  = 0
        level as integer = 0
        score as integer = 0
        length as integer = 0
        x as integer
        y as integer
    public:
        Declare constructor (x as integer, y as integer)
        Declare Sub updateKeys(newValue as integer)
        Declare Sub updateLevel(newValue as integer)
        Declare Sub updateLength(newValue as integer)
        Declare Sub updateScore(newValue as integer)
        Declare Sub printInfo() 
End Type

Constructor InfoField(x as integer, y as integer)
    this.x = x
    this.y = y
    printInfo()
End Constructor

Sub InfoField.printInfo()
    locate y,1:         color COLOR_SCREENBORDER,0: print string(80,chr$(176))
    updateKeys(keys)
    updateLevel(level)
    updateScore(score)
    updateLength(length)
    if 1 = 2 then 'never happens
    locate y,x + 0:     Color 7,6: print "Level"; :Color 6,0: print chr$(176);
                        Color 7,6: print format(level,"00")
    locate y,x + 15:    Color 7,6: print "Length"; :Color 6,0: print chr$(176); 
                        Color 7,6: print format(length,"00")
    locate y,x + 30:    Color 7,6: print "Score"; :Color 6,0: print chr$(176);
                        Color 7,6: print format(score,"0000")
    locate y,x + 45:    Color 7,6: print "Keys"; :Color 6,0: print chr$(176);
                        Color 7,6: print format(keys,"00")
    end if
End Sub

Sub InfoField.updateKeys(newValue as integer)
    keys = newValue
    locate y,x+45:  Color 15,COLOR_SCREENBORDER: print "Keys"; :Color COLOR_SCREENBORDER,0: print chr$(176);
                    Color 14,COLOR_SCREENBORDER: print format(keys,"00")
End Sub    

Sub InfoField.updateLevel(newValue as integer)
    level = newValue
    locate y,x+0:   Color 15,COLOR_SCREENBORDER: print "Level"; :Color COLOR_SCREENBORDER,0: print chr$(176);
                    Color 14,COLOR_SCREENBORDER: print format(level,"00") 
End Sub    

Sub InfoField.updateLength(newValue as integer)
    length = newValue
    locate y,x + 15:Color 15,COLOR_SCREENBORDER: print "Length"; :Color COLOR_SCREENBORDER,0: print chr$(176); 
                    Color 14,COLOR_SCREENBORDER: print format(length,"00")
End Sub    

Sub InfoField.updateScore(newValue as integer)
    score = newValue
    locate y,x+30:  Color 15,COLOR_SCREENBORDER: print "Score"; :Color COLOR_SCREENBORDER,0: print chr$(176);
                    Color 14,COLOR_SCREENBORDER: print format(score,"0000") 
End Sub    

'=================
'   Define Map
'=================
Type MapPtr as Map ptr 'forwarded pointer

Type Map
    Public:
        Declare Constructor(origMap() as byte, ow as integer, oh as integer, level as integer)            
        Declare Function getTile(p as Point2d) as byte
        'Declare Function getTile(x as integer, y as integer) as byte
        Declare Sub setTile(p as Point2d, v as byte)
        Declare Sub setTile(x as integer, y as integer, v as byte)
        Declare Function mapDataToAscii(x as integer, y as integer) as ubyte
        Declare Sub loadMap(origMap() as byte, ow as integer, oh as integer, level as integer)
        Declare Sub drawMap()
    Private:
        mWidth as integer
        mHeight as integer
        mapData(80,20) as byte        
End Type

'=================
'   Define Snake
'=================
Type SnakePart
    private:
        index As Integer
    Public:
        Declare Sub moveIndex()
        Declare Sub setIndex(i as integer)
        Declare Function getIndex() as integer
End Type
    
Sub SnakePart.moveIndex()
    index -= 1
    If index < 0 Then index = (MAX_SNAKELENGTH - 1)
End Sub

Function SnakePart.getIndex() as integer
    return index
End Function

Sub SnakePart.setIndex(i as integer)
    index = i
End Sub

Type Snake
    Private:        
        Declare Sub moveHead()
        Declare Sub eraseTail() 
        Declare Sub drawHead()
        Declare Sub drawTail() 
        Declare Sub changeCoords()
        Declare Sub die()
        
        screenPosition as point2d
        tilePosition as point2d
        direction as integer
        animate as integer = 0
        
        head as SnakeInstruction ptr = 0
        tail as SnakeInstruction ptr = 0
        
        
        length as integer
        score as integer = 0
        myKeys as integer = 0
        
        thisMap as MapPtr
        scoreDisplay as InfoField ptr                       
    Public:             
        Declare sub move()
        Declare sub setDirection(newDir as integer)
        Declare destructor()
        Declare constructor(x as integer, y as integer, direction as integer, length as integer, thisMap as MapPtr, scoreDisplay as InfoField ptr)
    
        state as integer            
End Type

Constructor Snake(x as integer, y as integer, startDir as integer, startLength as integer, thisMap as MapPtr, scoreDisplay as InfoField ptr)
        this.thisMap = thisMap
        this.scoreDisplay = scoreDisplay
        
        screenPosition = point2d(x + XOFFSET,y + YOFFSET)
        tilePosition = screenToMap(screenPosition)
        direction = startDir
        length = startLength
        for i as integer = 0 to length - 1        
            moveHead()
            drawhead()
        next i
End Constructor

Sub Snake.setDirection(newDir as integer)
    direction = newDir
End Sub

Sub Snake.drawHead()
    if head->prevInstruction <> null then
        If head->direction <> head->prevInstruction->direction then
            Dim as integer snakeChar
            Select case head->prevInstruction->direction
                case 1:
                    Select Case head->direction                        
                        case 2: snakeChar = 187
                        case 4: snakeChar = 201
                    End Select
                case 2:
                    Select Case head->direction
                        case 1: snakeChar = 200                        
                        case 3: snakeChar = 201
                    End Select
                case 3:
                    Select Case head->direction
                        case 2: snakeChar = 188                        
                        case 4: snakeChar = 200          
                    End Select            
                case 4:
                    Select Case head->direction            
                        case 1: snakeChar = 188
                        case 3: snakeChar = 187              
                End Select
            End Select
            printChar(head->prevInstruction->screenPos,snakeChar,2)
        else
            Select case animate
                Case 0: 
                    printChar(head->prevInstruction->screenPos, asc("<"),2) 
                    animate = 1
                Case 1:
                    printChar(head->prevInstruction->screenPos, asc(">"),2) 
                    animate = 0
            End select        
        end if
    end if
    Select Case head->direction
        Case 1: printChar(head->screenPos,30,3) 
        Case 2: printChar(head->screenPos,17,3)        
        Case 3: printChar(head->screenPos,31,3)    
        Case 4: printChar(head->screenPos,16,3)    
    End Select
    thisMap->setTile(head->mapPos, SNAKEBODY)
End Sub

Sub Snake.drawTail()
    if tail->NextInstruction <> null then
        select case tail->nextInstruction->direction
            Case 1: printChar(tail->nextInstruction->screenPos,31,2) 
            Case 2: printChar(tail->nextInstruction->screenPos,16,2)        
            Case 3: printChar(tail->nextInstruction->screenPos,30,2)    
            Case 4: printChar(tail->nextInstruction->screenPos,17,2)
        End Select        
    end if
    printChar(tail->screenPos, asc(" "),0)
    thisMap->setTile(tail->mapPos, EMPTY)
End Sub

Sub Snake.die()
    while tail <> null
        animateExplosion(tail->screenPos)
        eraseTail()
    wend
    state = SNAKE_DEATH
End Sub

Sub Snake.changeCoords()
    select case direction
        case 1:
            screenPosition.changeY(-1)
            tilePosition.changeY(-1)
        case 2:
            screenPosition.changeX(-1)
            tilePosition.changeX(-1)
        case 3:
            screenPosition.changeY(1)
            tilePosition.changeY(1)
        case 4:
            screenPosition.changeX(1)
            tilePosition.changeX(1)
    end select
End Sub

Sub Snake.move()
    changeCoords()
    Dim as boolean headAction = false, tailAction = false
    select case thisMap->getTile(tilePosition)
        case EMPTY:
            headAction = true
            tailAction = true
        case WALL:
            die()
        case DOT:
            length += 1
            headAction = true
        case SNAKEBODY:
            die()
        case DOORKEY:
            myKeys += 1
            headAction = true
            tailAction = true  
        case DOOR:
            if myKeys > 0 then
                myKeys -= 1
                headAction = true
                tailAction = true                
            else
                die()
            end if    
        case STRANGE_ARTIFACT:
            state = LEVEL_FINISHED
        case else:
            headAction = true: tailAction = true 
    End Select
    if headAction then moveHead()
    if tailAction and tail <> 0 then 
        drawTail()
        eraseTail()    
    End if
End Sub    
    
Sub Snake.moveHead()
    Dim as SnakeInstruction ptr newSnakeInstruction = new SnakeInstruction(screenPosition,tilePosition,direction)  
    if head <> 0 then
        newSnakeInstruction->prevInstruction = head
        head->nextInstruction = newSnakeInstruction
        head = newSnakeInstruction
    else
        head = newSnakeInstruction        
    end if
    if tail = null then tail = newSnakeInstruction
    drawHead()
End Sub    

Sub Snake.eraseTail()
    Dim as SnakeInstruction ptr oldTail = tail
    if tail->nextInstruction <> null then
        tail->nextInstruction->prevInstruction = null
    end if 
    tail = tail->nextInstruction
    delete oldTail
End Sub
'==================
'      Map
'==================

Constructor Map (origMap() as byte, ow as integer, oh as integer, level as integer)
    loadMap(origMap(), ow, oh, level)
End Constructor

Function Map.getTile(p as Point2d) as byte
    return mapData(p.getX, p.getY)
End Function

Sub Map.setTile(p as Point2d, v as byte)
    mapData(p.getX, p.getY) = v
End Sub

Function Map.mapDataToAscii(x as integer, y as integer) as ubyte
    Select Case mapData(x,y)
        case 0: return 32
        Case 1: Color 6,0: Return 177
        Case 2: Color 4,0: Return 3
        case 3: Color 14,0: Return 21        
        case 4: Color 8,0: Return 219
        case 5: Color 3,0: return 4
        case 6: Color 5,0: return 20
        case else: return 32
    End Select
End Function

Sub Map.drawMap()
    for i as integer = 0 to mWidth - 1
        for j as integer = 0 to mHeight - 1
            locate yOffset + 1 + j, xOffset + 1 + i
            print chr$(mapDataToAscii(i,j))
        next j
    next i     
End Sub

Sub Map.loadMap(origMap() as byte, ow as integer, oh as integer, level as integer)
    mWidth = ow
    mHeight = oh
    for i as integer = 0 to mHeight -1
        for j as integer = 0 to mWidth -1            
            mapData(j,i) = origMap(level,j,i)
        next j
    next i    
End Sub    

'==================
'   Helper subs and functions
'==================
Sub holdTillKeyPress(keycode As UByte = 0)
    While Inkey$ <> "": Wend
    Dim Key As String = ""
    Select Case keyCode
        Case 8 to 255:
            Do               
                Key = inkey
                Sleep 1,1
            Loop Until Key = Chr$(keycode)
        Case Else:
            Do               
                Key = inkey
                Sleep 1,1
            Loop While Key = ""
    End Select
End Sub

Sub drawBorders()
    color COLOR_SCREENBORDER,0
    for y as integer = 2 to 21
        if y mod 2 = 0 then
            locate y,1: print chr$(200);chr$(187)
            locate y,79: print chr$(201);chr$(188)
        else
            locate y,1: print chr$(201);chr$(188)
            locate y,79: print chr$(200);chr$(187)            
        end if
    next y
    Locate 22,1: print string(80,chr$(177))
End Sub

Function screenToMap(p as point2d) as Point2d
    function = Point2d((p.getX() - xOFFSET) / TILEWIDTH - 1,(p.getY() - YOFFSET) / TILEHEIGHT - 1)
End Function

Sub printChar(p as point2d, char as ubyte, fgc as ubyte = 7, bgc as ubyte = 0)
    locate p.getY(), p.getX(): color fgc,bgc: print chr$(char)
End Sub    

Sub animateExplosion(p as point2d)
    Dim as integer r = int(rnd * 5)    
    For i As Integer = 1 To r        
        printChar(p,177,4)
        sleep int(rnd * 20)
        printChar(p,178,14)
        Sleep int(rnd * 20)        
    Next i
    printChar(p,32)    
End Sub    

'================
' Prepare Game
'================
Screen 17
cls

'READ MAP DATA
Dim levelMap(2,60,15) as byte
For k as integer = 0 to 1
    For i as integer = 0 to 14
        For j as integer = 0 to 59
            read levelMap(k,j,i)
        next j    
    Next i
Next k

Dim level as integer = 0
Dim as State gamestate = GAME_INIT
Dim thisMap As Map = Map(levelMap(), 60, 15, level)
Dim scoreDisplay As InfoField = Infofield(4,1)
Dim messageField As messageDisplay

'================
'   SuperLoop
'================
Do
    
SELECT CASE gamestate
    Case GAME_INIT:
        scoreDisplay.updateLevel(level + 1)
    Case GAME_NEXTLEVEL:    
        if level < NUM_OF_LEVELS - 1 then
            level += 1
            scoreDisplay.updateLevel(level + 1)
            thisMap.loadMap(levelMap(),60,15,level)
        end if        
    Case GAME_RESTART:
        thisMap.loadMap(levelMap(),60,15,level)        
END SELECT

drawBorders() 
thisMap.drawMap()
Dim mySnake As Snake ptr = new Snake(3,3,4,8,@thisMap,@scoreDisplay)
messageField.say("Snake enters level ans says hi",7,0)
messageField.emptyMessageSpace()

'-----------------
'   INGAME LOOP
'-----------------
Dim Key As String = ""
Do 
    Dim as double starttime = timer()
    Do
    'snake.printSnakeState()
        Key = Inkey$    
        Select Case Key
            Case "w"
                mySnake->setDirection(1)
            Case "a"
                mySnake->setDirection(2)            
            Case "s"
                mySnake->setDirection(3)
            Case "d"
                mySnake->setDirection(4)            
            Case "l"
                'snake.lenghten()
            Case Chr$(8)
                'snake.shorten()
            Case Chr$(27)
                gamestate = GAME_EXIT
                mySnake->state = LEVEL_EXIT
            Case Chr$(32)
                messageField.say("** PAUSED, PRESS ANY KEY TO CONTINUE **",15,32)
                messageField.emptyMessageSpace()
        End Select
        sleep 1,1
    Loop while timer() - starttime < DELAY
    mySnake->move()
Loop While mySnake->state = SNAKE_ALIVE

'=============================
'   After Snake Stopped
'=============================
SELECT CASE mySnake->state
    Case SNAKE_DEATH:
        messageField.say("Snake had an accident... R.I.P. +", 4)
        gamestate = GAME_RESTART
        sleep
    Case LEVEL_FINISHED:
        if level = NUM_OF_LEVELS - 1 then
            cls
            Color 5,0: Locate 15,20: Print "Alle levels gehaald!"
            sleep
            gamestate = GAME_EXIT
        else 
            messageField.say("Level completed! Now move on to the next.",2)            
            gamestate = GAME_NEXTLEVEL
            Sleep
        end if
    Case LEVEL_EXIT:     
        gamestate = GAME_EXIT
End Select
LOOP WHILE gamestate <> GAME_EXIT

cls
Color 9,0: Locate 11,20: Print "/\/\/\ Snake says good bye /\/\/\"            
System

'===========================
'           Data
'===========================
'    1-2-3-4-5-6-7-8-9-#-1-2-3-4-5-6-7-8-9-#-1-2-3-4-5-6-7-8-9-#-1-2-3-4-5-6-7-8-9-#-1-2-3-4-5-6-7-8-9-#-1-2-3-4-5-6-7-8-9-#
Data 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,6,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,5,5,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,5,5,5,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,5,2,2,5,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,5,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0,5,2,2,5,0,0,0,0,1,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,5,2,2,5,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,5,5,5,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,1,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
Data 1,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
Data 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

Data 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,5,5,5,5,5,0,0,1,0,5,5,5,5,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,5,5,5,5,5,0,0,1,0,5,5,5,5,0,0,0,0,0,0,1,0,0,0,0,4,0,6,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,2,0,2,0,2,0,0,0,0,3,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,3,3,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,5,5,1
Data 1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,1,1,1,1,1,0,0,0,0,0,5,5,5,1
Data 1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,5,5,5,5,1,0,0,0,0,0,0,1,1,0,0,0,1,1,1,1,0,0,0,0,0,5,5,5,1
Data 1,0,5,5,5,5,0,1,0,0,0,0,0,0,0,1,0,3,0,0,0,0,0,0,0,0,0,0,0,0,1,5,5,5,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1
Data 1,0,5,5,5,5,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,5,5,5,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1
Data 1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,2,0,0,0,0,0,1,1,1,0,0,0,0,0,4,0,0,0,0,4,0,0,0,0,0,0,1,0,0,0,0,3,0,0,1,0,0,0,0,0,5,2,5,1
Data 1,0,3,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,2,3,2,1
Data 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,5,2,5,1
Data 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1






