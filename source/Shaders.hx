package;

import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;
import flixel.FlxG;

typedef ShaderEffect = {
  var shader:Dynamic;
}

class ChromaticAberrationEffect extends Effect
{
	public var shader:ChromaticAberrationShader;
	public function new(offset:Float = 0.00)
	{
		shader = new ChromaticAberrationShader();
		shader.rOffset.value = [offset];
		shader.gOffset.value = [0.0];
		shader.bOffset.value = [-offset];
	}

	public function setChrome(chromeOffset:Float):Void
	{
		shader.rOffset.value = [chromeOffset];
		shader.gOffset.value = [0.0];
		shader.bOffset.value = [chromeOffset * -1];
	}
}

class ChromaticAberrationShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header

	uniform float rOffset;
	uniform float gOffset;
	uniform float bOffset;

	void main()
	{
		vec4 col1 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(rOffset, 0.0));
		vec4 col2 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(gOffset, 0.0));
		vec4 col3 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(bOffset, 0.0));
		vec4 toUse = texture2D(bitmap, openfl_TextureCoordv);
		toUse.r = col1.r;
		toUse.g = col2.g;
		toUse.b = col3.b;

		gl_FragColor = toUse;
	}')
	public function new()
	{
		super();
	}
}

class VignetteEffect extends Effect
{
	public var shader:VignetteShader = new VignetteShader();

	public var radius(default, set):Float = 0.5;
	public var smoothness(default, set):Float = 0.5;

	public function new(radius:Float = 0.5, smoothness:Float = 0.5)
	{
		this.radius = radius;
		this.smoothness = smoothness;

		shader.uRadius.value = [0.5];
		shader.uSmoothness.value = [0.5];
	}

	function set_radius(value:Float):Float
	{
		shader.uRadius.value = [value];
		return value;
	}

	function set_smoothness(value:Float):Float
	{
		smoothness = value;
		shader.uSmoothness.value = [value];
		return value;
	}
}

class VignetteShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header

	uniform float uRadius;
	uniform float uSmoothness;

	float vignette(vec2 uv, float radius, float smoothness)
	{
		float diff = radius - distance(uv, vec2(0.5, 0.5));
		return smoothstep(-smoothness, smoothness, diff);
	}

	void main()
	{
		vec2 uv = openfl_TextureCoordv;

		float vignetteValue = vignette(uv, uRadius, uSmoothness);

		vec4 color = texture2D(bitmap, uv);
		color.rgb *= vignetteValue;
		gl_FragColor = color;
	}')
	public function new()
	{
		super();
	}
}

class GameboyEffect extends Effect
{
	public var brightness(default, set):Float = 1.0;
	public var shader:GameboyShader = new GameboyShader();

	public function new(brightness:Float = 1.0)
	{
		this.brightness = brightness;

		shader.brightness.value = [1.0];
	}

	function set_brightness(value:Float):Float
	{
		brightness = value;
		shader.brightness.value = [value];
		return value;
	}
}

class GameboyShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header
	uniform float brightness;

	vec3 iscloser (in vec3 color, in vec3 current, inout float dmin)
	{
		vec3 closest = current;
		float dcur = distance (color, current);
		if (dcur < dmin)
		{
			dmin = dcur;
			closest = color;
		}

		return closest;
	}

	vec3 find_closest (vec3 ref) {
		vec3 old = vec3 (100.0*255.0);
		#define TRY_COLOR(new) old = mix (new, old, step (length (old-ref), length (new-ref)));	

		TRY_COLOR (vec3 (156.0, 189.0, 15.0));
		TRY_COLOR (vec3 (140.0, 173.0, 15.0));
		TRY_COLOR (vec3 (48.0, 98.0, 48.0));
		TRY_COLOR (vec3 (15.0, 56.0, 15.0));

		return old;
	}

	float dither_matrix (float x, float y)
	{
		return mix(mix(mix(mix(mix(mix(0.0,32.0,step(1.0,y)),mix(8.0,40.0,step(3.0,y)),step(2.0,y)),mix(mix(2.0,34.0,step(5.0,y)),mix(10.0,42.0,step(7.0,y)),step(6.0,y)),step(4.0,y)),mix(mix(mix(48.0,16.0,step(1.0,y)),mix(56.0,24.0,step(3.0,y)),step(2.0,y)),mix(mix(50.0,18.0,step(5.0,y)),mix(58.0,26.0,step(7.0,y)),step(6.0,y)),step(4.0,y)),step(1.0,x)),mix(mix(mix(mix(12.0,44.0,step(1.0,y)),mix(4.0,36.0,step(3.0,y)),step(2.0,y)),mix(mix(14.0,46.0,step(5.0,y)),mix(6.0,38.0,step(7.0,y)),step(6.0,y)),step(4.0,y)),mix(mix(mix(60.0,28.0,step(1.0,y)),mix(52.0,20.0,step(3.0,y)),step(2.0,y)),mix(mix(62.0,30.0,step(5.0,y)),mix(54.0,22.0,step(7.0,y)),step(6.0,y)),step(4.0,y)),step(3.0,x)),step(2.0,x)),mix(mix(mix(mix(mix(3.0,35.0,step(1.0,y)),mix(11.0,43.0,step(3.0,y)),step(2.0,y)),mix(mix(1.0,33.0,step(5.0,y)),mix(9.0,41.0,step(7.0,y)),step(6.0,y)),step(4.0,y)),mix(mix(mix(51.0,19.0,step(1.0,y)),mix(59.0,27.0,step(3.0,y)),step(2.0,y)),mix(mix(49.0,17.0,step(5.0,y)),mix(57.0,25.0,step(7.0,y)),step(6.0,y)),step(4.0,y)),step(5.0,x)),mix(mix(mix(mix(15.0,47.0,step(1.0,y)),mix(7.0,39.0,step(3.0,y)),step(2.0,y)),mix(mix(13.0,45.0,step(5.0,y)),mix(5.0,37.0,step(7.0,y)),step(6.0,y)),step(4.0,y)),mix(mix(mix(63.0,31.0,step(1.0,y)),mix(55.0,23.0,step(3.0,y)),step(2.0,y)),mix(mix(61.0,29.0,step(5.0,y)),mix(53.0,21.0,step(7.0,y)),step(6.0,y)),step(4.0,y)),step(7.0,x)),step(6.0,x)),step(4.0,x));
	}

	vec3 dither (vec3 color, vec2 uv) {
		color *= 255.0 * brightness;
		color += dither_matrix (mod (uv.x, 8.0), mod (uv.y, 8.0));
		color = find_closest (clamp (color, 0.0, 255.0));
		return color / 255.0;
	}


	void main()
	{
		vec2 uv = openfl_TextureCoordv.xy;
		vec4 tc = flixel_texture2D(bitmap, uv);
		float daAlp = tc.a;
		gl_FragColor =  vec4 (dither (tc.xyz, uv),daAlp);
	}')
	public function new()
	{
		super();
	}
}

