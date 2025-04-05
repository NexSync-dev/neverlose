local NotificationLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/NexSync-dev/neverlose/refs/heads/main/lib.lua"))()

-- Example Usage:
NotificationLib:Notify("welcome to NexSync hub", "info")(2)
task.wait(1)
NotificationLib:Notify("Loading GUI", "info")(3)
task.wait(1)
NotificationLib:Notify("This may not be as good as you expect", "warning")(4)
task.wait(1)
NotificationLib:Notify("If something doesnt work after dying,try disabling and re-enabling it or fully re-executing", "warning")(5)

loadstring(game:HttpGet("https://raw.githubusercontent.com/NexSync-dev/neverlose/refs/heads/main/test.lua"))()
