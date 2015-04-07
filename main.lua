io.stdout:setvbuf("no")

function love.load()
    selectedSpace = {0, 0} --Space chosen by player to place card
    pickSpace = false --true if in pick space state
    pickCard = true --true if in pick card state
    cardPick = 0 --the index of the chosen card in the players hand
    playerTurn = true --controls turn state
    numLeft = 9 --cards left to be placed, game ends at 0
    gameEnd = false --initiates end of game actions
    twoPlayer = true --if true, two-player game

    player = {
    	grid_x = 64,
        grid_y = 256,
        act_x = 96,
        act_y = 128,
        speed = 10
    }

    Tileset = love.graphics.newImage('bgs.png')
    blueCardTile = love.graphics.newImage('cardsBlue.png')
    redCardTile = love.graphics.newImage('cardsRed.png')

    TileW, TileH = 32,32
    local tilesetW, tilesetH = Tileset:getWidth(), Tileset:getHeight()
    local cardtileW, cardtileH = blueCardTile:getWidth(), blueCardTile:getHeight()

    local quadInfo = {
        {  0,  0 }, -- 1 = grey 
        { 32,  0 }, -- 2 = blue
        {  0, 32 }, -- 3 = flowers
        { 32, 32 }  -- 4 = boxTop
    }

    Quads = {}
    for i,info in ipairs(quadInfo) do
        -- info[1] = x, info[2] = y
        Quads[i] = love.graphics.newQuad(info[1], info[2], TileW, TileH, tilesetW, tilesetH)
    end

    map = {
        { 1, 1, 1, 1, 1, 1, 1},
        { 1, 0, 0, 0, 0, 0, 1},
        { 1, 1, 1, 1, 1, 1, 1},
        { 1, 1, 0, 0, 0, 1, 1},
        { 1, 1, 0, 0, 0, 1, 1},
        { 1, 1, 0, 0, 0, 1, 1},
        { 1, 1, 1, 1, 1, 1, 1},
        { 1, 0, 0, 0, 0, 0, 1},
        { 1, 1, 1, 1, 1, 1, 1}
    }

    --holds the actual cards placed on the board
    board = {
        {0,0,0},
        {0,0,0},
        {0,0,0}
    }
    
    setupCards(cardtileW, cardtileH)

    --setup the board as a canvas
    canvas = love.graphics.newCanvas(800, 600)
    love.graphics.setCanvas(canvas)
        canvas:clear()
        --love.graphics.setBlendMode('alpha')
        for rowIndex,row in ipairs(map) do
            for columnIndex,number in ipairs(row) do
                local x,y = columnIndex*TileW, rowIndex*TileH
                love.graphics.draw(Tileset, Quads[number+1], x, y)
            end
        end
    love.graphics.setCanvas()
end

