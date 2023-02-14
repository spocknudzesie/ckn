function scripts.ckn:initSelling(ops)
    self.data.currentOperation = ops
    hecho(string.format("[#00ff00CKN#r] Liczenie sprzedazy wlaczone.\n"))
    enableTrigger("javier_wyplaca")
    -- self.triggers.shopPaysMoney = tempTrigger("^Javier z ogromna niechecia wrecza ci (.*)\\.",
    --     function()
    --         self:addSold(scripts.money:descToCopper(matches[2]))
    --         return true
    --     end)
    self.data.selling = true
    self.data.soldValue = 0
end


function scripts.ckn:addSold(copper)
    self.data.soldValue = self.data.soldValue + copper
    self:printCurrentSales(true)
end


function scripts.ckn:finishSelling()
    local mt, zl, sr, md = scripts.money:denominate(self.data.soldValue, true)
    self:msg("info", "Liczenie sprzedazy zakonczone.\n")
    disableTrigger("javier_wyplaca")
    -- killTrigger(self.triggers.shopPaysMoney)
    self.data.selling = false
    
    self:saveOpsToFile(
        self.data.currentOperation,
        string.format("%6dmd: %2dmt %2dzl %2dsr %2dmd", self.data.soldValue, mt, zl, sr, md))
    
    self.data.currentOperation = false

    self:printCurrentSales()
end


function scripts.ckn:printCurrentSales(noMargins)
    echo("")
    self:msg("info", string.format("Laczna kwota sprzedazy: %s", 
        scripts.money:hCopperToDesc(self.data.soldValue)))
    if not noMargins then
        scripts.ckn:printMargins(self.data.soldValue, true, true)
    end
end


function scripts.ckn:printMargins(value, noHeader, payoutLink)
    if not noHeader then
        hecho(string.format("\nBrutto (%8d md):  %s\n", value, scripts.money:hCopperToDesc(value, true)))
    end
    for _, p in ipairs({5, 10, 15, 20}) do
        hecho(string.format("Prowizja #00ff00%2d#r%% wyniesie: ", p))
        local v = p*value / 100
        hecho(scripts.money:hCopperToDesc(v, true) .. ", netto: " .. scripts.money:hCopperToDesc(value - v, true, true))
        hecho("\n")
    end
end
    

function scripts.ckn:cmdSprzedaz(arg)
    local ops
    local add

    if arg[2] == "rozpocznij" or arg[2] == "zacznij" or arg[2] == "start" then
        if self.data.selling == true then
            self:msg('err', "Przeciez sprzedaz juz jest rozpoczeta.")
        else
            if arg[3] then
                ops = arg[3]
            end
            scripts.ckn:initSelling(ops)
        end
    elseif arg[2] == "reset" then
        if self.data.selling == false then
            self:msg("err", "Przeciez sprzedaz nie zostala rozpoczeta.")
        else
            self:msg("info", "Zresetowano licznik sprzedazy.")
            scripts.ckn:resetSelling()
        end
    elseif arg[2] == "zakoncz" or arg[2] == "stop" then
        if self.data.selling == false then
            self:msg("err", "Przeciez sprzedaz nie zostala rozpoczeta.")
        else
            scripts.ckn:finishSelling()
        end
    elseif arg[2] == "dodaj" or arg[2] == "+" then
        local a = string.split(arg[3], " ")
        local val

        if #a > 1 then
            val = scripts.money:simpleStringToCC(arg[3])
        else
            val = tonumber(arg[3])
        end
        self:addSold(val)
    else
        if self.data.selling == true then
            self:msg("ok", "Sprzedaz jest juz rozpoczeta. Mozesz ja zakonczyc komenda #ffff00/knsprzedaz stop#r")
            self:printCurrentSales(true)
        else
            self:msg("err", "Sprzedaz nie jest rozpoczeta. Mozesz ja rozpoczac komenda #ffff00/knsprzedaz start#r")
        end    
    end
end


function scripts.ckn:cmdWycen(arg)
    enableTrigger("knwycena")
    send('knwycen ' .. arg)
end


function scripts.ckn:coinToCase(number, coin)
    local base
    local adjEnd
    local noun

    if coin == 'mt' then
        base = 'mithrylow'
    elseif coin == 'zl' then 
        base = 'zlot'
    elseif coin == 'sr' then
        base = 'srebrn'
    elseif coin == 'md' then
        base = 'miedzian'
    end
    
    if number >= 10 and number <= 20 then
        adjEnd = "ych"
        noun = "monet"
    elseif number == 1 then
        adjEnd = "a"
        noun = "monete"
    elseif number%10 >= 2 and number%10 <= 4 then
        adjEnd = "e"
        noun = "monety"
    else
        adjEnd = "ych"
        noun = "monet"
    end

    return string.format("%d %s%s %s", number, base, adjEnd, noun)
end


