precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    // Add a funny effect
    color.b *= 0.7;
    color.g *= 0.9;
    gl_FragColor = color;
}