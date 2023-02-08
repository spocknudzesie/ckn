scripts.ckn = scripts.ckn or {
    data = {
        selling = false,
        soldValue = 0,
        prowizje = {},    
        lastPayout = nil,
        lastPayoutCmd = nil,
        payoutVals = nil
    },
    pluginName = 'ckn',
    events = {},
    triggers = {},
    dir = getMudletHomeDir() .. "/plugins/ckn/"
}


function scripts.ckn:msg(t, msg)
    local col
    if t == "ok" then
        col = "#00ff00"
    elseif t == "info" then
        col = "#ffff00"
    elseif t == "err" then
        col = "#ff0000"
    end

    hecho(string.format("[%sCKN#r] %s\n", col, msg))
end


function scripts.ckn:init()
    hecho("[#00ff00CKN#r] Plugin zaladowany. Uzyj komendy #ffff00/knpomoc#r, aby przeczytac instrukcje.\n")
    scripts.plugins_update_check:github_check_version('ckn', 'spocknudzesie')
end


function scripts.ckn:getLogPath()
    return string.format("%s/ckn_ops.log", getMudletHomeDir())
end


function scripts.ckn:saveOpsToFile(ops, text)
    local f = io.open(self:getLogPath(), "a+")
    local timestamp = os.date("%Y-%m-%d %H:%M")
    if ops then
        f:write(string.format("%s [%s] | %s\n", timestamp, ops, text))
    else
        f:write(string.format("%s | %s\n", timestamp, text))
    end

    f:close()
end


function scripts.ckn:reload()
    local p = self.pluginName
    local selling = self.data.selling
    local total = self.data.soldValue
    local ops = self.data.currentOperation

    for name, num in ipairs(self.triggers) do
        killTrigger(num)
    end

    scripts[p] = nil
    load_plugin(p)

    self.data.selling = selling
    self.data.soldValue = total
    self.data.currentOperation = ops
end


tempTimer(0, function() scripts.charConfig:init() end)
