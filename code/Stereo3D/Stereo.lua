local Stereo = {}

---Initialize Stereo module with necessary parameters
---@param mode string 'stereo' or '3d', the first is Side By Side view, the second is Red-Cyan Dubois Anaglyph view. 
---@param fov number A value for the Y axis FOV of the view, 0.45 by default
---@param ipd number Interpupillary distance, 0.063m default 
---@param focus_distance number Focus distacne in meters, defaut 2.4m
function Stereo:init(mode, fov, ipd, focus_distance)
    -- Detect if running on Android system, if yes then no action is taken
    self.ANDROID = lovr.system.getOS() == 'Android'
    if self.ANDROID then return end
    -- Store parameters and pose information
    self.head = lovr.math.newMat4()
    self.mode = mode or "stereo"
    self.ipd = ipd or 0.063
    self.fovy = fov or 0.45
    self.focus_distance = focus_distance or 5
    -- Choose mode to run in
    if self.mode == "stereo" then
        self.width = lovr.system.getWindowWidth() *.5
        self.stereoShader = lovr.graphics.newShader('fill', "Stereo3D/Stereo.glsl")
    elseif self.mode == "3d" then        
        self.width = lovr.system.getWindowWidth()
        self.stereoShader = lovr.graphics.newShader('fill', "Stereo3D/Dubois.glsl")
    end
    self.views = 2
    self.height = lovr.system.getWindowHeight()
    -- Compute FOV on X axis
    self.fovx = self.fovy * (self.width / self.height)
    -- Texture on which the view is produced 
    self.canvas = lovr.graphics.newTexture(self.width, self.height, self.views, {
        type = 'array',
        usage = { 'render', 'sample' },
        mipmaps = false
    })
    self.focus_angle = math.pi/2 - math.atan( self.focus_distance / (self.ipd / 2)) 
end

---Update the headset pose to mantain a valid view
function Stereo:update()
    self.head:set(lovr.headset.getPose())
end

function Stereo:update_focus(distance)
    if type(distance) == "number" then
        if distance > 0 then 
            self.focus_distance = distance
            print("New Distance: "..distance)
            self.focus_angle = math.pi / 2 - math.atan(self.focus_distance / (self.ipd / 2))
        end
    end 
end

---Internal function to draw stereoscopic view of environment
---@param fn function pass the lovr.draw call with the pass to draw the view in stereoscopy
---@return lovr.Pass
function Stereo:render(fn)
    -- Pass on which the results are rendered
    local pass = lovr.graphics.getPass('render', self.canvas)
    
    -- Slightly rotate viewpoints to focus at a distance
    local rotation_l = quat(-self.focus_angle, 0, 1, 0)
    local rotation_r = quat(self.focus_angle, 0, 1, 0)

    -- Compute the pose of each eye
    local offset = vec3(self.ipd * .5, 0, 0)
    pass:setViewPose(1, mat4(self.head):translate(-offset):rotate(rotation_l))
    pass:setViewPose(2, mat4(self.head):translate(offset):rotate(rotation_r))

    --Produce the two views
    local projection = mat4():fov(self.fovx, self.fovx, self.fovy, self.fovy, .01)
    pass:setProjection(1, projection)
    pass:setProjection(2, projection)

    -- Draw all textures on the canvas to then display
    fn(pass)

    return pass
end

-- Invoked to produce the window view when a VR headset is connected
function Stereo:mirror(pass)
    pass:push('state')
    pass:setShader(self.stereoShader)
    pass:send('canvas', self.canvas)
    pass:fill()
    pass:pop('state')
end

-- Override LOVR functions such as update, mirror and draw to integrate the package as needed. To be called at the end of the script
function Stereo:integrate()
    local stub_fn = function() end
    local existing_cb = {
        draw = lovr.draw or stub_fn,
        update = lovr.update or stub_fn,
        mirror = lovr.mirror or stub_fn
    }

    lovr.update = function(dt)
        Stereo:update()
        existing_cb.update(dt)
    end

    lovr.draw = function(pass)        
        if self.ANDROID then
            return existing_cb.draw(pass)
        else
            return lovr.graphics.submit(Stereo:render(existing_cb.draw))
        end
    end

    lovr.mirror = function (pass)
        if self.ANDROID then
            return true
        else
            Stereo:mirror(pass)
        end
    end
end

return Stereo