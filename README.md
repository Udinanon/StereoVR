`# LOVR Stereo3D

An old idea of mine, now as an autonomous repo

Code to show the output of [LOVR](lovr.org) using both side-by-side video and with [red-cyan anaglyph](https://en.wikipedia.org/wiki/Anaglyph_3D).

Simply add the `Stereo3D` folder to your project, then add a few lines to your `main.lua`:
```lua
local Stereo = require("StereoVR.Stereo")

function lovr.load()
  Stereo:init('3d')
...
end

...
-- End of the code
Stereo:integrate()
```

The `:integrate()` overrides the draw, loads and overrides callbacks as needed.

`:init(mode, fov, ipd, focus_distance)` has three parameters:
- `mode`, a string, either `stereo` or `3d`, selecting if side-by-side or red-cyan, respectively
- `fov`, the FOV of the virtual cameras used
- `ipd` the simulated Interpupillary distance
- `focus_distance` the distance at which the virtual eyes focus, tune to regulate depth effect

If launched in an Android device its entirely skipped, while it should correctly modify only the `mirror` callback if using as PCVR.