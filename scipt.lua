local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function clearVisuals(char)
    for _, inst in ipairs(char:GetChildren()) do
        if inst:IsA("Accessory") or inst:IsA("Hat") or inst:IsA("Shirt")
        or inst:IsA("Pants") or inst:IsA("ShirtGraphic") 
        -- НЕ УДАЛЯЕМ CharacterMesh! Пусть старые меши перезапишутся новыми
        then
            inst:Destroy()
        end
    end
    local head = char:FindFirstChild("Head")
    if head then
        for _, d in ipairs(head:GetChildren()) do
            if d:IsA("Decal") and d.Name:lower() == "face" then 
                d:Destroy() 
            end
        end
    end
    local bc = char:FindFirstChildOfClass("BodyColors")
    if bc then bc:Destroy() end
end

local function attachAccessory(char, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end
    
    local targetAttachment, accAttachment
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            for _, att in ipairs(part:GetChildren()) do
                if att:IsA("Attachment") then
                    local match = handle:FindFirstChild(att.Name)
                    if match and match:IsA("Attachment") then
                        targetAttachment = att
                        accAttachment = match
                        break
                    end
                end
            end
        end
        if targetAttachment then break end
    end
    
    if targetAttachment and accAttachment then
        handle.CFrame = targetAttachment.WorldCFrame * accAttachment.CFrame:Inverse()
    else
        -- Fallback для R6: цепляем к Head или Torso
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if root then
            handle.CFrame = root.CFrame
        end
    end
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = (targetAttachment and targetAttachment.Parent) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char:FindFirstChild("Torso")
    weld.Parent = handle
    accessory.Parent = char
end

local function applyAppearance(userId)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local ok, model = pcall(function()
        return Players:GetCharacterAppearanceAsync(userId)
    end)
    if not ok or not model then 
        return false 
    end

    clearVisuals(char)

    -- Копируем BodyColors
    local bc = model:FindFirstChildOfClass("BodyColors")
    if bc then bc:Clone().Parent = char end

    -- Копируем одежду
    for _, item in ipairs(model:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Clone().Parent = char
        end
    end

    -- КЛЮЧЕВОЕ: Копируем CharacterMesh (для уникальных меш рук/ног/торса в R6)
    for _, mesh in ipairs(model:GetChildren()) do
        if mesh:IsA("CharacterMesh") then
            local clonedMesh = mesh:Clone()
            clonedMesh.Parent = char
            -- Принудительно обновляем меш в части тела (для R6)
            local bodyPart = char:FindFirstChild(mesh.BodyPart)
            if bodyPart then
                bodyPart:FindFirstChildOfClass("SpecialMesh"):Destroy() -- Удаляем дефолтный меш
                local newMesh = Instance.new("SpecialMesh")
                newMesh.MeshId = mesh.MeshId
                newMesh.TextureId = mesh.TextureId
                newMesh.Scale = mesh.Scale or Vector3.new(1,1,1)
                newMesh.Parent = bodyPart
            end
        end
    end

    -- Копируем аксессуары
    for _, acc in ipairs(model:GetChildren()) do
        if acc:IsA("Accessory") or acc:IsA("Hat") then
            attachAccessory(char, acc:Clone())
        end
    end

    -- Лицо (правильно ищем в модели)
    local head = char:FindFirstChild("Head")
    if head then
        local face = model:FindFirstChild("face", true) -- recursive поиск
        if face and face:IsA("Decal") then
            face:Clone().Parent = head
        end
    end

    -- Финальный трюк для R6: Перезагружаем анимации/позу, чтоб меши "включились"
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = true
        task.wait(0.1)
        hum.PlatformStand = false
    end

    return true
end

local function resetCharacter()
    LocalPlayer:LoadCharacter()
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Solara Character Changer",
    LoadingTitle = "Avatar Copier",
    LoadingSubtitle = "UserId -> Character (R6 Fixed)",
    ConfigurationSaving = { Enabled = false }
})

local Tab = Window:CreateTab("Character")
local userIdInput = ""

Tab:CreateInput({
    Name = "Enter UserId",
    PlaceholderText = "Например: 1",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        userIdInput = text
    end
})

Tab:CreateButton({
    Name = "Применить скин",
    Callback = function()
        local uid = tonumber(userIdInput)
        if uid then
            local success = applyAppearance(uid)
            if success then
                Rayfield:Notify({
                    Title = "Успех",
                    Content = "Скин применён с UserId: " .. uid .. " (меши, аксессуары, всё для R6)",
                    Duration = 4
                })
            else
                Rayfield:Notify({
                    Title = "Ошибка",
                    Content = "Не удалось загрузить скин для UserId: " .. uid .. " (проверь приватность аккаунта)",
                    Duration = 4
                })
            end
        else
            Rayfield:Notify({
                Title = "Ошибка",
                Content = "Введи корректный UserId!",
                Duration = 3
            })
        end
    end
})

Tab:CreateButton({
    Name = "Сбросить персонажа",
    Callback = function()
        resetCharacter()
        Rayfield:Notify({
            Title = "Персонаж сброшен",
            Content = "Возвращён стандартный вид",
            Duration = 3
        })
    end
})
