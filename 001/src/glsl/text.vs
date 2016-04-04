precision highp float;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;
attribute vec3 position;
attribute vec3 normal;

void main() {
	vec3 pos = position;
	// pos+=position*normal*.3;
	gl_Position = projectionMatrix * modelViewMatrix * vec4( pos, 1.0 );
}
