    btn.MouseButton1Click:Connect(function()
        if item.id == "fling_all" then
            btnText.Text = "✓"
            task.delay(0.75, function()
                if btnText and btnText.Parent then btnText.Text = t(item.btn) end
            end)
            flingAll()
            return
        end
        if item.id == "emote_zen" then
            task.spawn(playEmote, "Zen")
        elseif item.id == "emote_floss" then
            task.spawn(playEmote, "Floss")
        elseif item.id == "save_config" then
            saveConfig()
        elseif item.id == "shoot_now" then
            task.spawn(shootMurderer)
        end
        btnText.Text = "✓"
        setStatus(string.format("%s %s", t(item.label), UITEXT[currentLang].executed))
        task.delay(0.75, function()
            if btnText and btnText.Parent then btnText.Text = t(item.btn) end
        end)
    end)
