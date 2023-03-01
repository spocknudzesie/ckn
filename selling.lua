function scripts.ckn:cmdWez(arg) 
    enableTrigger('ckn_bierzesz')
    send("wez " .. arg[2])
end


function scripts.ckn:setWares(arg)
    local items = string.lower(arg)
    local for_sale = {}
    items = items:gsub(" i ", ", ")
    items = string.split(items, ", ")

    -- print(dump_table(items))

    for i, item in ipairs(items) do
        -- print("ITEM = |"..item.."|")
        if not item:match('^wiele ') then
            -- print("Nie ma wiele")
            table.insert(self.data.tmp.tempWares, item)
        else
            -- print(item .. " to jest wiele")
            item = item:gsub('^wiele ', "50 ")
            -- print(item)

            table.insert(self.data.tmp.tempWares, item)
        end
    end

    print("")
    self:msg('ok', string.format("Na liscie do sprzedazy: [#ffff00%d#r] #ffff00%s#r",
        #self.data.tmp.tempWares, string.join(self.data.tmp.tempWares, ", ")))
    self:msg('ok', string.format("Uzyj komendy '#ffff00/knsp#r', aby sprzedac #ffff00%s#r",
        self.data.tmp.tempWares[#self.data.tmp.tempWares]))
end


function scripts.ckn:sellNextWare(arg)
    local item

    if self.data.tmp.lastSaleTime and (os.time(os.date("!*t")) - self.data.tmp.lastSaleTime) < 1 then
        self:msg('err', 'Odczekaj przed kolejna sprzedaza.')
        return
    end
    
    if #self.data.tmp.tempWares == 0 then
        self:msg('err', 'Obecna porcja sprzedana.')
        return
    end

    self.data.tmp.lastSaleTime = os.time(os.date("!*t"))

    item = table.remove(self.data.tmp.tempWares)

    send("sprzedaj " .. item)
    if arg:match('t$') then
        send("poloz monety")
    end


    if #self.data.tmp.tempWares == 0 then
        self:msg('ok', "Obecna porcja towaru sprzedana.")
    end
end