function love.update(dt)
    if gameEnd == true then
        player.act_y = player.act_y - ((player.act_y - player.grid_y) * player.speed * dt)
        player.act_x = player.act_x - ((player.act_x - player.grid_x) * player.speed * dt)
    elseif numLeft == 0 and gameEnd == false then
        local numBlue = 0
        for rowIndex,row in ipairs(board) do
            for columnIndex,number in ipairs(row) do 
                if number ~= 0 and number.blue == true then
                    numBlue = numBlue + 1
                end 
            end
        end

        if numBlue > 4 then
            print("You Win")
        else
            print("You Lose")
        end
        gameEnd = true
    else
        player.act_y = player.act_y - ((player.act_y - player.grid_y) * player.speed * dt)
        player.act_x = player.act_x - ((player.act_x - player.grid_x) * player.speed * dt)

        if playerTurn == false and twoPlayer == false then
            local randCard,randX, randY
            randCard = math.random(#opponentCards)
            repeat
                math.randomseed(os.time())
                randX = math.random(3)
                randY = math.random(3)
            until board[randX][randY] == 0
            board[randX][randY] = opponentCards[randCard]
            table.remove(opponentCards, randCard)
            testSpace(randX, randY)

            numLeft = numLeft - 1
            playerTurn = true
        end
    end
end

function love.draw()
    --draw the map
    love.graphics.setBlendMode('premultiplied')
    love.graphics.draw(canvas)
    
    --draw the cards on the board
    for rowIndex,row in ipairs(board) do
        for columnIndex,number in ipairs(row) do
            if number ~= 0 then
                local x,y,quadNum = (rowIndex+2)*TileW, (columnIndex+3)*TileH, number[1]
                if number.blue == true then
                    love.graphics.draw(blueCardTile, playerCardQuads[quadNum], x, y)
                else
                    love.graphics.draw(redCardTile, playerCardQuads[quadNum], x, y)
                end
            end
        end
    end    

    --draw the players' hands
    drawHand(playerCards, blueCardTile, 8)
    drawHand(opponentCards, redCardTile, 2)
    --draw the player cursor
    love.graphics.rectangle("line", player.act_x, player.act_y, 32, 32)
end

function love.keypressed(key)
    if key == "up" then
        if testMap(0, -1) then
            player.grid_y = player.grid_y - 32
        end
    elseif key == "down" then
        if testMap(0, 1) then
            player.grid_y = player.grid_y + 32
        end
    elseif key == "left" then
        if testMap(-1, 0) then
            player.grid_x = player.grid_x - 32
        end
    elseif key == "right" then
        if testMap(1, 0) then
            player.grid_x = player.grid_x + 32
        end
    end

    --disable player selection if not player turn
    if key == "return" and (playerTurn == true or twoPlayer == true) then
        if pickSpace == true then
            selectedSpace[1] = player.grid_x/32 - 2
            selectedSpace[2] = player.grid_y/32 - 3
            --print("space: " .. selectedSpace[1] .."  " .. selectedSpace[2])

            --valid space was chosen
            if board[selectedSpace[1]][selectedSpace[2]] == 0 then
                if twoPlayer == true and playerTurn == false then
                    board[selectedSpace[1]][selectedSpace[2]] = opponentCards[cardPick]
                    table.remove(opponentCards, cardPick)
                else
                    board[selectedSpace[1]][selectedSpace[2]] = playerCards[cardPick]
                    table.remove(playerCards, cardPick)
                end
                testSpace(selectedSpace[1],selectedSpace[2])

                player.grid_x = 64
                if twoPlayer == true and playerTurn == true then
                    player.grid_y = 64
                    playerTurn = false
                else
                    player.grid_y = 256
                    playerTurn = true
                end
                pickSpace = false
                pickCard = true
                numLeft = numLeft - 1
            --invalid space was chosen
            else
                print("taken")
            end
        elseif pickCard == true then
            local handSize = #playerCards
            cardPick = player.grid_x/32 - 1
            --print("card: " .. cardPick)
            --print("size: " .. handSize)           
            player.grid_x = 128
            player.grid_y = 160
            pickSpace = true
            pickCard = false
        end
    end
    
    if key == "backspace" then
        if pickSpace == true then
            if twoPlayer == true and playerTurn == false then
                player.grid_y = 64
            else
                player.grid_y = 256
            end
            player.grid_x = 64
            pickSpace = false
            pickCard = true
        end
    end

    if key == "escape" then
    	 love.event.push('quit')
    end

end

--------------------------------------------
-----------------FUNCTIONS------------------
--------------------------------------------

-------------Loading Functions--------------

--load the players decks
function setupCards(cardtileW, cardtileH)
    --the players deck of cards
    playerCards = {
        --{cardNum,x,y,up,down,left,right,ifUsed,ifBlue}
        {1,0,0,1,1,5,4, blue = true}, 
        {2,32,0,5,1,3,1, blue = true},
        {3,0,32,1,3,5,3, blue = true},
        {4,32,32,6,1,2,1, blue = true},
        {5,64,0,2,1,5,3, blue = true},
        {6,64,32,2,4,4,1, blue = true},
        {7,96,0,1,4,1,5, blue = true},
        {8,96,32,3,2,1,5, blue = true},
        {9,0,64,2,6,1,1, blue = true},
        {10,32,64,4,4,3,2, blue = true},
        {11,64,64,2,2,6,1, blue = true}
    }
    playerCardQuads = {}
    for i,info in ipairs(playerCards) do
        -- info[1] = x, info[2] = y
        playerCardQuads[i] = love.graphics.newQuad(info[2], info[3], TileW, TileH, cardtileW, cardtileH)
    end
    playerCards = shuffle(playerCards)

    opponentCards = deepcopy(playerCards)
    opponentCards = shuffle(opponentCards)
    makeRed(opponentCards)
end

function makeRed(cardArray)
    for i,card in ipairs(cardArray) do 
        card.blue = false
    end
end

---------------Draw Functions---------------

function drawHand(whichCards, cardTiles, handHeight) 
    local cardsDrawn = 1
    for cardIndex,card in ipairs(whichCards) do
        love.graphics.draw(cardTiles, playerCardQuads[card[1]], (cardsDrawn+1)*TileW, handHeight*TileH)
        cardsDrawn = cardsDrawn + 1
        if cardsDrawn == 6 then break end --only show 5 cards in the hand
    end
end

-------------Gameplay Functions-------------

--check if player can move to a space
function testMap(x, y)
    if map[(player.grid_y / 32) + y][(player.grid_x / 32) + x] == 1 then
        return false
    end
    return true
end

--test the cards around a space for color changes 
--resulting from the card just placed there
function testSpace(x,y)
    --{cardNum,x,y,up,down,left,right,ifUsed,ifBlue}
    print("X: " .. x .. " Y: " .. y)
    local thisCard = board[x][y]
    if y > 1 then
        local cardAbove = board[x][y-1]
        if cardAbove ~= 0 then print("     Placed card: " .. thisCard[4] .. " Above: " .. cardAbove[5]) end
        if cardAbove ~= 0 and thisCard[4] > cardAbove[5] then
            cardAbove.blue = thisCard.blue
        end
    end
    if y < 3 then
        local cardBelow = board[x][y+1]
        if cardBelow ~= 0 then print("     Placed card: " .. thisCard[5] .. " Below: " .. cardBelow[4]) end
        if cardBelow ~= 0 and thisCard[5] > cardBelow[4] then
            cardBelow.blue = thisCard.blue
        end
    end
    if x > 1 then
        --print("x>1")
        local cardLeft = board[x-1][y]
        if cardLeft ~= 0 then print("     Placed card: " .. thisCard[6] .. " Left: " .. cardLeft[7]) end
        if cardLeft ~= 0 and thisCard[6] > cardLeft[7] then
            --print("Us left: " .. thisCard[6] .. " them right: " .. cardLeft[7])
            cardLeft.blue = thisCard.blue
        end
    end
    if x < 3 then
        --print("x>3")
        local cardRight = board[x+1][y]
        if cardRight ~= 0 then print("     Placed card: " .. thisCard[7] .. " Right: " .. cardRight[6]) end
        if cardRight ~= 0 and thisCard[7] > cardRight[6] then
            --print("Us right: " .. thisCard[7] .. " them left: " .. cardRight[6])
            cardRight.blue = thisCard.blue
        end
    end
end

--------------Utility Fuctions--------------

function wait(seconds)
  local start = os.time()
  repeat until os.time() > start + seconds
end

--return deep copy of passed in table
function deepcopy(t)
    if type(t) ~= 'table' then return t end
        local mt = getmetatable(t)
        local res = {}
        for k,v in pairs(t) do
            if type(v) == 'table' then
            v = deepcopy(v)
        end
        res[k] = v
    end
    setmetatable(res,mt)
    return res
end

--pass in table, return shuffled table
function shuffle(tab)
    local n, order, res = #tab, {}, {}
    math.randomseed(os.time())
    --math.random()
    for i=1,n do order[i] = { rnd = math.random(), idx = i } end
    table.sort(order, function(a,b) return a.rnd < b.rnd end)
    for i=1,n do res[i] = tab[order[i].idx] end
    return res
end



 
