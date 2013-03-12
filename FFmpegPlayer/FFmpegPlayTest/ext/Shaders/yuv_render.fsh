/*
 * anaglyph.fsh - Anaglyph (red/cyan) half-color stereoscopic filter. Get some red/cyan 3D glasses.
 * Using really naive scaling for the demo.
 * jamesghurley<at>gmail.com
 */
uniform sampler2D sampler0;
uniform sampler2D sampler1;
uniform sampler2D sampler2;
varying highp vec2 _texcoord;

void main()
{
    
    highp float y = texture2D(sampler0, _texcoord).r;
    highp float u = texture2D(sampler1, _texcoord).r - 0.5;
    highp float v = texture2D(sampler2, _texcoord).r - 0.5;
    
    highp float r = y +             1.402 * v;
    highp float g = y - 0.344 * u - 0.714 * v;
    highp float b = y + 1.772 * u;
    
    gl_FragColor = vec4(r, g, b, 1.0);
}