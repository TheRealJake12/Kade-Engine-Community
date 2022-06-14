package shader;

import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import shader.FXAAShader;

class ShadersHandler
{
	public static var fxaa:ShaderFilter = new ShaderFilter(new FXAAShader());

	public static var time: Float = 0.0;
	
}
