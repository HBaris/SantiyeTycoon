local cam = workspace.CurrentCamera
return string.format("Cam type: %s | CFrame: %s | Focus: %s", tostring(cam.CameraType), tostring(cam.CFrame), tostring(cam.Focus))