class CRTEffect extends Effect
{
	public var shader:CRTShader = new CRTShader();
	public var curved(default, set):Bool = true;

	public function new(curved:Bool = true)
	{
		this.curved = curved;

		shader.uTime.value = [0.0];
	}

	public function update(elapsed:Float)
	{
		shader.uTime.value[0] += elapsed;
	}

	public function getFilter():ShaderFilter
	{
		return new ShaderFilter(shader);
	}

	public function set_curved(value:Bool):Bool
	{
		curved = value;
		shader.curved.value = [value];
		return value;
	}
}

class CRTShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header

	uniform float uTime;
	uniform bool curved;

	vec2 curve(vec2 uv)
	{
		return uv;
	}

	void main()
	{
		vec2 uv = openfl_TextureCoordv.xy;

		if (curved)
		uv = curve( uv );

		float daAlp = flixel_texture2D(bitmap,uv).a;

		vec3 col;

		col.r = flixel_texture2D(bitmap,vec2(uv.x+0.003,uv.y)).x;
		col.g = flixel_texture2D(bitmap,vec2(uv.x+0.000,uv.y)).y;
		col.b = flixel_texture2D(bitmap,vec2(uv.x-0.003,uv.y)).z;

		col *= step(0.0, uv.x) * step(0.0, uv.y);
		col *= 1.0 - step(1.0, uv.x) * 1.0 - step(1.0, uv.y);

		col *= 0.5 + 0.5*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);
		col *= vec3(0.95,1.05,0.95);

		col *= 0.9+0.1*sin(10.0*uTime+uv.y*700.0);

		col *= 0.99+0.01*sin(110.0*uTime);

		gl_FragColor = vec4(col,daAlp);
	}')
	public function new()
	{
		super();
	}
}

//DNB Mod lol
class GlitchEffect extends Effect 
{
	public var shader:GlitchShader = new GlitchShader();

	public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	public function new(waveSpeed:Float = 0, waveFrequency:Float = 0, waveAmplitude:Float = 0):Void
	{
		this.waveSpeed = waveSpeed;
		this.waveFrequency = waveFrequency;
		this.waveAmplitude = waveAmplitude;

		shader.uTime.value = [0];

		PlayState.instance.shaderUpdates.push(update);
	}

	public function update(elapsed:Float):Void
	{
		shader.uTime.value[0] += elapsed;
	}

	function set_waveSpeed(v:Float):Float
	{
		waveSpeed = v;
		shader.uSpeed.value = [waveSpeed];
		return v;
	}

	function set_waveFrequency(v:Float):Float
	{
		waveFrequency = v;
		shader.uFrequency.value = [waveFrequency];
		return v;
	}

	function set_waveAmplitude(v:Float):Float
	{
		waveAmplitude = v;
		shader.uWaveAmplitude.value = [waveAmplitude];
		return v;
	}
}

class GlitchShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header 

	uniform float uTime;

	/**
	* How fast the waves move over time
	*/
	uniform float uSpeed;

	/**
	* Number of waves over time
	*/
	uniform float uFrequency;

	/**
	* How much the pixels are going to stretch over the waves
	*/
	uniform float uWaveAmplitude;

	vec2 sineWave(vec2 pt)
	{
		float x = 0.0;
		float y = 0.0;

		float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
		float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / pt.y * pt.x);
		pt.x += offsetX;
		pt.y += offsetY;

		return vec2(pt.x + x, pt.y + y);
	}

	void main()
	{
		vec2 uv = sineWave(openfl_TextureCoordv);
		gl_FragColor = texture2D(bitmap, uv);
	}')
	public function new()
	{
		super();
	}
}

//thx bbpanzu for this effect function
class Effect 
{
	public function setValue(shader:FlxShader, variable:String, value:Float)
	{
		Reflect.setProperty(Reflect.getProperty(shader, 'variable'), 'value', [value]);
	}
}