function scripts.ckn:cmdWyplac(arg)
    if not self.data.lastPayout then
        table.remove(arg, 1)
        table.remove(arg, 1)
        local s = #arg
        local coins = {
            {'mt', tonumber(arg[2]), "mt", "#9ec3ff"},
            {'zl', tonumber(arg[3]), "zl", "#ffaa00"},
            {'sr', tonumber(arg[4]), "sr", "#dddddd"},
            {'md', tonumber(arg[5]), "md", "#ff6600"},
        }
        local who = arg[1]
        local desc = {}
        local simple = {}
        local payout
        local cmd = {}

        for _, coin in ipairs(coins) do
            if coin[2] > 0 then
                table.insert(desc, string.format("%s%d %s#r", coin[4], coin[2], coin[1]))
                table.insert(cmd, string.format("daj %s %s", self:coinToCase(coin[2], coin[1]), who))
                table.insert(simple, string.format("%d%s", coin[2], coin[1]))
            end
        end

        payout = string.join(desc,", ")

        msg = string.format("Wyplacic #ffff00%s#r kwote %s? "
            .. "Ponow komende, aby potwierdzic.", who, payout)

        self:msg('ok', msg)
        self.data.lastPayoutSimple = string.join(simple, " ")
        self.data.lastPayout = msg
        self.data.lastPayoutClient = who
        self.data.lastPayoutCmd = cmd
    else
        for _, cmd in ipairs(self.data.lastPayoutCmd) do
            send(cmd)
        end
        self:saveOpsToFile(
            string.format("placisz %s", self.data.lastPayoutClient),
            self.data.lastPayoutSimple)
        self.data.lastPayout = nil
        self.data.lastPayoutCmd = nil
    end
end


function scripts.ckn:cmdProwizja(arg)
    local s
    local val = 0
    local mults = {24000, 240, 12, 1}
    local i

    if arg == "pomoc" then
        self:msg("info", "#ffff00/knprowizja [mt] [zl] [sr] [md]#r oblicza rozne "
            .. "prowizje dla podanej kwoty.\n"
            .. "W przypadku podania mniejszej liczby argumentow, pomijane sa one od lewej.")
        return
    end

    arg = string.split(arg, " ")
    s = #arg

    while #mults > #arg do
        table.remove(mults, 1)
    end

    for i, coins in ipairs(arg) do
        val = val + coins * mults[i]
    end

    self:printMargins(val)
end


function scripts.ckn:cmdWloz(arg)
    local cont = arg:match('( do %a+)')
    local coins = {'mt', 'zl', 'sr', 'md'}
    
    if not cont and string.len(scripts.inv.dopelniacz_money_bag_1) == 0 then
        self:msg('err', '/knwloz [co] do [czego]?')
        return
    end

    if not cont then
        cont = ' do ' .. scripts.inv.dopelniacz_money_bag_1
    end

    arg = arg:gsub(cont, "")
    
    if arg:match("%d+ %d+ %d+ %d+") then
        arg = string.split(arg, ' ')
        for i, c in ipairs(arg) do
            send(string.format('wloz %s%s', self:coinToCase(tonumber(c), coins[i]), cont))
        end
    elseif arg:match("(%d+ %w+)") then
        local c, deno = arg:match("(%d+) (%w+)")        
        local item
        c = tonumber(c)
        if deno:find('mithryl') or deno == 'mt' or deno == 'mth' then
            item = 'mt'
        elseif deno:find('zlot') or deno == 'zl' then
            item = 'zl'
        elseif deno:find('srebr') or deno == 'sr' then
            item = 'sr'
        elseif deno:find('miedzi') or deno == 'md' then
            item = 'md'
        else
            self:msg('err', '/knwloz [ile] [mt/zl/sr/md] do [czego]?')
            return;            
        end
        send(string.format('wloz %s%s', self:coinToCase(c, item), cont))
    else
        self:msg('err', '/knwloz [co] do [czego]?')
        return
    end        
end


function scripts.ckn:printCmdHelp(cmd, desc)
    hecho(string.format("#ffff00/kn%s#r - %s\n", cmd, desc))
end


function scripts.ckn:cmdHelp()
    self:msg("info", "Pomoc do pluginu CKN:")
    self:printCmdHelp("pomoc", "ta pomoc")
    self:printCmdHelp("prowizja <mt> <zl> <sr> <md>", "oblicza prowizje dla podanej kwoty (min. 1 argument)")
    self:printCmdHelp("wycen", "wycenia przedmioty u Javiera i wylicza prowizje")
    self:printCmdHelp("sprzedaz start <operacja>", "rozpoczyna sprzedaz; jesli podana zostanie operacja, przy zapisie w logu zostanie ona onaczona")
    self:printCmdHelp("sprzedaz stop", "konczy sprzedaz i wyswietla zarobek")
    self:printCmdHelp("sprzedaz dodaj/+ [kwota]", "dodaje podana kwote w formacie [mt] [zl] [sr] [md] do sumy sprzedazy, np. /knsprzedaz + 1 2 0 0")
    self:printCmdHelp("sprzedaz", "wyswietla aktualna kwote sprzedazy")
    self:printCmdHelp("wyplac <komu> <mt> <zl> <sr> <md>", "wyplaca wskazanej osobie podana liczbe monet, np. /knwyplac ogrowi 1 20 5 0")
    self:printCmdHelp("w[loz] <mt> <zl> <sr> <md> [do czego]", "wklada podana liczbe monet do pojemnika")
    self:printCmdHelp("w[loz] <x mt/zl/sr/md> [do czego]", "wklada podana liczbe monet do pojemnika")
    self:printCmdHelp("w[loz] <x mithryli/zlota/srebra/miedzi> [do czego]", "wklada podana liczbe monet do pojemnika")
    hecho('Jesli parametr [do czego] zostanie pominiety, a w konfigu zdefiniowano #ffff00scripts.inv.dopelniacz_money_bag_1#r, zostanie uzyty ten pojemnik\n')
    hecho('Log sprzedazy trzymany jest w ' .. self:getLogPath() .. '\n')
end
