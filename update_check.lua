CKN.updateCheck = ckn.updateCheck or {
    file = ckn.dir .. "commits",
    url = "https://api.github.com/repos/spocknudzesie/ckn/commits",
    storeKey = "CKN"
}


function ckn.updateCheck:checkNewVersion()
    downloadFile(self.file, self.url)
    registerAnonymousEventHandler("sysDownloadDone", function(_, file)
        self:handle(file)
    end, true)
    coroutine.yield(self.coroutine)
end


function ckn.updateCheck:handle(fileName)
    if fileName ~= self.file then
        return
    end

    local cknState = scripts.state_store:get(self.storeKey) or {}

    local file, s, contents = io.open(self.file)
    if file then
        contents = yajl.to_value(file:read("*a"))
        io.close(file)
        os.remove(self.file)
        local sha = contents[1].sha
        if cknState.sha ~= nil and sha ~= cknState.sha then
            echo("\n")
            cecho("<CadetBlue>(skrypty)<tomato>: Plugin ckn ma  nowa aktualizacje. Kliknij ")
            cechoLink("<green>tutaj", [[ckn.updateCheck:update()]], "Aktualizuj", true)
            cecho(" <tomato>aby pobrac")
            echo("\n")
        end
        cknState.sha = sha
        scripts.state_store:set(self.storeKey, cknState)
    end
end

function ckn.updateCheck:update()
    scripts.plugins_installer:install_from_url("https://codeload.github.com/spocknudzesie/ckn/zip/master")
end

ckn.updateCheck.coroutine = coroutine.create(function()
    ckn.updateCheck:checkNewVersion()
end)
tempTimer(5, function() coroutine.resume(ckn.updateCheck.coroutine) end)


