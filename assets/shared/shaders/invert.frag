//SHADERTOY PORT FIX
#pragma header
vec2 uv = openfl_TextureCoordv.xy;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;

uniform float iStrength;
#define iChannel0 bitmap
#define texture flixel_texture2D
#define fragColor gl_FragColor
#define mainImage main
#define Strength iStrength

void mainImage()
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 color = texture(iChannel0, uv) ;


    float lightconfig = abs(Strength+1.0);
    if (lightconfig > 1.0)
        lightconfig = 1.0;
    
    color.xyz = vec3(lightconfig,lightconfig,lightconfig)+ (color.xyz*-Strength);

    fragColor = color;
}