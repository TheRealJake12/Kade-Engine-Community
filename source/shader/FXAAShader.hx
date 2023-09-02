package shader;

import flixel.system.FlxAssets.FlxShader;

class FXAAShader extends FlxShader
{
	@:glFragmentSource('
        #pragma header

        precision mediump float;

        #define FXAA_SPAN_MAX 8.0
        #define FXAA_REDUCE_MUL   (1.0/FXAA_SPAN_MAX)
        #define FXAA_REDUCE_MIN   (1.0/128.0)
        #define FXAA_SUBPIX_SHIFT (1.0/4.0)
        
        uniform float iTime;
        uniform vec2 iResolution;
        uniform sampler2D iChannel1;
        uniform sampler2D iChannel2;

        vec3 FxaaPixelShader(vec4 uv, sampler2D tex, vec2 rcpFrame) 
        {
            
            vec3 rgbNW = flixel_texture2D(tex, uv.zw).xyz;
            vec3 rgbNE = flixel_texture2D(tex, uv.zw + vec2(1,0)*rcpFrame.xy).xyz;
            vec3 rgbSW = flixel_texture2D(tex, uv.zw + vec2(0,1)*rcpFrame.xy).xyz;
            vec3 rgbSE = flixel_texture2D(tex, uv.zw + vec2(1,1)*rcpFrame.xy).xyz;
            vec3 rgbM  = flixel_texture2D(tex, uv.xy).xyz;

            vec3 luma = vec3(0.299, 0.587, 0.114);
            float lumaNW = dot(rgbNW, luma);
            float lumaNE = dot(rgbNE, luma);
            float lumaSW = dot(rgbSW, luma);
            float lumaSE = dot(rgbSE, luma);
            float lumaM  = dot(rgbM,  luma);

            float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
            float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

            vec2 dir;
            dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
            dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

            float dirReduce = max(
                (lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
                FXAA_REDUCE_MIN);
            float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);
            
            dir = min(vec2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
                max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
                dir * rcpDirMin)) * rcpFrame.xy;

            vec3 rgbA = (1.0/2.0) * (
                flixel_texture2D(tex, uv.xy + dir * (1.0/3.0 - 0.5)).xyz +
                flixel_texture2D(tex, uv.xy + dir * (2.0/3.0 - 0.5)).xyz);
            vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
                flixel_texture2D(tex, uv.xy + dir * (0.0/3.0 - 0.5)).xyz +
                flixel_texture2D(tex, uv.xy + dir * (3.0/3.0 - 0.5)).xyz);
            
            float lumaB = dot(rgbB, luma);

            if((lumaB < lumaMin) || (lumaB > lumaMax)) return rgbA;
            
            return rgbB; 
        }


        void main(out vec4 fragColor, in vec2 openfl_TextureCoordv)
        {
            vec2 rcpFrame = 1./openfl_TextureCoordv;
            vec2 uv2 = openfl_TextureCoordv;
                
            float splitCoord = (iMouse.x == 0.0) ? openfl_TextureCoordv/2. + openfl_TextureCoordv*cos(iTime*.5) : iMouse.x;
            
            vec3 col;
            
            if( uv2.x < splitCoord/openfl_TextureCoordv ) {
                vec4 uv = vec4( uv2, uv2 - (rcpFrame * (0.5 + FXAA_SUBPIX_SHIFT)));
                col = FxaaPixelShader( uv, bitmap, 1./openfl_TextureCoordv );
            } else {
                col = flixel_texture2D( bitmap, uv2 ).xyz;
            }
            
            if (abs(fragCoord.x - splitCoord) < 1.0) {
                col.x = 1.0;
            }
            
            gl_FragColor = vec4( col, 1. ); 
        } ')
	public function new()
	{
		super();
	}
}
