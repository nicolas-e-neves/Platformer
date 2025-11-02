return [[

extern float angle;
extern vec2 textureSize;
extern Image palette;


float lerp(float a, float b, float t) {
   return a + (b - a) * t;
}


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
   vec2 U = vec2(cos(-angle), -sin(-angle));
   vec2 V = vec2(sin(-angle), cos(-angle));
   vec2 unU = vec2(cos(angle), -sin(angle));
   vec2 unV = vec2(sin(angle), cos(angle));

   vec2 rotatedCoord = (texture_coords.x - 0.5) * U + (texture_coords.y - 0.5) * V;
   vec2 roundRotCoord = floor(rotatedCoord * textureSize * 2) / (textureSize * 2) + vec2(0.5, 0.5);

   vec2 space = 1 / (textureSize * 2);
   vec2 roundCoord = ((roundRotCoord.x - 0.5) * unU + (roundRotCoord.y - 0.5) * unV) * 2 + vec2(0.5, 0.5) + space;

   if (roundCoord.x < 0 || roundCoord.x >= 1 || roundCoord.y < 0 || roundCoord.y >= 1) {
      return vec4(0,0,0,0);
   }

   vec4 pixelUV = Texel(tex, roundCoord);
   vec4 pixel = Texel(palette, pixelUV.xy);
   vec4 finalColor = vec4(pixel.rgb * color.rgb, pixelUV.a * color.a);

   //return vec4(roundCoord, 0, 1);
   return finalColor;
}



]]