return [[

extern Image palette;


float lerp(float a, float b, float t) {
   return a + (b - a) * t;
}


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
   vec4 pixelUV = Texel(tex, texture_coords);
   vec4 pixel = Texel(palette, pixelUV.xy);

   vec4 finalColor = vec4(pixelUV.rgb * color.rgb, pixelUV.a * color.a);
   if (pixelUV.b == 0) {
      finalColor = vec4(pixel.rgb * color.rgb, finalColor.a);
   }

   //return vec4(texture_coords, 0, 1);
   return finalColor;
}



]]