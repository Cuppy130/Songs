#version 120

varying vec4 color;
varying vec2 imageCoord;
uniform vec2 imageSize;
uniform vec2 textureSize;
uniform float opacity;
uniform sampler2D sampler0;
uniform sampler2D sampler1;


vec2 img2tex( vec2 v ) { return v / textureSize * imageSize; }
void main()
{
    vec2 uv = imageCoord;

	vec3 col1 = texture2D( sampler0, img2tex(uv)).rgb;
	vec3 col2 = texture2D( sampler1,  vec2( uv.x, 1.0 - uv.y)).rgb;
	
	//Multiply
    //col1= col1*col2;
	
    //Exclusion
	//col1 = 0.5-2.0*(col1-0.5)*(col2-0.5);
	
	//Lighten
	//col1 = max(col1,col2);

    //Color Dodge
	//col1 = col1/(1.0-col2);

    //Color Burn
	//col1 = 1.0-(1.0-col1)/col2;
	
	//Difference
	//col1 = abs(col1-col2);
	//col1 = 1.0-col1;

	gl_FragColor = vec4( col1, opacity )*color;
}
