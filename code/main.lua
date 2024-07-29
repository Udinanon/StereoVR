local Stereo = require("Stereo3D.Stereo")

function lovr.load()
  Stereo:init('3d')
  -- grid floor shader
  shader = lovr.graphics.newShader([[
        vec4 lovrmain() {
            return DefaultPosition;
        }
    ]], [[
        const float gridSize = 25.;
        const float cellSize = .5;

        vec4 lovrmain() {
            // Distance-based alpha (1. at the middle, 0. at edges)
            vec2 uv = UV;
            float alpha = 1. - smoothstep(.15, .50, distance(uv, vec2(.5)));
            // Grid coordinate
            uv *= gridSize;
            uv /= cellSize;
            vec2 c = abs(fract(uv - .5) - .5) / fwidth(uv);
            float line = clamp(1. - min(c.x, c.y), 0., 1.);
            vec3 value = mix(vec3(.01, .01, .011), (vec3(.04)), line);

            return vec4(vec3(value), alpha);
        }
    ]], { flags = { highp = true } })
    distance = 2.2
end

function lovr.keypressed(key, scancode, repeating)
  if key == "." then
    distance = distance +.3
    Stereo:update_focus(distance)
  elseif key == "," then
    distance = distance - .3
    Stereo:update_focus(distance)
  end
end

function lovr.draw(pass)
  pass:setWireframe(false)
  pass:monkey(0, 1.7, -2)


  local size = .4
  local start_point = vec3(0, 1, 0)
  pass:cube(start_point, size)
  for i = -1, 1, 2 do
    for j = -1, 1, 2 do
      for k = -1, 1, 2 do
        pass:sphere(start_point + ((size / 1.5) * vec3(i, j, k)), size / 6)
      end
    end
  end

  pass:setWireframe(false)
  pass:setShader(shader)
  pass:plane(0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0)
  pass:setShader()


end

Stereo:integrate()