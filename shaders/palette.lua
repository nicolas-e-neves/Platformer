return [[

extern vec2 screenSize;
float PI = 3.14159625;

vec4 effect(vec4 color, Image image, vec2 textureCoords, vec2 screenCoords) {
   vec2 screenUV = screenCoords / screenSize;

   //vec2 offset = vec2(sin(screenCoords.y / screenSize.y * PI * 8) * 0.5, sin(screenCoords.x / screenSize.x * PI * 8) * 0.5);
   //vec4 pixel = Texel(image, 2 * textureCoords - vec2(0.5, 0.5) + offset);

   //vec4 pixel = Texel(image, floor(textureCoords * 12) / 12);

   vec4 pixel = Texel(image, textureCoords);
   
   float brightness = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
   vec4 brightnessVector = vec4(brightness, brightness, brightness, pixel.a);

   vec4 finalColor = vec4(pixel.rgb * color.rgb, pixel.a * color.a);
   //vec4 finalColor = vec4()

   return finalColor;
}



]]